import { randomInt } from 'node:crypto';

import { type Firestore, Timestamp, type Transaction } from 'firebase-admin/firestore';

import { householdRef } from '../household/documents';
import { generateReadableCode } from '../shared/readable_code';
import { refuseReferral } from './errors';
import {
  householdMembers,
  householdReferralRef,
  referralCodeRef,
  referralRef,
} from './referral_documents';
import { REFERRAL_CODE_LENGTH, YEARLY_REWARD_CAP, redeemByOf } from './referral_policy';

/**
 * The household's own referral code, made the first time a parent asks
 * (subscriptions ADR-0002). A household keeps its code for ever: asking again
 * answers the same one, so a code already shared never stops working.
 */
export interface ReferralCodeRequest {
  readonly householdId: string;
  readonly random?: (max: number) => number;
}

/** How many fresh codes to try before giving up — a collision in 31^8 is already rare. */
const ATTEMPTS = 5;

export async function ensureReferralCode(
  store: Firestore,
  request: ReferralCodeRequest,
  now: Date,
): Promise<string> {
  const random = request.random ?? randomInt;
  return store.runTransaction(async (transaction) => {
    const ownRef = householdReferralRef(store, request.householdId);
    const [own, household, ledger] = await Promise.all([
      transaction.get(ownRef),
      transaction.get(householdRef(store, request.householdId)),
      transaction.get(referralRef(store, request.householdId)),
    ]);
    const existing: unknown = own.get('code');
    if (typeof existing === 'string' && existing.length > 0) return existing;
    if (!household.exists) throw refuseReferral('householdNotFound');

    const code = await freeCode(transaction, store, random);
    const createdAt = householdMembers.safeParse(household.data()).data?.createdAt ?? null;
    const redeemBy = redeemByOf(createdAt);
    transaction.create(referralCodeRef(store, code), {
      householdId: request.householdId,
      createdAt: Timestamp.fromDate(now),
    });
    transaction.set(
      ownRef,
      {
        code,
        redeemBy: redeemBy === null ? null : Timestamp.fromDate(redeemBy),
        // A household that redeemed before it ever opened its own screen.
        hasRedeemed: ledger.exists,
        // Said by the server, so the screen never keeps its own copy of the rule.
        yearlyRewardCap: YEARLY_REWARD_CAP,
        createdAt: Timestamp.fromDate(now),
      },
      { merge: true },
    );
    return code;
  });
}

async function freeCode(
  transaction: Transaction,
  store: Firestore,
  random: (max: number) => number,
): Promise<string> {
  for (let attempt = 0; attempt < ATTEMPTS; attempt += 1) {
    const code = generateReadableCode(REFERRAL_CODE_LENGTH, random);
    if (!(await transaction.get(referralCodeRef(store, code))).exists) return code;
  }
  throw new Error('no free referral code after several attempts');
}
