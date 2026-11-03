import type { Firestore } from 'firebase-admin/firestore';

import { MEMBER_LOCATIONS } from '../account_data/personal_refs';
import { householdRef } from '../household/documents';
import { NOTIFICATION_INBOX } from '../notifications/notification_refs';
import { trailRef } from './location_refs';

const PAGE = 400;

/**
 * Everything location knows about one member in one household goes when they
 * leave, are removed or are erased (live-location ADR-0009): their pin, their
 * thirty days, and the arrivals that named them in other people's inboxes.
 */
export async function forgetWhereTheyWere(
  store: Firestore,
  householdId: string,
  memberId: string,
): Promise<void> {
  const home = householdRef(store, householdId);
  {
    const batch = store.batch();
    batch.delete(home.collection(MEMBER_LOCATIONS).doc(memberId));
    await batch.commit();
  }
  await store.recursiveDelete(trailRef(store, householdId, memberId));
  const naming = home
    .collection(NOTIFICATION_INBOX)
    .where('source.kind', '==', 'placeEvent')
    .where('target.id', '==', memberId)
    .limit(PAGE);
  for (;;) {
    const page = await naming.get();
    if (page.empty) return;
    const batch = store.batch();
    for (const item of page.docs) batch.delete(item.ref);
    await batch.commit();
    if (page.size < PAGE) return;
  }
}
