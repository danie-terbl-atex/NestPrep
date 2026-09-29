import type { CollectionReference, DocumentReference, Firestore } from 'firebase-admin/firestore';

import { HOUSEHOLDS, MEMBERS, householdRef } from '../household/documents';

/**
 * Where a household's personal vaults live (documents ADR-0002). A vault is a
 * path, not a field: the owner is the `{memberId}` segment, so every rule and
 * every read here takes it from the address rather than from a stored value.
 *
 * `vaultDocuments` is deliberately not `documents`, so a collection-group read
 * over the household's shared documents can never pick up a passport.
 */
export const VAULTS = 'vaults';
export const VAULT_DOCUMENTS = 'vaultDocuments';
export const GRANTS = 'grants';
export const VIEWS = 'views';
export const VAULT_OPENINGS = 'vaultOpenings';

export function vaultRef(
  store: Firestore,
  householdId: string,
  ownerMemberId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(VAULTS).doc(ownerMemberId);
}

export function vaultDocumentRef(
  store: Firestore,
  householdId: string,
  ownerMemberId: string,
  documentId: string,
): DocumentReference {
  return vaultRef(store, householdId, ownerMemberId).collection(VAULT_DOCUMENTS).doc(documentId);
}

/** A grant is keyed by the grantee's uid, because that is what a rule knows. */
export function grantRef(
  store: Firestore,
  householdId: string,
  ownerMemberId: string,
  granteeUid: string,
): DocumentReference {
  return vaultRef(store, householdId, ownerMemberId).collection(GRANTS).doc(granteeUid);
}

export function viewsOf(
  store: Firestore,
  householdId: string,
  ownerMemberId: string,
): CollectionReference {
  return vaultRef(store, householdId, ownerMemberId).collection(VIEWS);
}

/**
 * The id `storage.rules` reads a ticket at: the caller's uid and the document,
 * joined. One ticket per person per document, so opening it again refreshes it
 * rather than piling up another (documents ADR-0003).
 */
export function openingId(uid: string, documentId: string): string {
  return `${uid}_${documentId}`;
}

export function openingRef(
  store: Firestore,
  householdId: string,
  uid: string,
  documentId: string,
): DocumentReference {
  return householdRef(store, householdId)
    .collection(VAULT_OPENINGS)
    .doc(openingId(uid, documentId));
}

/**
 * The profile this account claimed in the household, if any. Bounded to one:
 * a profile is claimed by at most one account (household ADR-0001).
 */
export async function claimedMemberId(
  store: Firestore,
  householdId: string,
  uid: string,
): Promise<string | undefined> {
  const found = await store
    .collection(HOUSEHOLDS)
    .doc(householdId)
    .collection(MEMBERS)
    .where('claimedBy', '==', uid)
    .limit(1)
    .get();
  return found.docs[0]?.id;
}
