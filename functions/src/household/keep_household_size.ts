import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { householdSizeRef } from '../subscriptions/subscription_documents';
import { HOUSEHOLDS, MEMBERS, householdRef } from './documents';

/**
 * Keeps `entitlement/size` at how many people the household holds, which the
 * `members` rules read for the free tier's four (subscriptions ADR-0008).
 * Counted again on every profile made or removed, never incremented, so a
 * missed or repeated event leaves nothing wrong for longer than the next one.
 */
export const keepHouseholdSize = onDocumentWritten(
  { document: `${HOUSEHOLDS}/{householdId}/${MEMBERS}/{memberId}`, retry: true },
  async (event) => {
    if (event.data?.before.exists === event.data?.after.exists) return;
    const { householdId } = event.params;
    const count = await recountHouseholdSize(db(), householdId);
    logger.info('household size counted', { householdId, count });
  },
);

/** Answers the count written, or null for a household that has ended. */
export async function recountHouseholdSize(
  store: Firestore,
  householdId: string,
): Promise<number | null> {
  return store.runTransaction(async (transaction) => {
    const household = await transaction.get(householdRef(store, householdId));
    const size = householdSizeRef(store, householdId);
    // A household being ended deletes its profiles one by one; a count written
    // behind it would be the only document left under a household that is gone.
    if (!household.exists) {
      transaction.delete(size);
      return null;
    }
    const counted = await transaction.get(household.ref.collection(MEMBERS).count());
    const count = counted.data().count;
    transaction.set(size, { count, updatedAt: FieldValue.serverTimestamp() });
    return count;
  });
}
