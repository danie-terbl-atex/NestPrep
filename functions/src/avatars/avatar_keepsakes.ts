import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { householdRef, memberRef } from '../household/documents';
import type { ObjectStore } from '../shared/storage';
import { isAvatarHash, lookOf, parseChoice, parseLook, parseOwned, sanitized } from './avatar_look';
import {
  AVATAR_CREATIONS,
  AVATAR_KEEPSAKES,
  avatarImagePath,
  avatarKeepsakeDeleteRef,
  avatarKeepsakeRef,
  avatarObjectPrefix,
  memberAvatarRef,
} from './avatar_refs';

export const AVATAR_MEMBER_RECORDS = [AVATAR_KEEPSAKES, AVATAR_CREATIONS] as const;

const PAGE = 400;

export type KeepsakeDeleteOutcome = 'gone' | 'deleted';

/**
 * A keepsake deleted from the shelf (avatars ADR-0005), asked for by family
 * or by the member themselves through `avatarKeepsakeDeletes/{keepsakeId}`,
 * which a kid device can write and a callable could not serve. A picture the
 * member wears goes back to the initial before its file goes.
 */
export async function settleKeepsakeDelete(
  store: Firestore,
  objects: ObjectStore,
  householdId: string,
  keepsakeId: string,
): Promise<KeepsakeDeleteOutcome> {
  const requestRef = avatarKeepsakeDeleteRef(store, householdId, keepsakeId);
  const keepsakeRef = avatarKeepsakeRef(store, householdId, keepsakeId);
  const doomed = await store.runTransaction(async (transaction) => {
    const [request, keepsake] = await transaction.getAll(requestRef, keepsakeRef);
    if (request?.exists !== true) return null;
    const memberId: unknown = keepsake?.get('memberId');
    const imageHash: unknown = keepsake?.get('imageHash');
    if (keepsake?.exists !== true || typeof memberId !== 'string' || !isAvatarHash(imageHash)) {
      transaction.delete(requestRef);
      if (keepsake?.exists === true) transaction.delete(keepsakeRef);
      return [];
    }
    const avatarDoc = memberAvatarRef(store, householdId, memberId);
    const memberDoc = memberRef(store, householdId, memberId);
    const [avatar, member] = await transaction.getAll(avatarDoc, memberDoc);
    const twins = await transaction.get(
      householdRef(store, householdId)
        .collection(AVATAR_KEEPSAKES)
        .where('memberId', '==', memberId)
        .where('imageHash', '==', imageHash)
        .limit(2),
    );
    const shared = twins.docs.some((doc) => doc.id !== keepsakeId);

    transaction.delete(keepsakeRef);
    transaction.delete(requestRef);
    const files: string[] = [];
    const original: unknown = keepsake.get('originalPath');
    if (
      typeof original === 'string' &&
      original.startsWith(avatarObjectPrefix(householdId, memberId))
    ) {
      files.push(original);
    }
    if (shared) return files;
    files.push(avatarImagePath(householdId, memberId, imageHash));

    if (avatar?.exists === true) {
      const owned = parseOwned(avatar.get('owned'));
      const ownedAfter = { ...owned, images: owned.images.filter((hash) => hash !== imageHash) };
      const choice = parseChoice(avatar.get('choice'));
      const changes: Record<string, unknown> = {
        'owned.images': FieldValue.arrayRemove(imageHash),
      };
      if (choice?.base === `image:${imageHash}`) {
        const initial = sanitized(
          { ...choice, base: 'initial' },
          ownedAfter,
          member?.get('role') !== 'kid',
        );
        changes['choice'] = initial;
        const look = parseLook(member?.get('look'));
        if (member?.exists === true && look !== undefined) {
          transaction.update(memberDoc, { look: lookOf(initial, look.stage) });
        }
      }
      transaction.update(avatarDoc, changes);
    }
    return files;
  });
  if (doomed === null) return 'gone';
  if (doomed.length > 0) await objects.deleteObjects(doomed);
  return 'deleted';
}

/** A member's keepsakes and creation requests go with them (avatars ADR-0005). */
export async function forgetAvatarRecords(
  store: Firestore,
  householdId: string,
  memberId: string,
): Promise<void> {
  for (const collection of AVATAR_MEMBER_RECORDS) {
    const theirs = householdRef(store, householdId)
      .collection(collection)
      .where('memberId', '==', memberId)
      .limit(PAGE);
    for (;;) {
      const page = await theirs.get();
      if (page.empty) break;
      const batch = store.batch();
      for (const record of page.docs) batch.delete(record.ref);
      await batch.commit();
      if (page.size < PAGE) break;
    }
  }
}
