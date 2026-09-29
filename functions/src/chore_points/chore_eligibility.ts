import { FAMILY_ROLES } from '../household/access';
import { addDays } from '../documents/expiry_schedule';
import { isOccurrence } from './occurrence_check';
import type { StoredCompletion, StoredRoutine, StoredTask } from './point_documents';

/**
 * Whether one completion should earn a child stars, and how (todos ADR-0003).
 * Pure: the trigger reads the documents, this decides.
 *
 * A completion earns only when every one of these holds — each is a way a
 * child's own device could otherwise mint stars:
 *
 * - the task still exists and carries stars;
 * - the child it was done for is a `kid` profile — only kids earn;
 * - the date is a real occurrence of the chore's schedule, which is its
 *   routine's when it has one (todos ADR-0001);
 * - and it is no later than today and no more than [CLAIM_WINDOW_DAYS] back —
 *   exactly the jobs the child's own screen offers.
 */

/** How far back an unfinished chore can still earn: the overdue horizon. */
export const CLAIM_WINDOW_DAYS = 7;

export interface ClaimFacts {
  readonly completion: StoredCompletion;
  readonly task: StoredTask | undefined;
  /** Undefined when the task names no routine, or its routine is gone. */
  readonly routine: StoredRoutine | undefined;
  /** The stored role of the profile it was done for, and of who did it. */
  readonly forRole: string | undefined;
  readonly byRole: string | undefined;
  /** `YYYY-MM-DD` in the household's zone. */
  readonly today: string;
}

export interface DesiredClaim {
  readonly memberId: string;
  readonly taskId: string;
  readonly occurrenceDate: string;
  readonly title: string;
  readonly points: number;
  readonly completedBy: string;
  /** Stars land at once: the chore needs no check, or a parent ticked it. */
  readonly awardsAtOnce: boolean;
}

export type Ineligible =
  'noTask' | 'noStars' | 'notAKid' | 'notAnOccurrence' | 'inTheFuture' | 'tooLongAgo';

export function isFamilyRole(role: string | undefined): boolean {
  return role !== undefined && (FAMILY_ROLES as readonly string[]).includes(role);
}

export function decideClaim(facts: ClaimFacts): DesiredClaim | Ineligible {
  const { completion, task, routine, today } = facts;
  if (task === undefined) return 'noTask';
  if (task.points <= 0) return 'noStars';
  if (facts.forRole !== 'kid') return 'notAKid';

  const date = completion.occurrenceDate;
  if (date > today) return 'inTheFuture';
  if (date < addDays(today, -CLAIM_WINDOW_DAYS)) return 'tooLongAgo';

  const schedule =
    task.routineId !== null && routine !== undefined
      ? { firstDate: routine.firstDate, rule: routine.recurrence }
      : { firstDate: task.dueDate, rule: task.recurrence };
  if (!isOccurrence(schedule.firstDate, schedule.rule, date)) return 'notAnOccurrence';

  return {
    memberId: completion.completedFor,
    taskId: completion.taskId,
    occurrenceDate: date,
    title: task.title,
    points: task.points,
    completedBy: completion.completedBy,
    awardsAtOnce: !task.needsApproval || isFamilyRole(facts.byRole),
  };
}
