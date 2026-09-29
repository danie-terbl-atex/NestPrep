import { isFamilyRole } from '../../household/access';

/**
 * The rules of a shared link (documents ADR-0006), as plain decisions with no
 * I/O, so every row is a unit test rather than an emulator run.
 */

/** The lifetimes a person may choose. The app offers exactly these. */
export const SHARE_LIFETIME_HOURS = [1, 4, 24, 72, 168] as const;

/** A shift-bound link never outlives this, even if the shift is never ended. */
export const MAX_SHARE_HOURS = 168;

/** Live links per household, so the list is bounded (`BE-08`). */
export const MAX_LIVE_SHARES = 25;

/** The fifth wrong PIN locks the link for good. */
export const MAX_PIN_ATTEMPTS = 5;

/** How long a right PIN lets the receiver fetch the file. */
export const PASS_LIFETIME_MS = 15 * 60 * 1000;

/** How long an ended link stays in the family's history before its TTL. */
export const PURGE_AFTER_MS = 30 * 24 * 60 * 60 * 1000;

const HOUR_MS = 60 * 60 * 1000;

export type ShareScope = 'household' | 'vault';
export type ShareStatus = 'active' | 'revoked' | 'ended' | 'locked';

export type ShareLifetime =
  | { readonly kind: 'hours'; readonly hours: number }
  | { readonly kind: 'shift'; readonly shiftId: string };

/** When a link made [now] with [lifetime] stops working at the latest. */
export function expiryFor(now: Date, lifetime: ShareLifetime): Date {
  const hours = lifetime.kind === 'hours' ? lifetime.hours : MAX_SHARE_HOURS;
  return new Date(now.getTime() + hours * HOUR_MS);
}

/** When the link's record is removed from the family's history. */
export function purgeAfter(expiresAt: Date): Date {
  return new Date(expiresAt.getTime() + PURGE_AFTER_MS);
}

export interface Sharer {
  /** The caller's role, re-derived from the household's membership map. */
  readonly role: string | undefined;
  /** The profile the caller claimed here, if any. */
  readonly memberId: string | undefined;
}

/**
 * Who may send a document outside the household (documents ADR-0006): the
 * family, for anything; a vault's owner, for their own vault. A grantee reads
 * a vault but never shares it, and a helper with `documents: edit` does not
 * send the household's papers out.
 */
export function mayShare(sharer: Sharer, scope: ShareScope, ownerMemberId: string | null): boolean {
  if (sharer.role === undefined) return false;
  if (isFamilyRole(sharer.role)) return true;
  return (
    scope === 'vault' &&
    ownerMemberId !== null &&
    sharer.memberId !== undefined &&
    sharer.memberId === ownerMemberId
  );
}

export interface ShareState {
  readonly status: ShareStatus;
  readonly expiresAt: Date;
  /** Whether the shift this link is bound to is still open; true when unbound. */
  readonly shiftIsOpen: boolean;
  readonly featureIsOn: boolean;
  /** Whether whoever made it could still make it now. */
  readonly creatorMayShare: boolean;
  readonly documentExists: boolean;
}

export type ShareVerdict = 'open' | 'expired' | 'ended';

/**
 * Whether a link may be served right now. Checked on every request, page and
 * file alike (documents ADR-0006). `expired` is the one reason worth telling a
 * receiver apart; every other refusal reads the same — "no longer works".
 */
export function verdictFor(share: ShareState, now: Date): ShareVerdict {
  if (share.status !== 'active') return 'ended';
  if (share.expiresAt.getTime() <= now.getTime()) return 'expired';
  if (!share.featureIsOn || !share.shiftIsOpen) return 'ended';
  if (!share.creatorMayShare || !share.documentExists) return 'ended';
  return 'open';
}

/** Attempts left after [failed] wrong PINs, never below zero. */
export function attemptsLeft(failed: number): number {
  return Math.max(0, MAX_PIN_ATTEMPTS - failed);
}
