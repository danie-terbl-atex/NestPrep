import type { Firestore, Query } from 'firebase-admin/firestore';

import { householdRef } from '../../household/documents';
import { ASSISTANT_CODES, ASSISTANT_TOKENS } from '../auth/auth_documents';
import { ASSISTANT_ACTIVITY, ASSISTANT_CONNECTIONS, connectionRef } from './connection_documents';

/** Rows removed per page. */
const PAGE = 400;

/**
 * Disconnects assistants on the server's side (assistants ADR-0003): each
 * grant document goes first, which already makes every token it issued
 * worthless, then its tokens and the code it was redeemed from, page by page.
 * A code not yet redeemed names no grant, so it is not found here; it cannot
 * become one for somebody who is no longer family, because redeeming reads
 * the household again. Safe to run again, and a grant already gone is simply
 * finished.
 */
export async function deleteGrants(
  store: Firestore,
  householdId: string,
  grantIds: readonly string[],
): Promise<void> {
  for (const grantId of grantIds) {
    const batch = store.batch();
    batch.delete(connectionRef(store, householdId, grantId));
    await batch.commit();
    for (const collection of [ASSISTANT_TOKENS, ASSISTANT_CODES]) {
      await deleteEvery(store.collection(collection).where('grantId', '==', grantId));
    }
  }
}

/** Every grant one account holds in one household. Returns how many there were. */
export async function deleteGrantsOf(
  store: Firestore,
  householdId: string,
  uid: string,
): Promise<number> {
  const held = await householdRef(store, householdId)
    .collection(ASSISTANT_CONNECTIONS)
    .where('uid', '==', uid)
    .limit(PAGE)
    .get();
  await deleteGrants(
    store,
    householdId,
    held.docs.map((doc) => doc.id),
  );
  return held.size;
}

/**
 * The tokens and codes of every grant in a household that is ending; the
 * grants, the activity and the switch go with the household's own
 * recursive delete.
 */
export async function deleteHouseholdCredentials(
  store: Firestore,
  householdId: string,
): Promise<void> {
  for (const collection of [ASSISTANT_TOKENS, ASSISTANT_CODES]) {
    await deleteEvery(store.collection(collection).where('householdId', '==', householdId));
  }
}

/**
 * What assistants did as one member of a household that goes on without
 * them, erased with the rest of their own data (assistants ADR-0005, POPIA).
 */
export async function deleteActivityOf(
  store: Firestore,
  householdId: string,
  memberId: string,
): Promise<void> {
  await deleteEvery(
    householdRef(store, householdId)
      .collection(ASSISTANT_ACTIVITY)
      .where('memberId', '==', memberId),
  );
}

async function deleteEvery(query: Query): Promise<void> {
  for (;;) {
    const page = await query.limit(PAGE).get();
    if (page.empty) return;
    const batch = query.firestore.batch();
    for (const doc of page.docs) batch.delete(doc.ref);
    await batch.commit();
    if (page.size < PAGE) return;
  }
}
