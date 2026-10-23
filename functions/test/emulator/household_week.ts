import { mondayOf, weekKeyOf } from '../../src/plan_week/iso_week';
import { addDays, todayIn } from '../../src/school_letter/plain_date';

/** The demo and test households' zone, as `createHousehold` is called in the harness. */
export const HOUSEHOLD_TIME_ZONE = 'Africa/Johannesburg';

/**
 * The ISO week after the household's current one, on the household's clock —
 * as `openPlanning` reads "today" — never on UTC's, which is still Sunday
 * for two hours of a South African Monday.
 */
export function nextWeekIn(timeZone: string, now: Date): string {
  const { today } = todayIn(timeZone, now);
  return weekKeyOf(mondayOf(addDays(today, 7)));
}
