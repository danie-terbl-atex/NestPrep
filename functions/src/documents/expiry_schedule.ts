/**
 * When a document with an expiry date raises a reminder (documents ADR-0005).
 *
 * **This is a contract with the app.** `app/lib/features/documents/model/
 * expiry_schedule.dart` holds the same offsets for the badges a person sees,
 * and `app/test/features/documents/model/expiry_schedule_contract_test.dart`
 * reads this file and fails if the two disagree.
 *
 * Dates here are `YYYY-MM-DD` strings meaning a day in the household's own
 * timezone (`ENG-21`). The arithmetic is on UTC midnights of those days, which
 * is exact for whole days and has no daylight-saving edge.
 */
export const EXPIRY_REMINDER_DAYS_BEFORE = [90, 30, 7, 0] as const;

/** How long after expiring a document still raises its "expired" reminder. */
export const EXPIRED_GRACE_DAYS = 7;

const MS_PER_DAY = 24 * 60 * 60 * 1000;
const ISO_DAY = /^(\d{4})-(\d{2})-(\d{2})$/;

/** The UTC midnight of a `YYYY-MM-DD` day, or undefined for anything else. */
export function dayNumber(iso: string): number | undefined {
  const match = ISO_DAY.exec(iso);
  if (match === null) return undefined;
  const [year, month, day] = [Number(match[1]), Number(match[2]), Number(match[3])];
  const midnight = Date.UTC(year, month - 1, day);
  const back = new Date(midnight);
  // 2031-02-31 parses as 3 March; a day that is not in the calendar is refused.
  if (back.getUTCMonth() !== month - 1 || back.getUTCDate() !== day) return undefined;
  return midnight / MS_PER_DAY;
}

export function isoOfDayNumber(days: number): string {
  return new Date(days * MS_PER_DAY).toISOString().slice(0, 10);
}

export function addDays(iso: string, days: number): string {
  const start = dayNumber(iso);
  if (start === undefined) throw new RangeError(`not a calendar day: ${iso}`);
  return isoOfDayNumber(start + days);
}

/**
 * Today in the household's zone. An unknown zone falls back to UTC, the same
 * answer `HouseholdClock` gives on the client (foundation ADR-0007).
 */
export function todayIn(timeZone: string, now: Date): string {
  const format = (zone: string): string =>
    new Intl.DateTimeFormat('en-CA', {
      timeZone: zone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(now);
  try {
    return format(timeZone);
  } catch {
    // RangeError for a zone the runtime's IANA data does not know. UTC is the
    // documented fallback, not a swallowed error (foundation ADR-0007).
    return format('UTC');
  }
}

/**
 * The reminder a document is due today, as days-before-expiry — the tightest
 * offset it has reached, 0 on or after the day itself — or undefined when none
 * is due (too far off, too long expired, or not a date).
 *
 * Only the current stage is ever raised, so a job that did not run for a week
 * catches up with one reminder rather than four stale ones.
 */
export function reminderStage(expiresOn: string, today: string): number | undefined {
  const expires = dayNumber(expiresOn);
  const now = dayNumber(today);
  if (expires === undefined || now === undefined) return undefined;
  const daysLeft = expires - now;
  if (daysLeft < -EXPIRED_GRACE_DAYS) return undefined;
  if (daysLeft <= 0) return 0;
  const reached = EXPIRY_REMINDER_DAYS_BEFORE.filter((offset) => offset > 0 && daysLeft <= offset);
  return reached.length === 0 ? undefined : Math.min(...reached);
}

export type ReminderScope = 'vault' | 'household';

export interface ReminderKey {
  readonly scope: ReminderScope;
  readonly ownerMemberId: string | null;
  readonly documentId: string;
  readonly expiresOn: string;
  readonly daysBefore: number;
}

/**
 * The reminder's document id. Deterministic, so writing it twice is a no-op,
 * and it carries the expiry date, so changing a document's date raises fresh
 * reminders for the new one (BE-15).
 */
export function reminderId(key: ReminderKey): string {
  return [
    key.scope,
    key.ownerMemberId ?? 'household',
    key.documentId,
    key.expiresOn,
    String(key.daysBefore),
  ].join('_');
}
