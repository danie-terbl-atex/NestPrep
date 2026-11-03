import { isOccurrence, type StoredRecurrence } from '../chore_points/occurrence_check';
import { addDays, weekdayOf } from '../calendar_sync/zoned_time';
import { choreOccurrencesOn, eventOccurrencesOn } from '../notifications/day_occurrences';
import {
  type ChoreRecords,
  completionKey,
  type EventWindow,
  LUNCH_SLOTS,
  type LunchPicksToday,
  type LunchSlot,
  skippedOn,
} from '../notifications/digest_reads';
import type { ChoreOccurrence } from '../notifications/day_occurrences';
import type { FrameScreensaver } from './frame_documents';
import {
  type FrameGroceriesDay,
  type FrameGroceriesSources,
  groceriesPanel,
} from './frame_groceries';
import {
  FRAME_DAY_AHEAD,
  FRAME_OVERDUE_DAYS,
  addsEvents,
  refreshAfterSeconds,
} from './frame_policy';
import { memberColorHex } from './member_colors';
import type { FramePanels } from './frame_schemas';

/**
 * One frame's day, assembled from what is stored (photo-frames ADR-0001).
 * Pure, so what a wall shows is tested without a database. Events and
 * chores land on a day by the digest's own expansion (notifications
 * ADR-0002), so the frame, the digest and the week view agree.
 *
 * What leaves here is what the wall shows and nothing more: titles, times,
 * first names, member colours and an event's own note (ADR-0003), the opaque
 * task, job or routine id a tick names (ADR-0007), and a premium box's picture
 * id, a hash of its foods (ADR-0009). No member id, uid, allergy, school rule
 * or anything medical.
 */

export const NOTE_MAX = 500;

export const MEAL_SLOTS = ['breakfast', 'lunch', 'dinner'] as const;
export type MealSlot = (typeof MEAL_SLOTS)[number];

const DONE_JOB_STATUSES: readonly string[] = ['submitted', 'approved'];

export interface HomeCareStep {
  readonly id: string;
  readonly text: string;
}

export interface HomeCareJobRecord {
  readonly id: string;
  readonly title: string;
  readonly roomId: string;
  readonly status: string;
  readonly dueDate: string;
  readonly note: string | null;
  readonly steps: readonly HomeCareStep[];
  readonly doneStepIds: readonly string[];
}

export interface HomeCareRoutineRecord {
  readonly id: string;
  readonly name: string;
  readonly roomId: string;
  readonly firstDate: string;
  readonly recurrence: StoredRecurrence | null;
  readonly items: readonly HomeCareStep[];
}

export interface HomeCareDay {
  /** The frame's helper's jobs due from [FRAME_OVERDUE_DAYS] ago to today. */
  readonly jobs: readonly HomeCareJobRecord[];
  /** Every routine of the frame's helper; only today's are shown. */
  readonly routines: readonly HomeCareRoutineRecord[];
  /** routineId → the items ticked today. */
  readonly ticks: Readonly<Record<string, readonly string[]>>;
  /** roomId → its name. */
  readonly rooms: Readonly<Record<string, string>>;
}

export interface MealDay {
  /** This week's plan, `{isoWeekday}_{slot}` → mealId. */
  readonly slots: Readonly<Record<string, string>>;
  /** mealId → its name. */
  readonly mealNames: Readonly<Record<string, string>>;
}

export interface FrameDaySources {
  readonly householdName: string;
  readonly frameName: string;
  readonly panels: FramePanels;
  readonly screensaver: FrameScreensaver | null;
  readonly today: string;
  /** Minutes after local midnight, now. */
  readonly localMinute: number;
  /** memberId → the name the household gave them. */
  readonly names: Readonly<Record<string, string>>;
  /** memberId → their palette colour's name. */
  readonly colors: Readonly<Record<string, string>>;
  /** The members whose role is `kid`: their chores get the Chores screen (rev 10). */
  readonly kids?: readonly string[];
  /** The members who may add an event from the frame, read only while it may (ADR-0008). */
  readonly adders?: readonly string[];
  readonly events?: EventWindow;
  readonly chores?: ChoreRecords;
  readonly meals?: MealDay;
  readonly homeCare?: HomeCareDay;
  readonly lunch?: readonly LunchPicksToday[];
  /** childId → the ready picture of that child's box, premium only (ADR-0009). */
  readonly lunchPhotos?: Readonly<Record<string, { readonly id: string }>>;
  /** The list and who may add to it, read only while the frame adds groceries (ADR-0012). */
  readonly groceries?: FrameGroceriesSources;
}

