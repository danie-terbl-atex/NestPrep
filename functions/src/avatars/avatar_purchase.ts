import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { type LedgerBalance, readBalance, stageLine } from '../chore_points/point_ledger';
import { parseSnapshot } from '../chore_points/point_documents';
import { householdRef, memberRef } from '../household/documents';
import { householdHasPremium } from '../subscriptions/subscription_documents';
import type { ACCESSORIES } from './avatar_catalogue';
import { type AvatarOwned, accessoryOf, parseOwned } from './avatar_look';
import { avatarPurchaseRef, memberAvatarRef } from './avatar_refs';

/**
 * A child buys an accessory with their stars (avatars ADR-0004): the price
 * from the server's catalogue, the stars taken and the accessory owned in one
 * transaction, with no parent step. A retry finds the status and writes nothing.
 */

export type PurchaseRefusal =
  | 'notEnoughStars'
  | 'alreadyOwned'
  | 'unknownAccessory'
  | 'shopOff'
  | 'notAKid'
  | 'premiumRequired';

export type PurchaseOutcome = 'owned' | 'alreadySettled' | 'gone' | PurchaseRefusal;

const storedPurchase = z.object({
  memberId: z.string(),
  accessoryId: z.string(),
  requestedBy: z.string(),
  status: z.string().optional(),
});

/** Pure: whether [accessory] can be bought with [balance]. A free one is everybody's already. */
export function decidePurchase(facts: {
  readonly accessory: (typeof ACCESSORIES)[number] | undefined;
  readonly hasPremium: boolean;
  readonly shopOn: boolean;
  readonly memberRole: unknown;
  readonly owned: AvatarOwned;
  readonly balance: number;
}): PurchaseRefusal | 'buy' {
  const { accessory } = facts;
  if (accessory === undefined) return 'unknownAccessory';
  if (!facts.hasPremium) return 'premiumRequired';
  if (!facts.shopOn) return 'shopOff';
  if (facts.memberRole !== 'kid') return 'notAKid';
  if (accessory.stars === 0 || facts.owned.accessories.includes(accessory.id)) {
    return 'alreadyOwned';
  }
  if (facts.balance < accessory.stars) return 'notEnoughStars';
  return 'buy';
}

export async function settleAvatarPurchase(
  store: Firestore,
  householdId: string,
  purchaseId: string,
  now: Date = new Date(),
): Promise<PurchaseOutcome> {
  return store.runTransaction(async (transaction) => {
    const ref = avatarPurchaseRef(store, householdId, purchaseId);
    const purchase = parseSnapshot(await transaction.get(ref), storedPurchase);
    if (purchase === undefined) return 'gone';
    if (purchase.status !== undefined) return 'alreadySettled';
    const household = await transaction.get(householdRef(store, householdId));
    if (!household.exists) return 'gone';

    const { memberId } = purchase;
    const member = await transaction.get(memberRef(store, householdId, memberId));
    const avatar = await transaction.get(memberAvatarRef(store, householdId, memberId));
    const balance: LedgerBalance = await readBalance(transaction, store, householdId, memberId);
    const accessory = accessoryOf(purchase.accessoryId);
    const decision = decidePurchase({
      accessory,
      hasPremium: await householdHasPremium(transaction, store, householdId, now),
      shopOn: household.get('avatarShop') !== false,
      memberRole: member.get('role'),
      owned: parseOwned(avatar.get('owned')),
      balance: balance.balance,
    });

    const settledAt = FieldValue.serverTimestamp();
    if (decision !== 'buy' || accessory === undefined) {
      const reason = decision === 'buy' ? 'unknownAccessory' : decision;
      transaction.update(ref, { status: 'refused', reason, settledAt });
      return reason;
    }

    stageLine(transaction, store, householdId, balance, {
      entryId: `accessory_${purchaseId}`,
      memberId,
      delta: -accessory.stars,
      kind: 'accessory',
      sourceId: purchaseId,
      title: accessory.label,
    });
    transaction.set(
      memberAvatarRef(store, householdId, memberId),
      { owned: { accessories: FieldValue.arrayUnion(accessory.id) } },
      { merge: true },
    );
    transaction.update(ref, { status: 'owned', settledAt });
    return 'owned';
  });
}
