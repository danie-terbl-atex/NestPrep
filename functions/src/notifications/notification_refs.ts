import type { CollectionReference, DocumentReference, Firestore } from 'firebase-admin/firestore';

import { USERS, householdRef } from '../household/documents';

/**
 * Where notifications keeps what it keeps (notifications ADR-0001). The app
 * spells the same names in its repositories, and the rules name them in
 * `rules/firestore/household/notifications.rules` and
 * `rules/firestore/root/notifications.rules`.
 */

/** `users/{uid}/pushTokens/{token}` — one per phone an account is signed in on. */
export const PUSH_TOKENS = 'pushTokens';

/** `households/{h}/notificationSettings/{memberId}` — one person's choices. */
export const NOTIFICATION_SETTINGS = 'notificationSettings';

/** `households/{h}/notificationInbox/{id}` — every notification, per person. */
export const NOTIFICATION_INBOX = 'notificationInbox';

/** As many phones as one account's pushes go to (BE-08). */
export const TOKENS_PER_ACCOUNT = 10;

export function pushTokensOf(store: Firestore, uid: string): CollectionReference {
  return store.collection(USERS).doc(uid).collection(PUSH_TOKENS);
}

export function settingsRef(
  store: Firestore,
  householdId: string,
  memberId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(NOTIFICATION_SETTINGS).doc(memberId);
}

export function inboxRef(store: Firestore, householdId: string, itemId: string): DocumentReference {
  return householdRef(store, householdId).collection(NOTIFICATION_INBOX).doc(itemId);
}
