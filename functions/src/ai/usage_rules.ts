import { z } from 'zod';

import { isPremiumAt } from '../subscriptions/subscription_documents';
import type { AiCharge, AiFeature, Allowance, AllowanceName, MonthlyCalls } from './ai_settings';

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

export const LIFETIME_USAGE = 'lifetime';

/** How many of [features] a stored `byFeature` map counts; missing or bad is zero. */
export function countOf(stored: unknown, features: readonly AiFeature[]): number {
  const parsed = z
    .object({ byFeature: z.record(z.string(), z.unknown()).catch({}) })
    .safeParse(stored ?? {});
  if (!parsed.success) return 0;
  return features.reduce((total, feature) => {
    const value = parsed.data.byFeature[feature];
    return total + (typeof value === 'number' && Number.isInteger(value) && value > 0 ? value : 0);
  }, 0);
}

export interface AllowanceUsage {
  readonly month: number;
  readonly lifetime: number;
  /** Every call started for the allowance this month, its checks included; never refunded. */
  readonly attempts: number;
}

/** The most calls one creation makes: its reference or words read, the picture, the picture checked. */
export const CALLS_PER_CREATION = 3;

export const ALLOWANCE_ATTEMPTS = 'allowanceAttempts';

export function allowanceAttemptsOf(stored: unknown, name: AllowanceName): number {
  const parsed = z
    .object({ [ALLOWANCE_ATTEMPTS]: z.record(z.string(), z.unknown()).catch({}) })
    .safeParse(stored ?? {});
  const value = parsed.success ? parsed.data[ALLOWANCE_ATTEMPTS][name] : undefined;
  return typeof value === 'number' && Number.isInteger(value) && value > 0 ? value : 0;
}

/**
 * The calls an allowance may start in a month, refused and failed ones
 * included. It is the allowance's own: a child sending photo after photo that
 * is refused closes creations for the month and never the household's other AI.
 */
export function allowanceAttemptCeiling(tier: AiTier, allowance: Allowance): number {
  const creations = tier === 'premium' ? allowance.premiumMonthly : allowance.freeLifetime;
  return creations * CALLS_PER_CREATION * ATTEMPT_HEADROOM;
}

export function allowanceAttemptsLeft(
  tier: AiTier,
  used: AllowanceUsage,
  allowance: Allowance,
): number {
  return Math.max(0, allowanceAttemptCeiling(tier, allowance) - used.attempts);
}

/** What a tier may still make: premium by the month, free once in the household's life. */
export function allowanceLeft(tier: AiTier, used: AllowanceUsage, allowance: Allowance): number {
  return tier === 'premium'
    ? Math.max(0, allowance.premiumMonthly - used.month)
    : Math.max(0, allowance.freeLifetime - used.lifetime);
}

/**
 * Whether one more call of [charge] fits. A call against an allowance, or one
 * of its checks charged to nothing, never touches the monthly call cap or its
 * attempts: it is bounded by the allowance's own attempt ceiling.
 */
export function decideCharge(
  charge: AiCharge,
  usage: MonthUsage,
  cap: number,
  tier: AiTier,
  used: AllowanceUsage,
): ClaimDecision {
  if (charge.kind === 'calls') return decideClaim(usage, cap);
  if (allowanceAttemptsLeft(tier, used, charge.allowance) <= 0) return { allowed: false };
  if (charge.kind === 'none') {
    return { allowed: true, callsAfter: usage.calls, callsLeft: Math.max(0, cap - usage.calls) };
  }
  const left = allowanceLeft(tier, used, charge.allowance);
  if (left <= 0) return { allowed: false };
  return { allowed: true, callsAfter: usage.calls, callsLeft: left - 1 };
}
