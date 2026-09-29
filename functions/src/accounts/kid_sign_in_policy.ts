import { randomInt } from 'node:crypto';

import type { MemberDocument, Role } from '../household/documents';
import type { RateLimitRule } from '../shared/rate_limit';
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

/**
 * Twenty redemptions in ten minutes from one address, and a thousand an hour
 * from everywhere: far past a family pairing its tablets, far short of
 * guessing a six-character code (accounts ADR-0006). The address is spoofable,
 * which is why the second limit exists.
 */
export const KID_REDEEM_PER_ADDRESS: RateLimitRule = {
  name: 'redeemKidPairing:address',
  limit: 20,
  windowSeconds: 10 * 60,
};
export const KID_REDEEM_OVERALL: RateLimitRule = {
  name: 'redeemKidPairing:all',
  limit: 1000,
  windowSeconds: 60 * 60,
};

/** A lost tablet, a phone, a school laptop, and room to spare. */
export const KID_DEVICE_LIMIT = 5;

/**
 * The roles a kid sign-in may be made for: `kid`, and only `kid` (accounts
 * ADR-0004). A kid device holds its profile's grant, which only a `kid` has —
 * `member` is read as a parent (household ADR-0003), and a device bound to one
 * would have no grant to hold. Mirrored by the client's
 * `MemberRole.canHaveKidSignIn`.
 */
export const KID_SIGN_IN_ROLES: readonly Role[] = ['kid'];

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
