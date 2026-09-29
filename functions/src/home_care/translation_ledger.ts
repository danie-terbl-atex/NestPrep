import type { Firestore } from 'firebase-admin/firestore';

import { householdHasPremium } from '../subscriptions/subscription_documents';
import { refuseHomeCare } from './errors';
import { usageRef } from './home_care_refs';
import { monthKey, monthlyAllowance, refunded, spendWithin } from './translation_cap';

/**
 * Claims this month's characters **before** Google is asked (home-care
 * ADR-0006, BE-06): the entitlement and the count are read in one
 * transaction with the write that raises it, so two phones asking at once
 * cannot both slip under the cap. Refuses when the spend would pass it.
 */
export async function claimCharacters(
  store: Firestore,
  householdId: string,
  characters: number,
  now: Date,
): Promise<string> {
  const month = monthKey(now);
  await store.runTransaction(async (transaction) => {
    const isPremium = await householdHasPremium(transaction, store, householdId, now);
    const usage = await transaction.get(usageRef(store, householdId, month));
    const after = spendWithin(usage.get('characters'), characters, monthlyAllowance(isPremium));
    if (after === null) throw refuseHomeCare('translationLimitReached');
    transaction.set(usageRef(store, householdId, month), { characters: after }, { merge: true });
  });
  return month;
}

/** Gives a failed call's characters back, so a Google outage costs nothing. */
export async function refundCharacters(
  store: Firestore,
  householdId: string,
  month: string,
  characters: number,
): Promise<void> {
  await store.runTransaction(async (transaction) => {
    const usage = await transaction.get(usageRef(store, householdId, month));
    transaction.set(
      usageRef(store, householdId, month),
      { characters: refunded(usage.get('characters'), characters) },
      { merge: true },
    );
  });
}
