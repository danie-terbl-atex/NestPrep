import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { balanceRef } from '../chore_points/point_refs';
import { parseSnapshot, storedBalance } from '../chore_points/point_documents';
import { householdRef, memberRef } from '../household/documents';
import type { ObjectStore } from '../shared/storage';
import {
  type AvatarOwned,
  adultStage,
  choiceOfLook,
  imageOf,
  isAvatarHash,
  isValidChoice,
  lookOf,
  parseChoice,
  parseLook,
  parseOwned,
  sameLook,
  sanitized,
} from './avatar_look';
import {
  AVATAR_KEEPSAKES,
  AVATAR_PHOTO_MAX_BYTES,
  avatarImagePath,
  memberAvatarRef,
} from './avatar_refs';
import { starStage } from './avatar_stage';

/**
 * Brings a member's look into line with their choice as it is now (avatars
 * ADR-0001). It reads everything again rather than trusting the event, and a
 * run that finds the look already mirrored writes nothing, so its own write to
 * the choice wakes it once more and stops there.
 */

export type MemberAvatarOutcome =
  'memberGone' | 'unchanged' | 'mirrored' | 'reverted' | 'photoTaken' | 'photoRefused' | 'cleared';

export async function photoIsUsable(objects: ObjectStore, path: string): Promise<boolean> {
  const [stored] = (await objects.list(path, 1)).filter((object) => object.name === path);
  return (
    stored !== undefined &&
    stored.contentType === 'image/jpeg' &&
    stored.size > 0 &&
    stored.size <= AVATAR_PHOTO_MAX_BYTES
  );
}

/**
 * The photos a member no longer wears (Daniel, 2026-11-12): every owned image
 * that is neither the base nor a creation, which stays as its keepsake, and a
 * refused photo nobody owns.
 */
export function photosToDrop(
  owned: AvatarOwned,
  base: string | null,
  creations: ReadonlySet<string>,
  refused: string | null,
): string[] {
  const worn = imageOf(base);
  const dropped = owned.images.filter((hash) => hash !== worn && !creations.has(hash));
  const stray =
    refused !== null && !owned.images.includes(refused) && !creations.has(refused) ? [refused] : [];
  return [...new Set([...dropped, ...stray])];
}

interface Settled {
  readonly outcome: MemberAvatarOutcome;
  readonly drop: readonly string[];
}

export async function settleMemberAvatar(
  store: Firestore,
  objects: ObjectStore,
  householdId: string,
  memberId: string,
): Promise<MemberAvatarOutcome> {
  const avatarDoc = memberAvatarRef(store, householdId, memberId);
  const waiting: unknown = (await avatarDoc.get()).get('pendingPhoto');
  const usablePhoto =
    isAvatarHash(waiting) &&
    (await photoIsUsable(objects, avatarImagePath(householdId, memberId, waiting)))
      ? waiting
      : null;

  const settled = await store.runTransaction(async (transaction): Promise<Settled> => {
    const memberDoc = memberRef(store, householdId, memberId);
    const [avatar, member, stars] = await transaction.getAll(
      avatarDoc,
      memberDoc,
      balanceRef(store, householdId, memberId),
    );
    const keepsakes = await transaction.get(
      householdRef(store, householdId)
        .collection(AVATAR_KEEPSAKES)
        .where('memberId', '==', memberId)
        .select('imageHash')
        .limit(500),
    );
    const creations = new Set(
      keepsakes.docs.flatMap((doc) => {
        const made: unknown = doc.get('imageHash');
        return isAvatarHash(made) ? [made] : [];
      }),
    );
    const done = (outcome: MemberAvatarOutcome, drop: readonly string[] = []): Settled => ({
      outcome,
      drop,
    });
    if (member?.exists !== true) return done('memberGone');
    const current = parseLook(member.get('look'));
    if (avatar?.exists !== true) {
      if (member.get('look') === undefined) return done('unchanged');
      transaction.update(memberDoc, { look: FieldValue.delete() });
      return done('cleared');
    }

    const isKid = member.get('role') === 'kid';
    let owned = parseOwned(avatar.get('owned'));
    let choice = parseChoice(avatar.get('choice'));
    const changes: Record<string, unknown> = {};
    let outcome: MemberAvatarOutcome = 'mirrored';

    let refused: string | null = null;
    // A photo offered after the one looked at above is left for its own run.
    const pending: unknown = avatar.get('pendingPhoto');
    if (pending !== undefined && pending === waiting) {
      changes['pendingPhoto'] = FieldValue.delete();
      if (isAvatarHash(pending) && pending === usablePhoto) {
        owned = { ...owned, images: [...new Set([...owned.images, pending])] };
        choice = sanitized(
          { ...(choice ?? { wear: {} }), base: `image:${pending}` },
          owned,
          !isKid,
        );
        changes['owned'] = owned;
        changes['choice'] = choice;
        outcome = 'photoTaken';
      } else {
        refused = isAvatarHash(pending) ? pending : null;
        outcome = 'photoRefused';
      }
    }

    if (choice === undefined && avatar.get('choice') === undefined) {
      const strays = photosToDrop({ ...owned, images: [] }, null, creations, refused);
      if (Object.keys(changes).length > 0) transaction.update(avatarDoc, changes);
      return Object.keys(changes).length > 0 ? done(outcome, strays) : done('unchanged');
    }

    if (choice === undefined || !isValidChoice(choice, owned, !isKid)) {
      choice = choiceOfLook(current, isKid, owned);
      changes['choice'] = choice;
      outcome = 'reverted';
    }

    const stage = isKid
      ? starStage(
          (stars === undefined ? undefined : parseSnapshot(stars, storedBalance)) ?? {
            earned: 0,
            bestStreak: 0,
          },
        )
      : adultStage(choice);
    const drop = photosToDrop(owned, choice.base, creations, refused);
    if (drop.some((hash) => owned.images.includes(hash))) {
      owned = { ...owned, images: owned.images.filter((hash) => !drop.includes(hash)) };
      changes['owned'] = owned;
    }
    const look = lookOf(choice, stage);
    const mirrors = !sameLook(current, look);
    if (mirrors) transaction.update(memberDoc, { look });
    if (Object.keys(changes).length > 0) transaction.update(avatarDoc, changes);
    return mirrors || Object.keys(changes).length > 0 ? done(outcome, drop) : done('unchanged');
  });

  if (settled.drop.length > 0) {
    await objects.deleteObjects(
      settled.drop.map((hash) => avatarImagePath(householdId, memberId, hash)),
    );
  }
  return settled.outcome;
}
