import type { DocumentReference, Firestore } from 'firebase-admin/firestore';

import { householdRef } from '../household/documents';

export const MEMBER_AVATARS = 'memberAvatars';
export const AVATAR_PURCHASES = 'avatarPurchases';
export const AVATAR_CREATIONS = 'avatarCreations';
export const AVATAR_KEEPSAKES = 'avatarKeepsakes';
export const AVATAR_KEEPSAKE_DELETES = 'avatarKeepsakeDeletes';

export const AVATAR_PHOTO_MAX_BYTES = 512 * 1024;
export const AVATAR_INBOX_MAX_BYTES = 2 * 1024 * 1024;
export const AVATAR_MADE_MAX_BYTES = 1024 * 1024;

export function memberAvatarRef(
  store: Firestore,
  householdId: string,
  memberId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(MEMBER_AVATARS).doc(memberId);
}

export function avatarPurchaseRef(
  store: Firestore,
  householdId: string,
  purchaseId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(AVATAR_PURCHASES).doc(purchaseId);
}

export function avatarCreationRef(
  store: Firestore,
  householdId: string,
  creationId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(AVATAR_CREATIONS).doc(creationId);
}

export function avatarKeepsakeRef(
  store: Firestore,
  householdId: string,
  keepsakeId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(AVATAR_KEEPSAKES).doc(keepsakeId);
}

export function avatarKeepsakeDeleteRef(
  store: Firestore,
  householdId: string,
  keepsakeId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(AVATAR_KEEPSAKE_DELETES).doc(keepsakeId);
}

/** Every picture of one member: their photos, the inbox and their keepsakes. */
export function avatarObjectPrefix(householdId: string, memberId: string): string {
  return `households/${householdId}/avatars/${memberId}/`;
}

export function avatarImagePath(householdId: string, memberId: string, hash: string): string {
  return `${avatarObjectPrefix(householdId, memberId)}${hash}.jpg`;
}

export function avatarInboxPath(householdId: string, memberId: string, inboxId: string): string {
  return `${avatarObjectPrefix(householdId, memberId)}inbox/${inboxId}.jpg`;
}

export function avatarKeepsakePath(
  householdId: string,
  memberId: string,
  keepsakeId: string,
): string {
  return `${avatarObjectPrefix(householdId, memberId)}keepsakes/${keepsakeId}.jpg`;
}
