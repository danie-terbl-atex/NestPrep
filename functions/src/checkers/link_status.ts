import type { CheckersLink, SessionLink } from './link_store';

/** What `checkersLinkStatus` answers (the Checkers build contract). */
export interface LinkStatus {
  readonly linked: boolean;
  /** ISO-8601 UTC (ENG-21), or null when not linked. */
  readonly expiresAt: string | null;
  readonly mobileMasked: string | null;
}

/** The session, while it has time left to use. */
export function liveSession(link: CheckersLink | null, now: Date): SessionLink | null {
  const session = link?.session ?? null;
  return session !== null && session.expiresAt > now ? session : null;
}

/**
 * Linked while the session has time left. A lapsed link still says which
 * number it was, so the app can offer to link that number again.
 */
export function linkStatusOf(link: CheckersLink | null, now: Date): LinkStatus {
  const live = liveSession(link, now);
  if (live !== null) {
    return {
      linked: true,
      expiresAt: live.expiresAt.toISOString(),
      mobileMasked: live.mobileMasked,
    };
  }
  return { linked: false, expiresAt: null, mobileMasked: link?.session?.mobileMasked ?? null };
}
