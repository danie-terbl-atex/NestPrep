/**
 * A member's Pick n Pay link, `pnpLinks/{uid}` (add-to-pnp ADR-0003):
 * server-only, closed to every client by the rules.
 *
 * What names the member's PnP account is sealed (`shared/session_crypto.ts`
 * under `PNP_SESSION_KEY`): the pending link's PKCE verifier, state and nonce,
 * and the access and refresh tokens. What stays readable is when the pending
 * link lapses, when the access token does, and when the member linked.
 */
export interface PendingPnpLink {
  readonly sealed: string;
  readonly expiresAt: Date;
}

export interface PnpSessionLink {
  readonly sealed: string;
  readonly accessExpiresAt: Date;
  readonly linkedAt: Date;
}

export type SessionSwap = 'replaced' | 'changed' | 'gone';

export interface PnpLink {
  readonly pending: PendingPnpLink | null;
  readonly session: PnpSessionLink | null;
}

/**
 * What the PnP callables read and write, as an interface so their rules are
 * tested without Firestore (BE-01, BE-14). `FirestorePnpLinkStore` is the one
 * implementation that runs.
 */
export interface PnpLinkStore {
  read(uid: string): Promise<PnpLink | null>;

  /** Replaces any pending link with this one; a session the member has stays. */
  savePending(uid: string, pending: PendingPnpLink): Promise<void>;

  /**
   * Takes the pending link away and answers it, when it is still live — in
   * one transaction, so a login code can be completed once (BE-06). Null when
   * there is none or it has lapsed.
   */
  claimPending(uid: string, now: Date): Promise<PendingPnpLink | null>;

  /** Stores the session; a pending link is dropped. Only a completed link writes this way. */
  saveSession(uid: string, session: PnpSessionLink): Promise<void>;

  /**
   * Replaces the session with [next] only while it is still the one sealed as
   * [expectedSealed], in one transaction — a compare-and-swap. `gone` when the
   * link or its session no longer exists (the member unlinked, or the account
   * was erased: nothing is written back), `changed` when another refresh
   * replaced it first (ADR-0003 §5–6).
   */
  replaceSession(uid: string, expectedSealed: string, next: PnpSessionLink): Promise<SessionSwap>;

  remove(uid: string): Promise<void>;
}
