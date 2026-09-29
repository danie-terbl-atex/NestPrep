import { addDays, isoWeekday } from '../school_letter/plain_date';

/**
 * ISO-8601 weeks, as the app's `LunchWeek` names them (`YYYY-Www`) — the key a
 * lunch plan is filed under — and the Monday a meal plan is filed under.
 * Arithmetic on `YYYY-MM-DD` at noon UTC, where no clock change moves a day.
 */

const WEEK = /^(\d{4})-W(\d{2})$/;

/** The Monday of the week [day] falls in. */
export function mondayOf(day: string): string {
  return addDays(day, 1 - isoWeekday(day));
}

/** `YYYY-Www` of the week starting [monday]: its Thursday's year and number. */
export function weekKeyOf(monday: string): string {
  const thursday = addDays(monday, 3);
  const year = Number(thursday.slice(0, 4));
  const firstOfYear = `${String(year)}-01-01`;
  const days = Math.round(
    (Date.parse(`${thursday}T12:00:00Z`) - Date.parse(`${firstOfYear}T12:00:00Z`)) / 86_400_000,
  );
  const number = Math.floor(days / 7) + 1;
  return `${String(year).padStart(4, '0')}-W${String(number).padStart(2, '0')}`;
}

/**
 * The Monday of the week [key] names, or null when it is not a week that
 * exists (`2026-W60`). 4 January is always in week 1.
 */
export function mondayOfWeek(key: string): string | null {
  const match = WEEK.exec(key);
  if (match === null) return null;
  const year = Number(match[1]);
  const number = Number(match[2]);
  const weekOne = mondayOf(`${String(year).padStart(4, '0')}-01-04`);
  const monday = addDays(weekOne, (number - 1) * 7);
  return weekKeyOf(monday) === key ? monday : null;
}

/** Monday to Friday, `1` to `5`. */
export const SCHOOL_DAYS = [1, 2, 3, 4, 5] as const;

/** Monday to Sunday, `1` to `7`. */
export const WEEK_DAYS = [1, 2, 3, 4, 5, 6, 7] as const;

/** How many weeks back the learning reads (lunch-box ADR-0003). */
export const HISTORY_WEEKS = 8;
