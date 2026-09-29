import type { DocumentReference, Firestore, Query } from 'firebase-admin/firestore';
import { defineString } from 'firebase-functions/params';

import { householdRef } from '../../household/documents';
import { functionUrlFrom } from '../../shared/function_url';
import { vaultDocumentRef } from '../vault_refs';
import type { ShareScope } from './share_policy';

/**
 * Where shared links live (documents ADR-0006).
 *
 * - `households/{h}/documentShares/{shareId}` — what the family sees of a
 *   link; only these Functions write it.
 * - `documentShareTokens/{sha256(token)}` — the link's secrets; nobody but
 *   these Functions reads or writes it.
 */
export const DOCUMENT_SHARES = 'documentShares';
export const DOCUMENT_SHARE_TOKENS = 'documentShareTokens';
export const DOCUMENTS = 'documents';

/** The HTTPS function a link points at. Its name is part of every link sent. */
export const SHARE_FUNCTION_NAME = 'documentShare';

/**
 * Optional; where links are served from, for a custom domain. Empty derives
 * the default `cloudfunctions.net` address (`BE-16`).
 */
export const shareBaseUrl = defineString('DOCUMENT_SHARE_BASE_URL', { default: '' });

export function shareUrlFor(token: string): string {
  const base = shareBaseUrl.value().trim();
  return `${functionUrlFrom(base === '' ? null : base, SHARE_FUNCTION_NAME)}?t=${token}`;
}

export function shareRef(
  store: Firestore,
  householdId: string,
  shareId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(DOCUMENT_SHARES).doc(shareId);
}

export function newShareRef(store: Firestore, householdId: string): DocumentReference {
  return householdRef(store, householdId).collection(DOCUMENT_SHARES).doc();
}

export function tokenRef(store: Firestore, tokenHash: string): DocumentReference {
  return store.collection(DOCUMENT_SHARE_TOKENS).doc(tokenHash);
}

/** Live links: the household's cap is counted over this (`BE-08`). */
export function liveSharesOf(
  store: Firestore,
  householdId: string,
  now: Date,
  limit: number,
): Query {
  return householdRef(store, householdId)
    .collection(DOCUMENT_SHARES)
    .where('status', '==', 'active')
    .where('expiresAt', '>', now)
    .limit(limit);
}

/** The live links bound to one shift, ended with it. */
export function liveSharesOfShift(
  store: Firestore,
  householdId: string,
  shiftId: string,
  limit: number,
): Query {
  return householdRef(store, householdId)
    .collection(DOCUMENT_SHARES)
    .where('shiftId', '==', shiftId)
    .where('status', '==', 'active')
    .limit(limit);
}

export interface SharedDocumentAddress {
  readonly householdId: string;
  readonly scope: ShareScope;
  readonly ownerMemberId: string | null;
  readonly documentId: string;
}

/** The metadata row of the document a link shares. */
export function sharedDocumentRef(
  store: Firestore,
  address: SharedDocumentAddress,
): DocumentReference {
  if (address.scope === 'vault' && address.ownerMemberId !== null) {
    return vaultDocumentRef(store, address.householdId, address.ownerMemberId, address.documentId);
  }
  return householdRef(store, address.householdId).collection(DOCUMENTS).doc(address.documentId);
}

/**
 * The Storage object of that document — the metadata row's id, under the
 * household or the vault (documents ADR-0001, ADR-0002).
 */
export function sharedObjectPath(address: SharedDocumentAddress): string {
  const household = `households/${address.householdId}`;
  if (address.scope === 'vault' && address.ownerMemberId !== null) {
    return `${household}/vaults/${address.ownerMemberId}/${address.documentId}`;
  }
  return `${household}/documents/${address.documentId}`;
}
