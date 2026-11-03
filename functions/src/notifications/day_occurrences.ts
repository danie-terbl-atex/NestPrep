import { isOccurrence } from '../chore_points/occurrence_check';
import type { StoredRoutine, StoredTask } from '../chore_points/point_documents';
import type { StoredEvent } from '../calendar_sync/feed_writer';
import type { ChoreToday, DayEvent } from './digest_facts';

/**
 * What happens *today*, worked out from what is stored (notifications
 * ADR-0002). The recurrence arithmetic is the one the server already has —
 * `isOccurrence`, the Functions' copy of the app's expansion — so an event
 * that repeats every second Tuesday is in the digest on exactly the Tuesdays
 * the week view shows it (ENG-01).
 */

export interface HouseholdEventRecord {
  readonly id: string;
  readonly event: StoredEvent;
  readonly memberIds: readonly string[];
  readonly note?: string | null;
}

export interface SyncedEventRecord {
  readonly title: string;
  readonly date: string;
  readonly endDate: string;
  readonly startMinute: number | null;
  readonly endMinute?: number | null;
  readonly memberId: string;
}

/** A day's event with the minute it ends, for a reader that shows the span. */
export interface EventOccurrence extends DayEvent {
  /** Minutes after local midnight; null when it ends on another day or is all day. */
  readonly endMinute: number | null;
  /** As stored; an import carries none. */
  readonly note: string | null;
  readonly repeats: boolean;
}

/** [today]'s events: the household's own, less skipped ones, and imported ones. */
export function eventOccurrencesOn(
  today: string,
  own: readonly HouseholdEventRecord[],
  skippedEventIds: ReadonlySet<string>,
  synced: readonly SyncedEventRecord[],
): EventOccurrence[] {
  const fromOwn = own
    .filter((record) => !skippedEventIds.has(record.id))
    .filter((record) => isOccurrence(record.event.date, record.event.recurrence ?? null, today))
    .map((record) => {
      const startMinute = record.event.startMinute ?? null;
      return {
        title: record.event.title,
        startMinute,
        endMinute: startMinute === null ? null : (record.event.endMinute ?? null),
        memberIds: [...record.memberIds],
        note: record.note ?? null,
        repeats: (record.event.recurrence ?? null) !== null,
      };
    });
  const fromSynced = synced
    .filter((record) => record.date <= today && record.endDate >= today)
    .map((record) => {
      // A day in the middle of a multi-day event is all of that day.
      const startMinute = record.date === today ? record.startMinute : null;
      return {
        title: record.title,
        startMinute,
        endMinute:
          startMinute !== null && record.endDate === today ? (record.endMinute ?? null) : null,
        memberIds: [record.memberId],
        note: null,
        repeats: false,
      };
    });
  return [...fromOwn, ...fromSynced].sort(
    (a, b) => (a.startMinute ?? -1) - (b.startMinute ?? -1) || a.title.localeCompare(b.title),
  );
}

/** Today's events, as the digest says them. */
export function eventsOn(
  today: string,
  own: readonly HouseholdEventRecord[],
  skippedEventIds: ReadonlySet<string>,
  synced: readonly SyncedEventRecord[],
): DayEvent[] {
  return eventOccurrencesOn(today, own, skippedEventIds, synced).map(
    ({ title, startMinute, memberIds }) => ({ title, startMinute, memberIds }),
  );
}

export interface TaskRecord {
  readonly id: string;
  readonly task: StoredTask;
  readonly note?: string | null;
}

/** A day's chore with what a reader that shows the whole chore needs. */
export interface ChoreOccurrence extends ChoreToday {
  readonly taskId: string;
  readonly note: string | null;
  readonly points: number;
  readonly needsApproval: boolean;
}

/**
 * Every chore on [today], ticked or not: a task on today by its own schedule,
 * or by its routine's when it has one, with the routine's default assignees
 * when the task names none (todos ADR-0001).
 */
export function choreOccurrencesOn(
  today: string,
  tasks: readonly TaskRecord[],
  routines: Readonly<Record<string, StoredRoutine | undefined>>,
): ChoreOccurrence[] {
  return tasks.flatMap(({ id, task, note }) => {
    const routine = task.routineId === null ? undefined : routines[task.routineId];
    const schedule =
      routine === undefined
        ? { firstDate: task.dueDate, rule: task.recurrence }
        : { firstDate: routine.firstDate, rule: routine.recurrence };
    if (!isOccurrence(schedule.firstDate, schedule.rule, today)) return [];
    const assigneeIds =
      task.assigneeIds.length === 0 && routine !== undefined
        ? routine.defaultAssigneeIds
        : task.assigneeIds;
    return [
      {
        taskId: id,
        title: task.title,
        assigneeIds: [...assigneeIds],
        note: note ?? null,
        points: task.points,
        needsApproval: task.needsApproval,
      },
    ];
  });
}

/** Today's chores still to do — the ones not already ticked today. */
export function choresOn(
  today: string,
  tasks: readonly TaskRecord[],
  routines: Readonly<Record<string, StoredRoutine | undefined>>,
  doneTaskIds: ReadonlySet<string>,
): ChoreToday[] {
  return choreOccurrencesOn(today, tasks, routines)
    .filter((chore) => !doneTaskIds.has(chore.taskId))
    .map(({ title, assigneeIds }) => ({ title, assigneeIds }));
}
