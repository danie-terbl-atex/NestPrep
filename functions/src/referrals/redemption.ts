import { type Firestore, Timestamp, type Transaction } from 'firebase-admin/firestore';

import { householdRef } from '../household/documents';
import { countingZoneFor, weekKeyOf } from '../product_analytics/iso_week';
import { refuseReferral } from './errors';
import {
  type HouseholdMembers,
  historyEntryId,
  historyRef,
  householdMembers,
  householdReferralRef,
  referralCodeRef,
  referralRef,
} from './referral_documents';
import {
  REDEMPTIONS_PER_DAY,
  mayStillRedeem,
  qualifyByOf,
  redeemedWithinADay,
  sharesAMember,
} from './referral_policy';

/**
 * A new household entering another household's code (subscriptions
 * ADR-0002). Every check and every write in one transaction, so two phones
 * redeeming at once cannot both get in, and a refusal leaves nothing behind
 * (`BE-06`, `BE-07`). Nothing is given here: the referral waits until the new
 * household is a real family.
 */
export interface Redemption {
  readonly householdId: string;
  readonly uid: string;
  readonly code: string;
}

export interface RedemptionResult {
  readonly qualifyBy: Date;
}

export async function redeemReferral(
  store: Firestore,
  redemption: Redemption,
  now: Date,
): Promise<RedemptionResult> {
  return store.runTransaction(async (transaction) => {
    const { householdId, uid, code } = redemption;
    const referred = await readMembers(transaction, store, householdId);
    if (referred === null) throw refuseReferral('householdNotFound');
    if ((await transaction.get(referralRef(store, householdId))).exists) {
      throw refuseReferral('alreadyRedeemed');
    }
    if (!mayStillRedeem(referred.createdAt ?? null, now)) throw refuseReferral('tooLateToRedeem');

    const { referrerId, recent } = await readCode(transaction, store, code, now);
    if (referrerId === householdId) throw refuseReferral('ownReferralCode');
    const referrer = await readMembers(transaction, store, referrerId);
    if (referrer === null) throw refuseReferral('referralCodeNotFound');
    if (referrer.members[uid] !== undefined || sharesAMember(referred.members, referrer.members)) {
      throw refuseReferral('ownReferralCode');
    }
    // The rate limit: a code shared into a crowd is paused for the day.
    if (recent.length >= REDEMPTIONS_PER_DAY) throw refuseReferral('tooManyRedemptions');

    const qualifyBy = qualifyByOf(now);
    stageRedemption(transaction, store, {
      code,
      recent,
      referrerId,
      householdId,
      uid,
      qualifyBy,
      week: weekKeyOf(now, countingZoneFor(referred.timeZone)),
      now,
    });
    return { qualifyBy };
  });
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

/**
 * Whose code this is, and when it was redeemed in the last day — kept on the
 * code itself, so the limit needs no query and no index.
 */
async function readCode(
  transaction: Transaction,
  store: Firestore,
  code: string,
  now: Date,
): Promise<{ referrerId: string; recent: Date[] }> {
  const snapshot = await transaction.get(referralCodeRef(store, code));
  const owner: unknown = snapshot.get('householdId');
  if (!snapshot.exists || typeof owner !== 'string') throw refuseReferral('referralCodeNotFound');
  const stored: unknown = snapshot.get('recentRedemptions');
  const times = Array.isArray(stored)
    ? stored.flatMap((value: unknown) => (value instanceof Timestamp ? [value.toDate()] : []))
    : [];
  return { referrerId: owner, recent: redeemedWithinADay(times, now) };
}

interface StagedRedemption {
  readonly code: string;
  readonly recent: readonly Date[];
  readonly referrerId: string;
  readonly householdId: string;
  readonly uid: string;
  readonly qualifyBy: Date;
  readonly week: string;
  readonly now: Date;
}

function stageRedemption(
  transaction: Transaction,
  store: Firestore,
  staged: StagedRedemption,
): void {
  const { code, recent, referrerId, householdId, uid, qualifyBy, week, now } = staged;
  transaction.update(referralCodeRef(store, code), {
    recentRedemptions: [...recent, now].map((at) => Timestamp.fromDate(at)),
  });
  transaction.create(referralRef(store, householdId), {
    referrerHouseholdId: referrerId,
    referredHouseholdId: householdId,
    redeemedAt: Timestamp.fromDate(now),
    redeemedWeek: week,
    qualifyBy: Timestamp.fromDate(qualifyBy),
    status: 'pending',
    // The parent who typed the code has just used the household.
    activeUids: [uid],
    qualifiedAt: null,
    qualifiedWeek: null,
    qualifiedBy: null,
    referrerReward: null,
    referredReward: null,
  });
  const line = {
    status: 'pending',
    redeemedAt: Timestamp.fromDate(now),
    qualifyBy: Timestamp.fromDate(qualifyBy),
    qualifiedAt: null,
    reward: null,
  };
  transaction.set(historyRef(store, referrerId, historyEntryId(householdId, 'referrer')), {
    ...line,
    side: 'referrer',
  });
  transaction.set(historyRef(store, householdId, historyEntryId(householdId, 'referred')), {
    ...line,
    side: 'referred',
  });
  transaction.set(householdReferralRef(store, householdId), { hasRedeemed: true }, { merge: true });
}
