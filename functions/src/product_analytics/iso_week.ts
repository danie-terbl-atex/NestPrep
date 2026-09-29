/**
 * The week every beta number is counted in: ISO-8601, Monday to Sunday, keyed
 * `YYYY-Www` (product-analytics ADR-0001).
 *
 * A week is a *local* thing — Sunday night in Johannesburg is already Monday in
 * Auckland — so an instant becomes a week only through the household's own
 * timezone (`ENG-21`). Everything after that is arithmetic on a calendar date,
 * done in UTC so no daylight-saving shift can move a day.
 */

const DAY_MS = 24 * 60 * 60 * 1000;
const WEEK_KEY = /^(\d{4})-W(\d{2})$/;

/** The zone the rollup and the readout reckon "this week" in: the launch market. */
export const LAUNCH_TIME_ZONE = 'Africa/Johannesburg';

/** A calendar date with no time and no zone, as UTC midnight. */
function calendarDateIn(instant: Date, timeZone: string): Date {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(instant);
  const part = (type: 'year' | 'month' | 'day'): number =>
    Number(parts.find((candidate) => candidate.type === type)?.value);
  return new Date(Date.UTC(part('year'), part('month') - 1, part('day')));
}

/** The ISO week of a calendar date held as UTC midnight. */
function weekKeyOfDate(date: Date): string {
  const mondayBased = (date.getUTCDay() + 6) % 7;
  // The ISO year of a week is the year its Thursday falls in.
  const thursday = new Date(date.getTime() + (3 - mondayBased) * DAY_MS);
  const year = thursday.getUTCFullYear();
  const dayOfYear = Math.floor((thursday.getTime() - Date.UTC(year, 0, 1)) / DAY_MS);
  const week = Math.floor(dayOfYear / 7) + 1;
  return `${String(year)}-W${String(week).padStart(2, '0')}`;
}

/**
 * Whether the runtime knows this zone. The household's zone is checked only for
 * shape when it is written (household schemas), so a zone this Node's tzdata
 * does not have is possible, and it must not stop a count.
 */
export function isKnownTimeZone(timeZone: string): boolean {
  try {
    new Intl.DateTimeFormat('en-CA', { timeZone });
    return true;
  } catch (error) {
    if (error instanceof RangeError) return false;
    throw error;
  }
}

/** The zone to count a household in: its own, or the launch zone if ours cannot read it. */
export function countingZoneFor(timeZone: string | undefined): string {
  return timeZone !== undefined && isKnownTimeZone(timeZone) ? timeZone : LAUNCH_TIME_ZONE;
}

/** The week an instant falls in, for somebody living in [timeZone]. */
export function weekKeyOf(instant: Date, timeZone: string): string {
  return weekKeyOfDate(calendarDateIn(instant, timeZone));
}

/** The Monday a week starts on, as UTC midnight of that calendar date. */
export function mondayOf(weekKey: string): Date {
  const match = WEEK_KEY.exec(weekKey);
  if (match === null) throw new RangeError(`not a week key: ${weekKey}`);
  const year = Number(match[1]);
  const week = Number(match[2]);
  // 4 January is always in week 1.
  const fourthOfJanuary = new Date(Date.UTC(year, 0, 4));
  const mondayOfWeekOne =
    fourthOfJanuary.getTime() - ((fourthOfJanuary.getUTCDay() + 6) % 7) * DAY_MS;
  return new Date(mondayOfWeekOne + (week - 1) * 7 * DAY_MS);
}

/** `YYYY-MM-DD` of the Monday a week starts on — what a person reads. */
export function weekStartDate(weekKey: string): string {
  return mondayOf(weekKey).toISOString().slice(0, 10);
}

/** The week [offset] weeks after (or, negative, before) [weekKey]. */
export function shiftWeek(weekKey: string, offset: number): string {
  return weekKeyOfDate(new Date(mondayOf(weekKey).getTime() + offset * 7 * DAY_MS));
}
