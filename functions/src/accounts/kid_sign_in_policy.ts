import { randomInt } from 'node:crypto';

import type { MemberDocument, Role } from '../household/documents';
import type { KidPairingDocument } from './kid_documents';
import type { KidRefusal } from './kid_errors';

/**
 * The rules of kid sign-in, as pure functions so they are tested where they
 * live (`BE-14`) rather than only through a callable (accounts ADR-0003).
 */

/** Six characters: one breath, typed on a child's device with a parent beside it. */
export const KID_CODE_LENGTH = 6;

/** Ten minutes: long enough to find the tablet, short enough to be no use later. */
export const KID_CODE_LIFETIME_MS = 10 * 60 * 1000;

/** A lost tablet, a phone, a school laptop, and room to spare. */
export const KID_DEVICE_LIMIT = 5;

/**
 * The roles a kid sign-in may be made for. Mirrored by the client's
 * `MemberRole.canHaveKidSignIn`. Household phase 2's `kid` role joins this
 * list when it exists.
 */
export const KID_SIGN_IN_ROLES: readonly Role[] = ['member'];

/**
 * Whether a profile may have a kid sign-in: nobody has claimed it, and its role
 * is a child's. A claimed profile already has a person; an admin or helper is
 * not a child.
 */
export function isEligibleForKidSignIn(
  member: Pick<MemberDocument, 'role' | 'claimedBy'>,
): boolean {
  return member.claimedBy === null && KID_SIGN_IN_ROLES.includes(member.role);
}

/** Why a pairing cannot be redeemed now, or null when it can. */
export function pairingRefusal(
  pairing: KidPairingDocument | null,
  nowMs: number,
): KidRefusal | null {
  if (pairing === null) return 'codeNotFound';
  if (pairing.expiresAt.toMillis() <= nowMs) return 'codeExpired';
  return null;
}

const UID_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
const UID_RANDOM_LENGTH = 20;

/**
 * A fresh uid for one kid device. The prefix is for a person reading the Auth
 * console, never for a rule: nothing authorises on the shape of a uid.
 */
export function newKidUid(random: (max: number) => number = randomInt): string {
  let suffix = '';
  for (let index = 0; index < UID_RANDOM_LENGTH; index += 1) {
    suffix += UID_ALPHABET.charAt(random(UID_ALPHABET.length));
  }
  return `kid_${suffix}`;
}
