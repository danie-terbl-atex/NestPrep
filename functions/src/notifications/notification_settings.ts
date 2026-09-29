import { z } from 'zod';

import { addDays, instantOf, wallClockOf } from '../calendar_sync/zoned_time';
import {
  DEFAULT_DIGEST_MINUTE,
  DEFAULT_QUIET_END,
  DEFAULT_QUIET_START,
  DIGEST_STEP_MINUTES,
  SWITCHABLE_CATEGORIES,
  type NotificationCategory,
  type SwitchableCategory,
} from './notification_contract';

/**
 * One person's notification choices, as the app writes them at
 * `households/{h}/notificationSettings/{memberId}` (notifications ADR-0003).
 *
 * Read defensively: the rules check the shape on the way in, but a document
 * is still data from outside (ENG-09). A missing document, or a field this
 * build does not know, falls back to the defaults below — never to "send
 * everything at 3am" (BE-10).
 */

const minuteOfDay = z.number().int().min(0).max(1439);

const storedSettings = z.object({
  digest: z.object({ enabled: z.boolean(), minute: minuteOfDay }).partial().default({}),
  categories: z.record(z.string(), z.boolean()).default({}),
  quietHours: z
    .object({ enabled: z.boolean(), startMinute: minuteOfDay, endMinute: minuteOfDay })
    .partial()
    .default({}),
});

export interface QuietHours {
  readonly enabled: boolean;
  readonly startMinute: number;
  readonly endMinute: number;
}

export interface NotificationSettings {
  readonly digestEnabled: boolean;
  /** Minutes after local midnight, a multiple of fifteen. */
  readonly digestMinute: number;
  readonly categories: Readonly<Record<SwitchableCategory, boolean>>;
  readonly quietHours: QuietHours;
}

/**
 * What somebody who has never opened the settings gets. The digest is off
 * until a person chooses it — the app writes it on for family the moment they
 * allow notifications (ADR-0003) — and every category is on, because a
 * reminder nobody can see is the failure this feature exists to prevent.
 */
export const DEFAULT_SETTINGS: NotificationSettings = {
  digestEnabled: false,
  digestMinute: DEFAULT_DIGEST_MINUTE,
  categories: { documents: true, handover: true, chores: true, photos: true, coParenting: true },
  quietHours: { enabled: true, startMinute: DEFAULT_QUIET_START, endMinute: DEFAULT_QUIET_END },
};

function onTheStep(minute: number | undefined, fallback: number): number {
  if (minute === undefined) return fallback;
  return minute - (minute % DIGEST_STEP_MINUTES);
}

export function readSettings(stored: unknown): NotificationSettings {
  const parsed = storedSettings.safeParse(stored ?? {});
  if (!parsed.success) return DEFAULT_SETTINGS;
  const { digest, categories, quietHours } = parsed.data;
  const chosen = Object.fromEntries(
    SWITCHABLE_CATEGORIES.map((category) => [
      category,
      categories[category] ?? DEFAULT_SETTINGS.categories[category],
    ]),
  ) as Record<SwitchableCategory, boolean>;
  return {
    digestEnabled: digest.enabled ?? DEFAULT_SETTINGS.digestEnabled,
    digestMinute: onTheStep(digest.minute, DEFAULT_SETTINGS.digestMinute),
    categories: chosen,
    quietHours: {
      enabled: quietHours.enabled ?? DEFAULT_SETTINGS.quietHours.enabled,
      startMinute: quietHours.startMinute ?? DEFAULT_SETTINGS.quietHours.startMinute,
      endMinute: quietHours.endMinute ?? DEFAULT_SETTINGS.quietHours.endMinute,
    },
  };
}

/** Whether this person wants to hear about [category] at all. */
export function wantsCategory(
  settings: NotificationSettings,
  category: NotificationCategory,
): boolean {
  switch (category) {
    case 'digest':
      return settings.digestEnabled;
    case 'test':
      return true;
    default:
      return settings.categories[category];
  }
}

/** Whether [minute] falls inside a window that may wrap past midnight. */
export function isInsideWindow(minute: number, startMinute: number, endMinute: number): boolean {
  if (startMinute === endMinute) return false;
  return startMinute < endMinute
    ? minute >= startMinute && minute < endMinute
    : minute >= startMinute || minute < endMinute;
}

/**
 * When a push to this person may go: [now], or — inside their quiet hours —
 * the instant the quiet hours end, on the household's clock (foundation
 * ADR-0007). The inbox has the notification at once either way; only the
 * buzz waits.
 */
export function sendAfter(quiet: QuietHours, zone: string, now: Date): Date {
  if (!quiet.enabled) return now;
  const clock = wallClockOf(now, zone);
  if (!isInsideWindow(clock.minute, quiet.startMinute, quiet.endMinute)) return now;
  const endsToday = instantOf(clock.date, quiet.endMinute, zone);
  if (endsToday.getTime() > now.getTime()) return endsToday;
  return instantOf(addDays(clock.date, 1), quiet.endMinute, zone);
}
