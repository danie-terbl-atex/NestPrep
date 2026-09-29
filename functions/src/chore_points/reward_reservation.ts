import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { householdRef, memberRef } from '../household/documents';
import { isFamilyRole } from './chore_eligibility';
import { readBalance, stageLine } from './point_ledger';
import { requestRef, rewardRef } from './point_refs';
import {
  parseSnapshot,
  storedRequest,
  storedReward,
  type StoredBalance,
  type StoredReward,
} from './point_documents';

/**
 * A child asked for a reward: the stars come off now, or the request is
 * refused (todos ADR-0003).
 *
 * Taking the stars at the moment of asking — not when a parent hands the
 * reward over — is what stops two requests spending the same stars: the second
 * one reads the balance the first one left. A parent who declines gives them
 * back (`settleReward`).
 */

export type Refusal = 'notEnoughPoints' | 'rewardGone' | 'notAKid';

export type ReservationOutcome = 'waiting' | 'fulfilled' | 'alreadySettled' | 'gone' | Refusal;

/** Pure: whether a request can be met from a balance. */
export function decideReservation(facts: {
  readonly reward: StoredReward | undefined;
  readonly memberRole: string | undefined;
  readonly balance: StoredBalance;
}): Refusal | 'reserve' {
  if (facts.reward === undefined) return 'rewardGone';
  if (facts.memberRole !== 'kid') return 'notAKid';
  if (facts.balance.balance < facts.reward.cost) return 'notEnoughPoints';
  return 'reserve';
}

export async function reserveReward(
  store: Firestore,
  householdId: string,
  requestId: string,
): Promise<ReservationOutcome> {
  return store.runTransaction(async (transaction) => {
    const ref = requestRef(store, householdId, requestId);
    const request = parseSnapshot(await transaction.get(ref), storedRequest);
    if (request === undefined) return 'gone';
    // A status is only ever written here or by a parent: this delivery is a
    // repeat of one that already ran.
    if (request.status !== undefined) return 'alreadySettled';
    if (!(await transaction.get(householdRef(store, householdId))).exists) return 'gone';

    const reward = parseSnapshot(
      await transaction.get(rewardRef(store, householdId, request.rewardId)),
      storedReward,
    );
    const roleOf = async (memberId: string): Promise<string | undefined> => {
      const role: unknown = (await transaction.get(memberRef(store, householdId, memberId))).get(
        'role',
      );
      return typeof role === 'string' ? role : undefined;
    };
    const memberRole = await roleOf(request.memberId);
    const byFamily = isFamilyRole(await roleOf(request.requestedBy));
    const balance = await readBalance(transaction, store, householdId, request.memberId);

    const decision = decideReservation({ reward, memberRole, balance });
    const snapshotOfReward = {
      title: reward?.title ?? '',
      cost: reward?.cost ?? 0,
      icon: reward?.icon ?? 'gift',
    };
    if (decision !== 'reserve' || reward === undefined) {
      const refusal = decision === 'reserve' ? 'rewardGone' : decision;
      transaction.update(ref, {
        ...snapshotOfReward,
        status: 'refused',
        refusal,
        settledAt: FieldValue.serverTimestamp(),
        settledBy: null,
      });
      return refusal;
    }

    stageLine(transaction, store, householdId, balance, {
      entryId: `reward_${requestId}`,
      memberId: request.memberId,
      delta: -reward.cost,
      kind: 'reward',
      sourceId: requestId,
      title: reward.title,
    });
    // A parent asking on a child's behalf is handing it over there and then.
    const status = byFamily ? 'fulfilled' : 'waiting';
    transaction.update(ref, {
      ...snapshotOfReward,
      status,
      refusal: null,
      settledAt: byFamily ? FieldValue.serverTimestamp() : null,
      settledBy: byFamily ? request.requestedBy : null,
    });
    return status;
  });
}