export interface FrameEvent {
  readonly title: string;
  readonly allDay: boolean;
  readonly start: string | null;
  readonly end: string | null;
  readonly who: string[];
  readonly note: string | null;
  readonly repeats: boolean;
}

export interface FrameCalendarDay {
  readonly date: string;
  readonly events: FrameEvent[];
}

export interface FrameMember {
  readonly name: string;
  /** `#RRGGBB`; null when the stored colour is not in the palette. */
  readonly color: string | null;
  readonly kid?: true;
}

export interface FrameLunchBox {
  readonly name: string;
  readonly items: { readonly slot: LunchSlot; readonly title: string }[];
  readonly photo?: string;
}

export const FRAME_ITEM_KINDS = ['task', 'job', 'routine'] as const;
export type FrameItemKind = (typeof FRAME_ITEM_KINDS)[number];

export interface FrameStep {
  readonly id: string;
  readonly text: string;
  readonly done: boolean;
}

/**
 * One row of the Tasks screen (ADR-0007): `kind`, `id` and `date` are what a
 * tick sends back; a `date` before `today` is overdue.
 */
export interface FrameItem {
  readonly title: string;
  readonly done: boolean;
  readonly kind: FrameItemKind;
  readonly id: string;
  readonly date: string;
  readonly note?: string;
  readonly stars?: number;
  readonly needsCheck?: true;
  readonly steps?: FrameStep[];
}

export interface FrameDay {
  readonly status: 'linked';
  readonly household: { readonly name: string; readonly members: FrameMember[] };
  readonly frame: { readonly name: string };
  readonly today: string;
  readonly refreshAfterSeconds: number;
  readonly screensaver?: FrameScreensaver;
  readonly calendar?: { readonly days: FrameCalendarDay[] };
  /** Who the frame may say is adding an event, by first name (ADR-0008). */
  readonly addEvents?: { readonly by: string[] };
  readonly todos?: { readonly items: (FrameItem & { readonly who: string[] })[] };
  readonly helper?: {
    readonly name: string;
    readonly items: (FrameItem & { readonly detail?: string })[];
  };
  readonly meals?: { readonly slots: { readonly slot: MealSlot; readonly title: string }[] };
  readonly lunch?: { readonly boxes: FrameLunchBox[] };
  readonly sharing?: true;
  /** The frame's shop, who may say they are adding, and what is still to buy (ADR-0012). */
  readonly groceries?: FrameGroceriesDay;
}

export function assembleFrameDay(sources: FrameDaySources): FrameDay {
  const { panels } = sources;
  const helperId = panels.helperMemberId;
  const helperName = helperId === null ? undefined : sources.names[helperId];
  return {
    status: 'linked',
    household: { name: sources.householdName, members: membersOf(sources) },
    frame: { name: sources.frameName },
    today: sources.today,
    refreshAfterSeconds: refreshAfterSeconds(sources.localMinute),
    ...(sources.screensaver === null ? {} : { screensaver: sources.screensaver }),
    ...(panels.calendar ? { calendar: calendarPanel(sources) } : {}),
    ...(addsEvents(panels) ? { addEvents: { by: addersOf(sources) } } : {}),
    ...(panels.todos ? { todos: todosPanel(sources) } : {}),
    ...(helperId !== null && helperName !== undefined
      ? { helper: { name: firstName(helperName), items: helperItems(sources, helperId) } }
      : {}),
    ...(panels.meals ? { meals: mealsPanel(sources) } : {}),
    ...(panels.lunch ? { lunch: lunchPanel(sources) } : {}),
    ...(panels.share ? { sharing: true as const } : {}),
    ...(sources.groceries === undefined
      ? {}
      : { groceries: groceriesPanel(sources.groceries, sources.names) }),
  };
}

export function firstName(displayName: string): string {
  return displayName.trim().split(/\s+/)[0] ?? '';
}

export function clockTime(minute: number | null): string | null {
  if (minute === null) return null;
  const hours = Math.floor(minute / 60);
  return `${String(hours).padStart(2, '0')}:${String(minute % 60).padStart(2, '0')}`;
}

