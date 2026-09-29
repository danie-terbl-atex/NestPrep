/**
 * Calendar-date arithmetic for co-parenting (household ADR-0004): days as
 * `YYYY-MM-DD`, held as UTC midnights so adding a day never crosses a
 * daylight-saving boundary. The server never expands a schedule — the client
 * does, through the recurrence model — so this is only what the callables need
 * to check a date and to name the days a swap moves.
 */

const ISO_DATE = /^(\d{4})-(\d{2})-(\d{2})$/;
const DAY_MS = 24 * 60 * 60 * 1000;

/** The UTC midnight of an ISO date, or null when it is not a real day. */
export function parseIsoDate(value: string): Date | null {
  const match = ISO_DATE.exec(value);
  if (match === null) return null;
  const [year, month, day] = [Number(match[1]), Number(match[2]), Number(match[3])];
  const date = new Date(Date.UTC(year, month - 1, day));
  const roundTrips =
    date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day;
  return roundTrips ? date : null;
}

export function isoOf(date: Date): string {
  return date.toISOString().slice(0, 10);
}

export function addDays(date: Date, days: number): Date {
  return new Date(date.getTime() + days * DAY_MS);
}

/** Whole days from `from` to `to`; negative when `to` is earlier. */
export function daysBetween(from: Date, to: Date): number {
  return Math.round((to.getTime() - from.getTime()) / DAY_MS);
}

/** ISO weekday: Monday is 1, Sunday is 7 — the recurrence model's numbering. */
export function isoWeekday(date: Date): number {
  const day = date.getUTCDay();
  return day === 0 ? 7 : day;
}

/** Today as the server sees it, as a UTC midnight. */
export function today(now: Date = new Date()): Date {
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
}

/**
 * Whether `value` falls within `[now - back, now + ahead]` days. The server's
 * day is UTC and a household's is not, so every window is a day wider on each
 * side than the rule it enforces.
 */
export function isWithin(
  value: Date,
  back: number,
  ahead: number,
  now: Date = new Date(),
): boolean {
  const offset = daysBetween(today(now), value);
  return offset >= -(back + 1) && offset <= ahead + 1;
}

/** Every day from `from` to `to`, inclusive, as ISO dates. */
export function isoDaysFrom(from: Date, to: Date): string[] {
  const days: string[] = [];
  for (let day = from; day.getTime() <= to.getTime(); day = addDays(day, 1)) {
    days.push(isoOf(day));
  }
  return days;
}
