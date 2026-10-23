import type { PnpLink } from './pnp_link_store';

/** What `pnpLinkStatus` answers (add-to-pnp ADR-0003). */
export interface PnpLinkStatus {
  readonly linked: boolean;
  /** ISO-8601 UTC (ENG-21), or null when not linked. */
  readonly linkedAt: string | null;
}

/**
 * Linked while a session is held. There is no hour as with Checkers: the
 * session lasts as long as PnP takes its refresh token, which only a push
 * finds out — and then the push says `pnp-link-expired`.
 */
export function pnpLinkStatusOf(link: PnpLink | null): PnpLinkStatus {
  const session = link?.session ?? null;
  return session === null
    ? { linked: false, linkedAt: null }
    : { linked: true, linkedAt: session.linkedAt.toISOString() };
}