/** Trimmed, at most [NOTE_MAX] characters, and null when nothing is left. */
export function frameNote(note: string | null): string | null {
  const trimmed = Array.from(note?.trim() ?? '')
    .slice(0, NOTE_MAX)
    .join('')
    .trimEnd();
  return trimmed === '' ? null : trimmed;
}

function byName<T extends { readonly name: string }>(a: T, b: T): number {
  return a.name.localeCompare(b.name);
}

function membersOf(sources: FrameDaySources): FrameMember[] {
  const kids = new Set(sources.kids);
  return Object.entries(sources.names)
    .flatMap(([id, displayName]) => {
      const name = firstName(displayName);
      if (name === '') return [];
      const color = memberColorHex(sources.colors[id]);
      return [kids.has(id) ? { name, color, kid: true as const } : { name, color }];
    })
    .sort(byName);
}

function addersOf(sources: FrameDaySources): string[] {
  return (sources.adders ?? [])
    .flatMap((id) => {
      const name = firstName(sources.names[id] ?? '');
      return name === '' ? [] : [{ name }];
    })
    .sort(byName)
    .map(({ name }) => name);
}

function firstNamesOf(memberIds: readonly string[], names: FrameDaySources['names']): string[] {
  return memberIds.flatMap((id) => {
    const name = names[id];
    return name === undefined || firstName(name) === '' ? [] : [firstName(name)];
  });
}

function calendarPanel(sources: FrameDaySources): NonNullable<FrameDay['calendar']> {
  const window = sources.events ?? { own: [], skips: [], synced: [] };
  const days = Array.from({ length: FRAME_DAY_AHEAD + 1 }, (_, offset) =>
    frameCalendarDay(addDays(sources.today, offset), window, sources.names),
  );
  return { days };
}

/** One day of a frame's calendar, by the digest's own expansion. */
export function frameCalendarDay(
  date: string,
  window: EventWindow,
  names: FrameDaySources['names'],
): FrameCalendarDay {
  const events = eventOccurrencesOn(date, window.own, skippedOn(window, date), window.synced).map(
    (event) => ({
      title: event.title,
      allDay: event.startMinute === null,
      start: clockTime(event.startMinute),
      end: clockTime(event.endMinute),
      who: firstNamesOf(event.memberIds, names),
      note: frameNote(event.note),
      repeats: event.repeats,
    }),
  );
  return { date, events };
}

/** Overdue oldest first, then today's still to do, then what is done, each in the order given. */
function inWallOrder<T extends FrameItem>(items: T[], today: string): T[] {
  const rank = (item: FrameItem): number => (item.done ? 2 : item.date < today ? 0 : 1);
  return items
    .map((item, index) => ({ item, index }))
    .sort(
      (a, b) =>
        rank(a.item) - rank(b.item) || a.item.date.localeCompare(b.item.date) || a.index - b.index,
    )
    .map(({ item }) => item);
}

interface ChoreRow {
  readonly chore: ChoreOccurrence;
  readonly date: string;
  readonly done: boolean;
}

/**
 * Today's chores, ticked or not, and the last [FRAME_OVERDUE_DAYS] days'
 * still undone: the app's overdue window (todos ADR-0001).
 */
function choresInReach(sources: FrameDaySources): ChoreRow[] {
  const records = sources.chores;
  if (records === undefined) return [];
  return Array.from({ length: FRAME_OVERDUE_DAYS + 1 }, (_, back) =>
    addDays(sources.today, back - FRAME_OVERDUE_DAYS),
  ).flatMap((date) =>
    choreOccurrencesOn(date, records.tasks, records.routines)
      .map((chore) => ({
        chore,
        date,
        done: records.completed.has(completionKey(chore.taskId, date)),
      }))
      .filter((row) => date === sources.today || !row.done)
      .sort((a, b) => a.chore.title.localeCompare(b.chore.title)),
  );
}

function choreItem({ chore, date, done }: ChoreRow): FrameItem {
  const note = frameNote(chore.note);
  const stars = chore.points > 0;
  return {
    title: chore.title,
    done,
    kind: 'task',
    id: chore.taskId,
    date,
    ...(note === null ? {} : { note }),
    ...(stars ? { stars: chore.points } : {}),
    ...(stars && chore.needsApproval ? { needsCheck: true as const } : {}),
  };
}

