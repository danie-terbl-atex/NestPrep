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
}

export interface SyncedEventRecord {
  readonly title: string;
  readonly date: string;
  readonly endDate: string;
  readonly startMinute: number | null;
  readonly memberId: string;
}

/** Today's events: the household's own, less skipped ones, and imported ones. */
export function eventsOn(
  today: string,
  own: readonly HouseholdEventRecord[],
  skippedEventIds: ReadonlySet<string>,
  synced: readonly SyncedEventRecord[],
): DayEvent[] {
  const fromOwn = own
    .filter((record) => !skippedEventIds.has(record.id))
    .filter((record) => isOccurrence(record.event.date, record.event.recurrence ?? null, today))
    .map((record) => ({
      title: record.event.title,
      startMinute: record.event.startMinute ?? null,
      memberIds: [...record.memberIds],
    }));
  const fromSynced = synced
    .filter((record) => record.date <= today && record.endDate >= today)
    .map((record) => ({
      title: record.title,
      // A day in the middle of a multi-day event is all of that day.
      startMinute: record.date === today ? record.startMinute : null,
      memberIds: [record.memberId],
    }));
  return [...fromOwn, ...fromSynced].sort(
    (a, b) => (a.startMinute ?? -1) - (b.startMinute ?? -1) || a.title.localeCompare(b.title),
  );
}

export interface TaskRecord {
  readonly id: string;
  readonly task: StoredTask;
}

/**
 * Today's chores still to do: a task on today by its own schedule, or by its
 * routine's when it has one, with the routine's default assignees when the
 * task names none (todos ADR-0001) — and not already ticked today.
 */
export function choresOn(
  today: string,
  tasks: readonly TaskRecord[],
  routines: Readonly<Record<string, StoredRoutine | undefined>>,
  doneTaskIds: ReadonlySet<string>,
): ChoreToday[] {
  return tasks.flatMap(({ id, task }) => {
    if (doneTaskIds.has(id)) return [];
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
    return [{ title: task.title, assigneeIds: [...assigneeIds] }];
  });
}
