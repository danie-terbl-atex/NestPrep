import { CLAIM_WINDOW_DAYS } from '../chore_points/chore_eligibility';
import { isOccurrence } from '../chore_points/occurrence_check';
import { addDays } from '../documents/expiry_schedule';
import type { StoredKidRoutine, StoredRoutineTick } from './routine_documents';

/**
 * Whether one child's day of a routine should earn its stars (kid-routines
 * ADR-0001). Pure: the trigger reads the documents, this decides.
 *
 * It earns only when the routine still exists and carries stars, names the
 * child, the child is a `kid` profile, the day is a real occurrence no later
 * than today and no more than [CLAIM_WINDOW_DAYS] back, and every step the
 * routine has *now* is done — each a way a child's device could otherwise
 * mint stars.
 */

export interface AwardFacts {
  readonly tick: StoredRoutineTick;
  readonly routine: StoredKidRoutine | undefined;
  /** The stored role of the tick's child. */
  readonly kidRole: string | undefined;
  /** `YYYY-MM-DD` in the household's zone. */
  readonly today: string;
}

export interface DesiredAward {
  readonly memberId: string;
  readonly routineId: string;
  readonly occurrenceDate: string;
  readonly title: string;
  readonly points: number;
}

export type Ineligible =
  | 'noRoutine'
  | 'noStars'
  | 'notNamed'
  | 'notAKid'
  | 'inTheFuture'
  | 'tooLongAgo'
  | 'notAnOccurrence'
  | 'notFinished';

export function decideAward(facts: AwardFacts): DesiredAward | Ineligible {
  const { tick, routine, today } = facts;
  if (routine === undefined) return 'noRoutine';
  if (routine.points <= 0) return 'noStars';
  if (!routine.kidIds.includes(tick.kidId)) return 'notNamed';
  if (facts.kidRole !== 'kid') return 'notAKid';

  const date = tick.occurrenceDate;
  if (date > today) return 'inTheFuture';
  if (date < addDays(today, -CLAIM_WINDOW_DAYS)) return 'tooLongAgo';
  if (!isOccurrence(routine.firstDate, routine.recurrence, date)) return 'notAnOccurrence';

  const finished =
    routine.steps.length > 0 && routine.steps.every((step) => tick.doneStepIds.includes(step.id));
  if (!finished) return 'notFinished';

  return {
    memberId: tick.kidId,
    routineId: tick.routineId,
    occurrenceDate: date,
    title: routine.name,
    points: routine.points,
  };
}
