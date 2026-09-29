import type { DocumentReference, Firestore } from 'firebase-admin/firestore';

import { householdRef } from '../household/documents';

/**
 * Where co-parenting lives (household ADR-0004).
 *
 * - `coParentInvites/{code}` — a code one home made; closed to every client.
 * - `coParentLinks/{linkId}` — the authority: which two households, which two
 *   kid profiles, and the status. Closed to every client.
 * - `households/{h}/coParentLinks/{linkId}` — each household's mirror, read by
 *   its own members under ordinary household rules, with `handovers/{date}`
 *   and `requests/{id}` under it. Written only here, both at once.
 */
export const COPARENT_INVITES = 'coParentInvites';
export const COPARENT_LINKS = 'coParentLinks';
export const HANDOVERS = 'handovers';
export const REQUESTS = 'requests';

export function coParentInviteRef(store: Firestore, code: string): DocumentReference {
  return store.collection(COPARENT_INVITES).doc(code);
}

export function authorityRef(store: Firestore, linkId: string): DocumentReference {
  return store.collection(COPARENT_LINKS).doc(linkId);
}

export function mirrorRef(
  store: Firestore,
  householdId: string,
  linkId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(COPARENT_LINKS).doc(linkId);
}

export function handoverRef(
  store: Firestore,
  householdId: string,
  linkId: string,
  date: string,
): DocumentReference {
  return mirrorRef(store, householdId, linkId).collection(HANDOVERS).doc(date);
}

export function requestRef(
  store: Firestore,
  householdId: string,
  linkId: string,
  requestId: string,
): DocumentReference {
  return mirrorRef(store, householdId, linkId).collection(REQUESTS).doc(requestId);
}
