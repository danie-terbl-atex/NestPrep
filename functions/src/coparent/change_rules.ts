import { daysBetween, isWithin, isoDaysFrom, parseIsoDate, today, addDays } from './custody_dates';
import { refuseCoParent } from './errors';
import type { Side } from './schedule_schema';
import { MAX_SWAP_DAYS } from './schemas';

/**
 * The decisions the request callables make, pure so they are tested without
 * an emulator (household ADR-0004).
 */

/** How far back a swap may start: last week's mix-up can still be written down. */
export const SWAP_DAYS_BACK = 7;
/** How far ahead anything may be arranged. */
export const DAYS_AHEAD = 365;
/** How far back a handover may be written up. */
export const HANDOVER_DAYS_BACK = 60;
/** Open requests one link may hold at once. */
export const MAX_OPEN_REQUESTS = 10;

/** The days a swap moves, or the refusal that says it cannot. */
export function swapDays(from: string, to: string, now: Date = new Date()): string[] {
  const start = parseIsoDate(from);
  const end = parseIsoDate(to);
  if (start === null || end === null) throw refuseCoParent('dateOutOfRange');
  const span = daysBetween(start, end) + 1;
  if (span < 1 || span > MAX_SWAP_DAYS) throw refuseCoParent('dateOutOfRange');
  if (!isWithin(start, SWAP_DAYS_BACK, DAYS_AHEAD, now)) throw refuseCoParent('dateOutOfRange');
  return isoDaysFrom(start, end);
}

/**
 * The days a stored swap moves when it is accepted. The window was checked
 * when it was asked; a swap accepted after its days have passed still records
 * what happened, so no window applies here — only the fourteen-day cap.
 */
export function storedSwapDays(from: string, to: string): string[] {
  const start = parseIsoDate(from);
  const end = parseIsoDate(to);
  if (start === null || end === null) return [];
  const span = daysBetween(start, end) + 1;
  return span < 1 || span > MAX_SWAP_DAYS ? [] : isoDaysFrom(start, end);
}

/** Whether a handover on `date` may be written now. */
export function requireHandoverDate(date: string, now: Date = new Date()): void {
  const day = parseIsoDate(date);
  if (day === null || !isWithin(day, HANDOVER_DAYS_BACK, DAYS_AHEAD, now)) {
    throw refuseCoParent('dateOutOfRange');
  }
}

/**
 * The overrides after an accepted swap: the swapped days now belong to
 * `toSide`, and anything older than a year is dropped, so the link document
 * never grows without end.
 */
export function withSwap(
  overrides: Readonly<Record<string, Side>>,
  days: readonly string[],
  toSide: Side,
  now: Date = new Date(),
): Record<string, Side> {
  const oldest = addDays(today(now), -DAYS_AHEAD);
  const kept: Record<string, Side> = {};
  for (const [day, side] of Object.entries(overrides)) {
    const date = parseIsoDate(day);
    if (date !== null && date.getTime() >= oldest.getTime()) kept[day] = side;
  }
  for (const day of days) kept[day] = toSide;
  return kept;
}

export type Answer = 'accept' | 'decline' | 'withdraw';

/**
 * Who may say what: the other home accepts or declines; the home that asked
 * may only withdraw. Nobody answers their own question.
 */
export function mayAnswer(callerSide: Side, proposedBySide: Side, answer: Answer): boolean {
  return answer === 'withdraw' ? callerSide === proposedBySide : callerSide !== proposedBySide;
}

/** The status a request is left in by an answer. */
export function statusAfter(answer: Answer): 'accepted' | 'declined' | 'withdrawn' {
  switch (answer) {
    case 'accept':
      return 'accepted';
    case 'decline':
      return 'declined';
    case 'withdraw':
      return 'withdrawn';
  }
}
