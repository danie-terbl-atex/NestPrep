import {
  Timestamp,
  type CollectionReference,
  type DocumentReference,
} from 'firebase-admin/firestore';
import { z } from 'zod';

import { storedEvent } from '../calendar_sync/feed_writer';
import { addDays, weekdayOf } from '../calendar_sync/zoned_time';
import { storedRoutine, storedTask, type StoredRoutine } from '../chore_points/point_documents';
import { weekKeyOf } from '../product_analytics/iso_week';
import {
  choresOn,
  eventsOn,
  type HouseholdEventRecord,
  type SyncedEventRecord,
  type TaskRecord,
} from './day_occurrences';
import type {
  ChoreToday,
  DayEvent,
  ExpiringDocument,
  LunchBoxToday,
  OpenShift,
  RecentHandover,
} from './digest_facts';

/**
 * The bounded reads a morning digest is made from (notifications ADR-0002,
 * BE-08): one area each, every one capped, every stored document parsed and
 * never cast — one that does not parse is left out, not trusted (ENG-09).
 * `digest_loader.ts` asks only for the areas somebody due this morning may see.
 */

export const EVENT_LIMIT = 500;
export const TASK_LIMIT = 500;
export const ROUTINE_LIMIT = 100;
export const LIST_LIMIT = 50;
export const EXPIRY_LIMIT = 20;
/** How far ahead an expiry is worth a line in the digest; the reminders cover the rest. */
export const EXPIRY_AHEAD_DAYS = 30;
export const EXPIRY_BEHIND_DAYS = 7;
/** A multi-day import is found by its first day; none runs longer than this. */
const SYNCED_SPAN_DAYS = 14;

function parsed<T extends z.ZodType>(schema: T, data: unknown): z.infer<T> | undefined {
  const result = schema.safeParse(data);
  return result.success ? result.data : undefined;
}

const eventWithPeople = storedEvent.extend({
  memberIds: z.array(z.string()).default([]),
  note: z.string().nullable().default(null).catch(null),
});
const exceptionShape = z.object({ eventId: z.string(), occurrenceDate: z.string() });
const syncedShape = z.object({
  title: z.string(),
  date: z.string(),
  endDate: z.string(),
  startMinute: z.number().int().nullable().default(null),
  endMinute: z.number().int().nullable().default(null),
  memberId: z.string(),
});

/** Everything stored that can put an event on a day from [from] to [to], inclusive. */
export interface EventWindow {
  readonly own: readonly HouseholdEventRecord[];
  readonly skips: readonly { readonly eventId: string; readonly occurrenceDate: string }[];
  readonly synced: readonly SyncedEventRecord[];
}

export async function readEventWindow(
  home: DocumentReference,
  from: string,
  to: string,
): Promise<EventWindow> {
  const [events, skips, synced] = await Promise.all([
    home.collection('events').limit(EVENT_LIMIT).get(),
    home
      .collection('eventExceptions')
      .where('occurrenceDate', '>=', from)
      .where('occurrenceDate', '<=', to)
      .limit(LIST_LIMIT)
      .get(),
    home
      .collection('syncedEvents')
      .where('date', '>=', addDays(from, -SYNCED_SPAN_DAYS))
      .where('date', '<=', to)
      .limit(EVENT_LIMIT)
      .get(),
  ]);
  return {
    own: events.docs.flatMap((doc) => {
      const event = parsed(eventWithPeople, doc.data());
      return event === undefined
        ? []
        : [{ id: doc.id, event, memberIds: event.memberIds, note: event.note }];
    }),
    skips: skips.docs.flatMap((doc) => parsed(exceptionShape, doc.data()) ?? []),
    synced: synced.docs.flatMap((doc) => parsed(syncedShape, doc.data()) ?? []),
  };
}

/** The household's own events skipped on [day]. */
export function skippedOn(window: EventWindow, day: string): Set<string> {
  return new Set(
    window.skips.filter((skip) => skip.occurrenceDate === day).map((skip) => skip.eventId),
  );
}

export async function readEvents(home: DocumentReference, today: string): Promise<DayEvent[]> {
  const window = await readEventWindow(home, today, today);
  return eventsOn(today, window.own, skippedOn(window, today), window.synced);
}

export const LUNCH_SLOTS = ['main', 'fruit', 'veg', 'snack', 'treat'] as const;
export type LunchSlot = (typeof LUNCH_SLOTS)[number];
const lunchPlanShape = z.object({
  childId: z.string(),
  slots: z.record(z.string(), z.object({ name: z.string() }).loose()).default({}),
});

/** One child's box today, slot by slot, in [LUNCH_SLOTS] order. */
export interface LunchPicksToday {
  readonly childId: string;
  readonly picks: readonly { readonly slot: LunchSlot; readonly name: string }[];
}

/** Today's box per child, Monday to Friday — a weekend has no school lunch. */
export async function readLunchPicks(
  home: DocumentReference,
  today: string,
): Promise<LunchPicksToday[]> {
  const weekday = weekdayOf(today);
  if (weekday > 5) return [];
  const week = weekKeyOf(new Date(`${today}T12:00:00Z`), 'UTC');
  const plans = await home
    .collection('lunchPlans')
    .where('week', '==', week)
    .limit(LIST_LIMIT)
    .get();
  return plans.docs.flatMap((doc) => {
    const plan = parsed(lunchPlanShape, doc.data());
    if (plan === undefined) return [];
    const picks = LUNCH_SLOTS.flatMap((slot) => {
      const name = plan.slots[`${String(weekday)}_${slot}`]?.name;
      return name === undefined ? [] : [{ slot, name }];
    });
    return picks.length === 0 ? [] : [{ childId: plan.childId, picks }];
  });
}

