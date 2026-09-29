import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import type { KidAuthAccounts } from '../accounts/kid_auth_accounts';
import { KID_PAIRINGS } from '../accounts/kid_documents';
import { FEED_TOKENS } from '../calendar_sync/sync_documents';
import { pushAccountClaims } from '../household/access_claim';
import { type HouseholdDocument, INVITES, householdRef, userRef } from '../household/documents';
import { STORE_PURCHASES } from '../subscriptions/subscription_documents';
import type { ObjectStore } from '../shared/storage';
import { removeOwnedCalendars } from './leave_erasing';
import { householdObjectPrefix } from './personal_refs';

/** Rows per page when clearing a household's top-level records. */
const PAGE = 400;

export interface HouseholdEnding {
  readonly store: Firestore;
  readonly objects: ObjectStore;
  readonly kidAccounts: KidAuthAccounts;
}

/**
 * Ends a household whose last adult is deleting their account (accounts
 * ADR-0006): everything in it goes — profiles, children's details, documents
 * and vaults with their bytes, plans, lists — and everybody else who was in it
 * loses it cleanly.
 *
 * The order is `BE-07`'s. The other accounts stop listing the household
 * first, so nobody is left pointing at a household that is half gone; then the
 * records that live outside it (invites, pairing codes, feed tokens, calendar
 * credentials, store links); then the household itself and its bytes; and
 * last the kid devices' users and the other accounts' claims, which are
 * cleanup after the household has already stopped trusting anyone. Every step
 * is safe to run again, and a household already gone is simply finished.
 */
export async function endHousehold(
  ending: HouseholdEnding,
  callerUid: string,
  householdId: string,
): Promise<void> {
  const { store, objects, kidAccounts } = ending;
  const snapshot = await householdRef(store, householdId).get();
  const household = snapshot.data() as HouseholdDocument | undefined;
  if (household === undefined) return;

  const others = Object.keys(household.members).filter((uid) => uid !== callerUid);
  const kidDevices = Object.keys(household.kids ?? {});

  await forgetHousehold(store, others, householdId);
  await removeOwnedCalendars(store, householdId, null);
  await deleteWhereHousehold(store, INVITES, householdId);
  await deleteWhereHousehold(store, KID_PAIRINGS, householdId);
  await deleteWhereHousehold(store, FEED_TOKENS, householdId);
  await unlinkPurchases(store, householdId);

  await store.recursiveDelete(householdRef(store, householdId));
  await objects.deletePrefix(householdObjectPrefix(householdId));

  await kidAccounts.close(kidDevices);
  for (const uid of others) await pushAccountClaims(store, uid);
}

/** Takes the household off every other account's list, and off its active slot. */
async function forgetHousehold(
  store: Firestore,
  uids: readonly string[],
  householdId: string,
): Promise<void> {
  if (uids.length === 0) return;
  const accounts = await store.getAll(...uids.map((uid) => userRef(store, uid)));
  const batch = store.batch();
  for (const account of accounts) {
    if (!account.exists) continue;
    const wasActive = account.get('activeHouseholdId') === householdId;
    batch.update(account.ref, {
      householdIds: FieldValue.arrayRemove(householdId),
      ...(wasActive ? { activeHouseholdId: null } : {}),
    });
  }
  await batch.commit();
}

async function deleteWhereHousehold(
  store: Firestore,
  collection: string,
  householdId: string,
): Promise<void> {
  for (;;) {
    const page = await store
      .collection(collection)
      .where('householdId', '==', householdId)
      .limit(PAGE)
      .get();
    if (page.empty) return;
    const batch = store.batch();
    for (const doc of page.docs) batch.delete(doc.ref);
    await batch.commit();
    if (page.size < PAGE) return;
  }
}

/**
 * A store subscription belongs to the store account that pays for it, not to
 * us: it is unlinked rather than deleted, so its owner can restore it onto a
 * household of their own, and it keeps renewing until they cancel it in the
 * store — which the preview tells them (subscriptions ADR-0001).
 */
async function unlinkPurchases(store: Firestore, householdId: string): Promise<void> {
  const linked = await store
    .collection(STORE_PURCHASES)
    .where('householdId', '==', householdId)
    .limit(PAGE)
    .get();
  if (linked.empty) return;
  const batch = store.batch();
  for (const purchase of linked.docs) {
    batch.update(purchase.ref, { householdId: null, linkedByUid: null, linkedByMemberId: null });
  }
  await batch.commit();
}
