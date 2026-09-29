/**
 * Instants and the wall clock of a named zone, through the IANA database Node
 * already carries (`Intl`). The server's half of what `HouseholdClock` does on
 * the phone (calendar ADR-0002, foundation ADR-0007): the one place an instant
 * becomes a household's day and minute, and back.
 *
 * Days are `YYYY-MM-DD` strings throughout, because that is how they are
 * stored and compared.
 */

export interface WallClock {
  readonly date: string;
  readonly minute: number;
}

const MINUTE_MS = 60_000;
const DAY_MS = 86_400_000;
// A plain record rather than a Map: the atomic-writes check reads every Map
// write in this codebase as a Firestore write.
const formatters: Record<string, Intl.DateTimeFormat | undefined> = {};

function formatter(zone: string): Intl.DateTimeFormat {
  let found = formatters[zone];
  if (found === undefined) {
    found = new Intl.DateTimeFormat('en-US', {
      timeZone: zone,
      hourCycle: 'h23',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
    formatters[zone] = found;
  }
  return found;
}

/** Whether this runtime knows [zone] — a stored name can outlive tzdata. */
export function isKnownZone(zone: string): boolean {
  try {
    formatter(zone);
    return true;
  } catch (error) {
    if (error instanceof RangeError) return false;
    throw error;
  }
}

/** [zone] when it is known, else UTC — a calendar an hour out beats none (BE-10). */
export function knownZoneOr(zone: string | undefined): string {
  return zone !== undefined && isKnownZone(zone) ? zone : 'UTC';
}

/** The day and minute [instant] shows on a clock in [zone]. */
export function wallClockOf(instant: Date, zone: string): WallClock {
  const parts: Record<string, string> = {};
  for (const part of formatter(zone).formatToParts(instant)) parts[part.type] = part.value;
  const hour = Number(parts['hour']) % 24;
  return {
    date: `${parts['year'] ?? ''}-${parts['month'] ?? ''}-${parts['day'] ?? ''}`,
    minute: hour * 60 + Number(parts['minute']),
  };
}

/** How far [zone]'s clock is ahead of UTC at [instant], in milliseconds. */
function offsetMs(instant: Date, zone: string): number {
  const clock = wallClockOf(instant, zone);
  const asUtc = Date.parse(`${clock.date}T00:00:00Z`) + clock.minute * MINUTE_MS;
  return asUtc - Math.floor(instant.getTime() / MINUTE_MS) * MINUTE_MS;
}

/**
 * The instant [minute] on [date] means in [zone]. A time that does not exist
 * (the hour skipped when clocks go forward) lands just after the gap; one that
 * happens twice lands on the first — what every calendar does.
 */
export function instantOf(date: string, minute: number, zone: string): Date {
  const guess = Date.parse(`${date}T00:00:00Z`) + minute * MINUTE_MS;
  // The offset a day either side of the moment is the offset either side of
  // any clocks change near it; one of the two readings is the answer.
  const early = guess - offsetMs(new Date(guess - DAY_MS), zone);
  const late = guess - offsetMs(new Date(guess + DAY_MS), zone);
  const shows = (instant: number): boolean => {
    const clock = wallClockOf(new Date(instant), zone);
    return clock.date === date && clock.minute === minute;
  };
  if (shows(early) && shows(late)) return new Date(Math.min(early, late));
  if (shows(late)) return new Date(late);
  return new Date(early);
}

export function addDays(date: string, days: number): string {
  return new Date(Date.parse(`${date}T00:00:00Z`) + days * DAY_MS).toISOString().slice(0, 10);
}

export function daysBetween(from: string, to: string): number {
  return Math.round((Date.parse(`${to}T00:00:00Z`) - Date.parse(`${from}T00:00:00Z`)) / DAY_MS);
}

/** ISO weekday of a day: Monday is 1 and Sunday is 7, as the app's rule uses. */
export function weekdayOf(date: string): number {
  const day = new Date(`${date}T00:00:00Z`).getUTCDay();
  return day === 0 ? 7 : day;
}

export function daysInMonth(year: number, month: number): number {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

export function isoDate(year: number, month: number, day: number): string {
  return `${String(year).padStart(4, '0')}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}
