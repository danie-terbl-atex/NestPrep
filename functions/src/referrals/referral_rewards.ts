import { type Firestore, Timestamp, type Transaction } from 'firebase-admin/firestore';

import {
  type HouseholdPremium,
  premiumGrantRef,
  readHouseholdPremium,
  stageHouseholdPremium,
  storeEntitlementOf,
} from '../subscriptions/household_premium';
import type { PremiumGrant } from '../subscriptions/premium_composition';
import {
  type ReferralReward,
  type ReferralSide,
  historyEntryId,
  referralGrantId,
} from './referral_documents';
import { REFERRAL_REWARD_DAYS, isUnderYearlyCap } from './referral_policy';

/**
 * Paying out a referral that qualified: a thirty-day grant to each side that
 * is under its yearly cap, and each side's entitlement restated in the same
 * transaction (subscriptions ADR-0002). The grant is a grant — no store
 * purchase is written or pretended — so the plan screen and the reconcile
 * never mistake it for something a store sold.
 */
export interface RewardSide {
  readonly side: ReferralSide;
  readonly householdId: string;
  readonly referredId: string;
  readonly premium: HouseholdPremium;
}

export interface RewardSides {
  /** Null when the household that shared the code no longer exists. */
  readonly referrer: RewardSide | null;
  readonly referred: RewardSide;
}

/** What each side got; null for a referrer that no longer exists. */
export interface ReferralRewards {
  readonly referrer: ReferralReward | null;
  readonly referred: ReferralReward;
}

/** Every read the payout needs, done before any write (a transaction's rule). */
export async function readRewardSides(
  transaction: Transaction,
  store: Firestore,
  households: { referrerId: string | null; referredId: string },
): Promise<RewardSides> {
  const { referrerId, referredId } = households;
  const referred: RewardSide = {
    side: 'referred',
    householdId: referredId,
    referredId,
    premium: await readHouseholdPremium(transaction, store, referredId),
  };
  if (referrerId === null) return { referrer: null, referred };
  return {
    referrer: {
      side: 'referrer',
      householdId: referrerId,
      referredId,
      premium: await readHouseholdPremium(transaction, store, referrerId),
    },
    referred,
  };
}

export function stageRewards(
  transaction: Transaction,
  store: Firestore,
  sides: RewardSides,
  now: Date,
): ReferralRewards {
  return {
    referrer: sides.referrer === null ? null : stageReward(transaction, store, sides.referrer, now),
    referred: stageReward(transaction, store, sides.referred, now),
  };
}

function stageReward(
  transaction: Transaction,
  store: Firestore,
  side: RewardSide,
  now: Date,
): ReferralReward {
  // Every grant is a referral's today (`GRANT_SOURCES`); a second source
  // decides in its own ADR whether it counts against this cap.
  const given = side.premium.grants.map((grant) => grant.grantedAt);
  if (!isUnderYearlyCap(given, now)) return 'capped';

  const grant: PremiumGrant = {
    id: referralGrantId(historyEntryId(side.referredId, side.side)),
    days: REFERRAL_REWARD_DAYS,
    grantedAt: now,
    startsAt: null,
  };
  const restated = stageHouseholdPremium(
    transaction,
    store,
    {
      householdId: side.householdId,
      storeEntitlement: storeEntitlementOf(side.premium.purchases, now),
      premium: side.premium,
      newGrant: grant,
    },
    now,
  );
  const startsAt = restated.started[grant.id];
  transaction.create(premiumGrantRef(store, side.householdId, grant.id), {
    source: 'referral',
    days: grant.days,
    grantedAt: Timestamp.fromDate(now),
    startsAt: startsAt === undefined ? null : Timestamp.fromDate(startsAt),
  });
  return 'month';
}