function todosPanel(sources: FrameDaySources): NonNullable<FrameDay['todos']> {
  return {
    items: inWallOrder(
      choresInReach(sources).map((row) => ({
        ...choreItem(row),
        who: firstNamesOf(row.chore.assigneeIds, sources.names),
      })),
      sources.today,
    ),
  };
}

/** The helper's routines that fall on [today]. */
export function routinesDueOn(
  today: string,
  routines: readonly HomeCareRoutineRecord[],
): HomeCareRoutineRecord[] {
  return routines.filter((routine) => isOccurrence(routine.firstDate, routine.recurrence, today));
}

type HelperItem = FrameItem & { readonly detail?: string };

function withRoom(item: FrameItem, roomId: string, rooms: HomeCareDay['rooms']): HelperItem {
  const room = rooms[roomId];
  return room === undefined ? item : { ...item, detail: room };
}

function stepsOf(steps: readonly HomeCareStep[], done: readonly string[]): FrameStep[] {
  return steps.map((step) => ({ id: step.id, text: step.text, done: done.includes(step.id) }));
}

function jobItem(job: HomeCareJobRecord, rooms: HomeCareDay['rooms']): HelperItem {
  const note = frameNote(job.note);
  return withRoom(
    {
      title: job.title,
      done: DONE_JOB_STATUSES.includes(job.status),
      kind: 'job',
      id: job.id,
      date: job.dueDate,
      ...(note === null ? {} : { note }),
      steps: stepsOf(job.steps, job.doneStepIds),
    },
    job.roomId,
    rooms,
  );
}

function helperItems(sources: FrameDaySources, helperId: string): HelperItem[] {
  const chores: HelperItem[] = choresInReach(sources)
    .filter((row) => row.chore.assigneeIds.includes(helperId))
    .map(choreItem);
  const care = sources.homeCare;
  if (care === undefined) return inWallOrder(chores, sources.today);
  const jobs = care.jobs
    .map((job) => jobItem(job, care.rooms))
    .filter((job) => job.date === sources.today || (job.date < sources.today && !job.done));
  const routines = routinesDueOn(sources.today, care.routines).map((routine) => {
    const ticked = care.ticks[routine.id] ?? [];
    const steps = stepsOf(routine.items, ticked);
    return withRoom(
      {
        title: routine.name,
        done: steps.length > 0 && steps.every((step) => step.done),
        kind: 'routine',
        id: routine.id,
        date: sources.today,
        steps,
      },
      routine.roomId,
      care.rooms,
    );
  });
  return inWallOrder([...chores, ...jobs, ...routines], sources.today);
}

/** Monday of [today]'s ISO week, which names the week's meal plan. */
export function mondayOf(today: string): string {
  return addDays(today, 1 - weekdayOf(today));
}

function mealsPanel(sources: FrameDaySources): NonNullable<FrameDay['meals']> {
  const plan = sources.meals;
  if (plan === undefined) return { slots: [] };
  const weekday = weekdayOf(sources.today);
  return {
    slots: MEAL_SLOTS.flatMap((slot) => {
      const mealId = plan.slots[`${String(weekday)}_${slot}`];
      const title = mealId === undefined ? undefined : plan.mealNames[mealId];
      return title === undefined ? [] : [{ slot, title }];
    }),
  };
}

/** Today's box per child by first name; a weekend has none. */
function lunchPanel(sources: FrameDaySources): NonNullable<FrameDay['lunch']> {
  if (weekdayOf(sources.today) > 5) return { boxes: [] };
  const boxes = (sources.lunch ?? []).flatMap(({ childId, picks }) => {
    const child = sources.names[childId];
    const name = child === undefined ? '' : firstName(child);
    if (name === '' || picks.length === 0) return [];
    const items = [...picks]
      .sort((a, b) => LUNCH_SLOTS.indexOf(a.slot) - LUNCH_SLOTS.indexOf(b.slot))
      .map(({ slot, name: title }) => ({ slot, title }));
    const photo = sources.lunchPhotos?.[childId]?.id;
    return [{ name, items, ...(photo === undefined ? {} : { photo }) }];
  });
  return { boxes: boxes.sort(byName) };
}