export async function readLunchBoxes(
  home: DocumentReference,
  today: string,
): Promise<LunchBoxToday[]> {
  const boxes = await readLunchPicks(home, today);
  return boxes.map(({ childId, picks }) => ({ childId, items: picks.map((pick) => pick.name) }));
}

const completionShape = z.object({ taskId: z.string(), occurrenceDate: z.string() });
const taskWithNote = storedTask.extend({ note: z.string().nullable().default(null).catch(null) });

/** The tasks and routines a day's chores come from, and what was ticked. */
export interface ChoreRecords {
  readonly tasks: readonly TaskRecord[];
  readonly routines: Readonly<Record<string, StoredRoutine | undefined>>;
  /** The tasks ticked on [today]. */
  readonly doneTaskIds: ReadonlySet<string>;
  /** Every occurrence ticked from [from] to [today], as `{taskId}_{date}` (todos ADR-0002). */
  readonly completed: ReadonlySet<string>;
}

export function completionKey(taskId: string, date: string): string {
  return `${taskId}_${date}`;
}

export async function readChoreRecords(
  home: DocumentReference,
  today: string,
  from: string = today,
): Promise<ChoreRecords> {
  const [tasks, routines, done] = await Promise.all([
    home.collection('tasks').limit(TASK_LIMIT).get(),
    home.collection('routines').limit(ROUTINE_LIMIT).get(),
    home
      .collection('taskCompletions')
      .where('occurrenceDate', '>=', from)
      .where('occurrenceDate', '<=', today)
      .limit(TASK_LIMIT)
      .get(),
  ]);
  const completions = done.docs.flatMap((doc) => parsed(completionShape, doc.data()) ?? []);
  return {
    tasks: tasks.docs.flatMap((doc) => {
      const task = parsed(taskWithNote, doc.data());
      return task === undefined ? [] : [{ id: doc.id, task, note: task.note }];
    }),
    routines: Object.fromEntries(
      routines.docs.flatMap((doc) => {
        const routine = parsed(storedRoutine, doc.data());
        return routine === undefined ? [] : [[doc.id, routine] as const];
      }),
    ),
    doneTaskIds: new Set(
      completions.flatMap((completion) =>
        completion.occurrenceDate === today ? [completion.taskId] : [],
      ),
    ),
    completed: new Set(
      completions.map((completion) => completionKey(completion.taskId, completion.occurrenceDate)),
    ),
  };
}

export async function readChores(home: DocumentReference, today: string): Promise<ChoreToday[]> {
  const records = await readChoreRecords(home, today);
  return choresOn(today, records.tasks, records.routines, records.doneTaskIds);
}

const expiringShape = z.object({ name: z.string(), expiresOn: z.string() });

/** Documents in [collection] expiring within the month, or expired this week. */
export async function readExpiring(
  collection: CollectionReference,
  today: string,
): Promise<ExpiringDocument[]> {
  const snapshot = await collection
    .where('expiresOn', '>=', addDays(today, -EXPIRY_BEHIND_DAYS))
    .where('expiresOn', '<=', addDays(today, EXPIRY_AHEAD_DAYS))
    .orderBy('expiresOn')
    .limit(EXPIRY_LIMIT)
    .get();
  return snapshot.docs.flatMap((doc) => parsed(expiringShape, doc.data()) ?? []);
}

const openShiftShape = z.object({ carerMemberId: z.string(), startedAt: z.instanceof(Timestamp) });
const handoverShape = z.object({ carerMemberId: z.string(), entryCount: z.number().int().min(0) });

/** Shifts still open, and the handovers written in the last day. */
export async function readShifts(
  home: DocumentReference,
  now: Date,
): Promise<{ openShifts: OpenShift[]; handovers: RecentHandover[] }> {
  const since = Timestamp.fromMillis(now.getTime() - 24 * 60 * 60 * 1000);
  const [open, ended] = await Promise.all([
    home.collection('nannyShifts').where('status', '==', 'open').limit(10).get(),
    home.collection('nannyShiftSummaries').where('endedAt', '>=', since).limit(10).get(),
  ]);
  return {
    openShifts: open.docs.flatMap((doc) => {
      const shift = parsed(openShiftShape, doc.data());
      return shift === undefined
        ? []
        : [{ carerMemberId: shift.carerMemberId, startedAt: shift.startedAt.toDate() }];
    }),
    handovers: ended.docs.flatMap((doc) => parsed(handoverShape, doc.data()) ?? []),
  };
}

/** How many chores wait for a parent's check, and rewards for handing over. */
export async function readApprovals(
  home: DocumentReference,
): Promise<{ choresToCheck: number; rewardsAskedFor: number }> {
  const [claims, requests] = await Promise.all([
    home.collection('pointClaims').where('status', '==', 'pending').count().get(),
    home.collection('rewardRequests').where('status', '==', 'waiting').count().get(),
  ]);
  return { choresToCheck: claims.data().count, rewardsAskedFor: requests.data().count };
}
