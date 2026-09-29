import { z } from 'zod';

import { isPremiumAt } from '../subscriptions/subscription_documents';
import type { MonthlyCalls } from './ai_settings';

/**
 * The pure half of the monthly cap (foundation ADR-0015): which month a call
 * falls in, which tier the household is on, and whether one more call fits.
 * The ledger applies these inside a transaction; here they are tested with no
 * Firestore at all.
 */

export type AiTier = 'free' | 'premium';

/**
 * The household's month, `YYYY-MM`, on its own clock — a family in
 * Johannesburg gets its new calls at its own midnight on the 1st, not UTC's.
 * A zone the runtime cannot read counts in UTC rather than failing the call.
 */
export function monthKeyIn(timeZone: string, now: Date): string {
  let parts: Intl.DateTimeFormatPart[];
  try {
    parts = new Intl.DateTimeFormat('en-CA', {
      timeZone,
      year: 'numeric',
      month: '2-digit',
    }).formatToParts(now);
  } catch {
    return now.toISOString().slice(0, 7);
  }
  const year = parts.find((part) => part.type === 'year')?.value;
  const month = parts.find((part) => part.type === 'month')?.value;
  return year !== undefined && month !== undefined
    ? `${year}-${month}`
    : now.toISOString().slice(0, 7);
}

const entitlementShape = z.object({ premiumUntil: z.unknown() });

/**
 * Premium while `households/{h}/entitlement/current.premiumUntil` is in the
 * future — read by subscriptions' own `isPremiumAt`, the same test the free
 * tier's limits make and the rule `hasPremium` makes, so a referral month
 * (subscriptions ADR-0002) raises the AI cap exactly when it unlocks
 * everything else. A missing document, a missing field or anything that is
 * not a Timestamp is free.
 */
export function tierFrom(entitlement: unknown, now: Date): AiTier {
  const parsed = entitlementShape.safeParse(entitlement);
  return parsed.success && isPremiumAt(parsed.data.premiumUntil, now) ? 'premium' : 'free';
}

export function capFor(tier: AiTier, monthlyCalls: MonthlyCalls): number {
  return monthlyCalls[tier];
}

/**
 * A month's counters as stored. `calls` is what the household is charged —
 * a call that failed is refunded. `attempts` counts every call started, and
 * is never refunded, so a call that fails over and over is still bounded.
 */
export interface MonthUsage {
  readonly calls: number;
  readonly attempts: number;
}

const storedUsage = z.object({
  calls: z.number().int().min(0).catch(0),
  attempts: z.number().int().min(0).catch(0),
});

export function readMonthUsage(stored: unknown): MonthUsage {
  const parsed = storedUsage.safeParse(stored ?? {});
  return parsed.success ? parsed.data : { calls: 0, attempts: 0 };
}

/** Failed attempts allowed on top of the cap before the month is closed anyway. */
export const ATTEMPT_HEADROOM = 3;

export type ClaimDecision =
  | { readonly allowed: true; readonly callsAfter: number; readonly callsLeft: number }
  | { readonly allowed: false };

/**
 * Whether one more call fits: under the cap in charged calls, and under
 * three times it in attempts. A cap of zero switches the tier off.
 */
export function decideClaim(usage: MonthUsage, cap: number): ClaimDecision {
  if (usage.calls >= cap) return { allowed: false };
  if (usage.attempts >= cap * ATTEMPT_HEADROOM) return { allowed: false };
  const callsAfter = usage.calls + 1;
  return { allowed: true, callsAfter, callsLeft: cap - callsAfter };
}
