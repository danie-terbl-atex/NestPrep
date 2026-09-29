/**
 * A day with no time and no zone, as `YYYY-MM-DD` — the way the app's
 * `CalendarDate` is stored (foundation ADR-0007). Arithmetic is done at noon
 * UTC, where no clock change can move a day.
 */

const DAY = /^(\d{4})-(\d{2})-(\d{2})$/;

/** The day, or null when the text is not a day that exists (31 February). */
export function parseDay(text: string): string | null {
  const match = DAY.exec(text);
  if (match === null) return null;
  const [year, month, day] = [Number(match[1]), Number(match[2]), Number(match[3])];
  const date = new Date(Date.UTC(year, month - 1, day, 12));
  const exists =
    date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day;
  return exists ? text : null;
}

export function addDays(day: string, days: number): string {
  const date = new Date(`${day}T12:00:00Z`);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

/** Monday 1 to Sunday 7, as the recurrence rule stores weekdays. */
export function isoWeekday(day: string): number {
  const weekday = new Date(`${day}T12:00:00Z`).getUTCDay();
  return weekday === 0 ? 7 : weekday;
}

/** Today on the household's clock, and its weekday's English name. */
export function todayIn(timeZone: string, now: Date): { today: string; weekday: string } {
  let today: string;
  try {
    today = new Intl.DateTimeFormat('en-CA', {
      timeZone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(now);
  } catch {
    // A zone this runtime cannot read: the household's day is still close
    // to UTC's for every zone NestPrep serves.
    today = now.toISOString().slice(0, 10);
  }
  const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return { today, weekday: names[isoWeekday(today) - 1] ?? 'Monday' };
}
