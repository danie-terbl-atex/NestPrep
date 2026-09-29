import { z } from 'zod';

import { REFERRAL_REWARDS } from '../referrals/referral_documents';

/**
 * A week's referrals as counts (product-analytics ADR-0002, subscriptions
 * ADR-0002): how many new households entered a code, how many referrals
 * became a real family, and how many free months that gave. Read from the
 * referral ledger by its week keys; nothing about either household reaches
 * the totals.
 */
export interface ReferralCounts {
  readonly redeemed: number;
  readonly qualified: number;
  readonly monthsGiven: number;
}

export const NO_REFERRALS: ReferralCounts = { redeemed: 0, qualified: 0, monthsGiven: 0 };

/** A referral as the rollup reads it: only what it was worth, never who. */
export const countedReferral = z.object({
  referrerReward: z.enum(REFERRAL_REWARDS).nullable().default(null),
  referredReward: z.enum(REFERRAL_REWARDS).nullable().default(null),
});
export type CountedReferral = z.infer<typeof countedReferral>;

export function countReferrals(
  redeemed: readonly CountedReferral[],
  qualified: readonly CountedReferral[],
): ReferralCounts {
  const months = (referral: CountedReferral): number =>
    (referral.referrerReward === 'month' ? 1 : 0) + (referral.referredReward === 'month' ? 1 : 0);
  return {
    redeemed: redeemed.length,
    qualified: qualified.length,
    monthsGiven: qualified.reduce((total, referral) => total + months(referral), 0),
  };
}
