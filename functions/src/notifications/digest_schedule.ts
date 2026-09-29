import { wallClockOf } from '../calendar_sync/zoned_time';
import { DIGEST_STEP_MINUTES } from './notification_contract';
import type { NotificationSettings } from './notification_settings';

/**
 * When a morning digest is due (notifications ADR-0002). Pure, so the clock
 * change, the far-away household and the late run are tested without a
 * schedule.
 *
 * A person's digest time is a quarter hour on **their household's** clock. The
 * app stores it with its slot — the minute divided by fifteen — which is what
 * the job asks Firestore for. The job runs every fifteen minutes; each run
 * looks at the slot it is in and the one before, so a run that is late, or
 * one that never came, is caught up by the next. Sending at most once a day
 * is the inbox's job: the digest's id is the person and the local day.
 */

const STEP_MS = DIGEST_STEP_MINUTES * 60_000;

export function slotOf(minute: number): number {
  return Math.floor(minute / DIGEST_STEP_MINUTES);
}

/** The instants a run answers for: now, and the step before it. */
function instantsCoveredBy(now: Date): Date[] {
  return [now, new Date(now.getTime() - STEP_MS)];
}

/** Every zone this runtime knows, for working out which slots are "now" somewhere. */
export function knownZones(): string[] {
  return [...Intl.supportedValuesOf('timeZone'), 'UTC'];
}

/**
 * Every slot that is the current (or the previous) quarter hour in *some*
 * zone. People whose digest slot is one of these are the only ones who could
 * be due; each is then checked against their own household's zone. A handful
 * of offsets exist in the world, so this is a few dozen slots, not ninety-six.
 */
export function candidateSlots(now: Date, zones: readonly string[]): number[] {
  const slots = new Set<number>();
  for (const instant of instantsCoveredBy(now)) {
    for (const zone of zones) slots.add(slotOf(wallClockOf(instant, zone).minute));
  }
  return [...slots].sort((a, b) => a - b);
}

/**
 * The household-local day a digest is due for, or undefined when it is not
 * due in this run. A time the clocks skip that morning is not due that day;
 * one they repeat is due once, because the day is the same both times.
 */
export function dueDigestDay(
  settings: NotificationSettings,
  zone: string,
  now: Date,
): string | undefined {
  if (!settings.digestEnabled) return undefined;
  const wanted = slotOf(settings.digestMinute);
  for (const instant of instantsCoveredBy(now)) {
    const clock = wallClockOf(instant, zone);
    if (slotOf(clock.minute) === wanted) return clock.date;
  }
  return undefined;
}
