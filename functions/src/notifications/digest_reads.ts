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

const eventWithPeople = storedEvent.extend({ memberIds: z.array(z.string()).default([]) });
const exceptionShape = z.object({ eventId: z.string() });
const syncedShape = z.object({
  title: z.string(),
  date: z.string(),
  endDate: z.string(),
  startMinute: z.number().int().nullable().default(null),
  memberId: z.string(),
});

export async function readEvents(home: DocumentReference, today: string): Promise<DayEvent[]> {
  const [events, skips, synced] = await Promise.all([
    home.collection('events').limit(EVENT_LIMIT).get(),
    home.collection('eventExceptions').where('occurrenceDate', '==', today).limit(LIST_LIMIT).get(),
    home
      .collection('syncedEvents')
      .where('date', '>=', addDays(today, -SYNCED_SPAN_DAYS))
      .where('date', '<=', today)
      .limit(EVENT_LIMIT)
      .get(),
  ]);
  const own: HouseholdEventRecord[] = events.docs.flatMap((doc) => {
    const event = parsed(eventWithPeople, doc.data());
    return event === undefined ? [] : [{ id: doc.id, event, memberIds: event.memberIds }];
  });
  const skipped = new Set(
    skips.docs.flatMap((doc) => parsed(exceptionShape, doc.data())?.eventId ?? []),
  );
  const imported: SyncedEventRecord[] = synced.docs.flatMap(
    (doc) => parsed(syncedShape, doc.data()) ?? [],
  );
  return eventsOn(today, own, skipped, imported);
}

const LUNCH_SLOTS = ['main', 'fruit', 'veg', 'snack', 'treat'] as const;
const lunchPlanShape = z.object({
  childId: z.string(),
  slots: z.record(z.string(), z.object({ name: z.string() }).loose()).default({}),
});

/** Today's box per child, Monday to Friday — a weekend has no school lunch. */
export async function readLunchBoxes(
  home: DocumentReference,
  today: string,
): Promise<LunchBoxToday[]> {
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
    const items = LUNCH_SLOTS.flatMap(
      (slot) => plan.slots[`${String(weekday)}_${slot}`]?.name ?? [],
    );
    return items.length === 0 ? [] : [{ childId: plan.childId, items }];
  });
}

const completionShape = z.object({ taskId: z.string() });

export async function readChores(home: DocumentReference, today: string): Promise<ChoreToday[]> {
  const [tasks, routines, done] = await Promise.all([
    home.collection('tasks').limit(TASK_LIMIT).get(),
    home.collection('routines').limit(ROUTINE_LIMIT).get(),
    home.collection('taskCompletions').where('occurrenceDate', '==', today).limit(TASK_LIMIT).get(),
  ]);
  const routineById: Record<string, StoredRoutine | undefined> = Object.fromEntries(
    routines.docs.flatMap((doc) => {
      const routine = parsed(storedRoutine, doc.data());
      return routine === undefined ? [] : [[doc.id, routine] as const];
    }),
  );
  const records = tasks.docs.flatMap((doc) => {
    const task = parsed(storedTask, doc.data());
    return task === undefined ? [] : [{ id: doc.id, task }];
  });
  const doneIds = new Set(
    done.docs.flatMap((doc) => parsed(completionShape, doc.data())?.taskId ?? []),
  );
  return choresOn(today, records, routineById, doneIds);
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
