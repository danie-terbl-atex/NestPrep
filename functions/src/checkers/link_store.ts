import type { StoreContext } from './checkers_api';

/**
 * A member's Checkers link, `checkersLinks/{uid}` (the Checkers build
 * contract): server-only, closed to every client by the rules.
 *
 * Everything that names the member's Checkers account is sealed
 * (`session_crypto.ts`): the pending code's number and reference, and the
 * session token with its three identifiers. What stays readable is what the
 * link-status answer needs — when it lapses and the last four digits — and the
 * stores, which are Checkers' and not the member's.
 */
export interface PendingLink {
  readonly sealed: string;
  readonly expiresAt: Date;
  /** Codes tried against this one; past the limit it is thrown away. */
  readonly attempts: number;
  readonly mobileMasked: string;
}

export interface SessionLink {
  readonly sealed: string;
  readonly expiresAt: Date;
  readonly storeContexts: readonly StoreContext[];
  readonly mobileMasked: string;
}

export interface CheckersLink {
  /** This link's install id, sent as `device-id` on every call, as the app's is. */
  readonly deviceId: string;
  readonly pending: PendingLink | null;
  readonly session: SessionLink | null;
}

/** A pending code, claimed for one more attempt. */
export interface ClaimedAttempt {
  readonly deviceId: string;
  readonly pending: PendingLink;
}

/**
 * What the link callables read and write, as an interface so their rules are
 * tested without Firestore (BE-01, BE-14). `FirestoreLinkStore` is the one
 * implementation that runs.
 */
export interface CheckersLinkStore {
  read(uid: string): Promise<CheckersLink | null>;

  /** Replaces any pending code with this one; a session the member has stays. */
  savePending(uid: string, deviceId: string, pending: PendingLink): Promise<void>;

  /**
   * Counts one attempt at the pending code before it is tried (BE-06), or
   * null when there is no live one or its attempts are spent — which also
   * throws it away.
   */
  claimAttempt(uid: string, now: Date, maxAttempts: number): Promise<ClaimedAttempt | null>;

  /** Stores the session and drops the pending code. */
  saveSession(uid: string, deviceId: string, session: SessionLink): Promise<void>;

  remove(uid: string): Promise<void>;
}
