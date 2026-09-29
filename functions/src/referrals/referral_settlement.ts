import { FieldValue, type Firestore, Timestamp, type Transaction } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { householdRef } from '../household/documents';
import { countingZoneFor, weekKeyOf } from '../product_analytics/iso_week';
import { readFlag } from '../shared/feature_flags';
import {
  type HouseholdMembers,
  type QualifiedBy,
  type StoredReferral,
  historyEntryId,
  historyRef,
  householdMembers,
  referralRef,
  storedReferral,
} from './referral_documents';
import { ADULTS_FOR_A_FAMILY, countsAsNewAdult, newAdultsSeen } from './referral_policy';
import { type ReferralRewards, readRewardSides, stageRewards } from './referral_rewards';

/**
 * Whether a pending referral has become a real family, and paying both sides
 * when it has (subscriptions ADR-0002). Asked when somebody opens the app in
 * the new household and when a purchase is verified for it; nothing polls.
 *
 * Idempotent: a referral already qualified or expired is left alone, and one
 * that is paid is paid in the same transaction that marks it, so a retry can
 * never pay twice.
 */
export type QualifyingEvent =
  { readonly kind: 'opened'; readonly uid: string } | { readonly kind: 'purchased' };

export type SettleOutcome = 'none' | 'pending' | 'qualified' | 'expired';

export async function settleReferral(
  store: Firestore,
  householdId: string,
  event: QualifyingEvent,
  now: Date,
): Promise<SettleOutcome> {
  // One read for every household that never redeemed — almost all of them.
  const glance = await referralRef(store, householdId).get();
  if (!glance.exists || glance.get('status') !== 'pending') return 'none';
  const isOn = await readFlag(store, 'referralRewards');
  return store.runTransaction((transaction) =>
    settleIn(transaction, store, { householdId, event, now, isOn }),
  );
}

/**
 * [settleReferral] for callers whose own work must not fail because of it —
 * opening the app, verifying a purchase. A failure is logged and left for the
 * next time somebody opens the app, which asks again (`BE-09`).
 */
export async function settleReferralAfter(
  store: Firestore,
  householdId: string,
  event: QualifyingEvent,
  now: Date,
): Promise<SettleOutcome | 'failed'> {
  try {
    return await settleReferral(store, householdId, event, now);
  } catch (error) {
    logger.error('referral not settled; asked again on the next open', {
      householdId,
      event: event.kind,
      error: error instanceof Error ? error.message : String(error),
    });
    return 'failed';
  }
}

interface Settlement {
  readonly householdId: string;
  readonly event: QualifyingEvent;
  readonly now: Date;
  readonly isOn: boolean;
}

async function settleIn(
  transaction: Transaction,
  store: Firestore,
  settlement: Settlement,
): Promise<SettleOutcome> {
  const { householdId, event, now, isOn } = settlement;
  const ref = referralRef(store, householdId);
  const parsed = storedReferral.safeParse((await transaction.get(ref)).data());
  if (!parsed.success) return 'none';
  const referral = parsed.data;
  if (referral.status !== 'pending') return referral.status;
  if (now.getTime() > referral.qualifyBy.getTime()) {
    stageExpiry(transaction, store, referral);
    return 'expired';
  }

  const referred = await readMembers(transaction, store, householdId);
  const referrer = await readMembers(transaction, store, referral.referrerHouseholdId);
  const referredRoles = referred?.members ?? {};
  const referrerRoles = referrer?.members ?? {};
  const seen =
    event.kind === 'opened' && countsAsNewAdult(event.uid, referredRoles, referrerRoles)
      ? event.uid
      : null;
  const adults = newAdultsSeen(
    seen === null ? referral.activeUids : [...referral.activeUids, seen],
    referredRoles,
    referrerRoles,
  );
  const qualifiedBy: QualifiedBy | null =
    event.kind === 'purchased'
      ? 'premiumPurchase'
      : adults.length >= ADULTS_FOR_A_FAMILY
        ? 'twoAdults'
        : null;

  if (qualifiedBy === null || !isOn || referred === null) {
    if (seen !== null && !referral.activeUids.includes(seen)) {
      transaction.update(ref, { activeUids: FieldValue.arrayUnion(seen) });
    }
    return 'pending';
  }

  const sides = await readRewardSides(transaction, store, {
    referrerId: referrer === null ? null : referral.referrerHouseholdId,
    referredId: householdId,
  });
  const rewards = stageRewards(transaction, store, sides, now);
  stageQualified(transaction, store, {
    referral,
    qualifiedBy,
    rewards,
    activeUids: adults,
    week: weekKeyOf(now, countingZoneFor(referred.timeZone)),
    now,
  });
  return 'qualified';
}

async function readMembers(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
): Promise<HouseholdMembers | null> {
  const snapshot = await transaction.get(householdRef(store, householdId));
  if (!snapshot.exists) return null;
  const parsed = householdMembers.safeParse(snapshot.data());
  return parsed.success ? parsed.data : null;
}

interface Qualification {
  readonly referral: StoredReferral;
  readonly qualifiedBy: QualifiedBy;
  readonly rewards: ReferralRewards;
  readonly activeUids: readonly string[];
  readonly week: string;
  readonly now: Date;
}

function stageQualified(
  transaction: Transaction,
  store: Firestore,
  qualification: Qualification,
): void {
  const { referral, qualifiedBy, rewards, activeUids, week, now } = qualification;
  const at = Timestamp.fromDate(now);
  transaction.update(referralRef(store, referral.referredHouseholdId), {
    status: 'qualified',
    qualifiedAt: at,
    qualifiedWeek: week,
    qualifiedBy,
    activeUids: [...activeUids],
    referrerReward: rewards.referrer,
    referredReward: rewards.referred,
  });
  const referredId = referral.referredHouseholdId;
  if (rewards.referrer !== null) {
    transaction.set(
      historyRef(store, referral.referrerHouseholdId, historyEntryId(referredId, 'referrer')),
      { status: 'qualified', qualifiedAt: at, reward: rewards.referrer },
      { merge: true },
    );
  }
  transaction.set(
    historyRef(store, referredId, historyEntryId(referredId, 'referred')),
    { status: 'qualified', qualifiedAt: at, reward: rewards.referred },
    { merge: true },
  );
}

function stageExpiry(transaction: Transaction, store: Firestore, referral: StoredReferral): void {
  const referredId = referral.referredHouseholdId;
  transaction.update(referralRef(store, referredId), { status: 'expired' });
  for (const [householdId, side] of [
    [referral.referrerHouseholdId, 'referrer'],
    [referredId, 'referred'],
  ] as const) {
    transaction.set(
      historyRef(store, householdId, historyEntryId(referredId, side)),
      { status: 'expired' },
      { merge: true },
    );
  }
}
