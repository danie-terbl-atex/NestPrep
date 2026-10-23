import { logger } from 'firebase-functions/v2';

import { accessExpiryOf } from './access_expiry';
import { asPnp } from './as_pnp';
import { PnpSessionExpired, type PnpLogin } from './pnp_api';
import { refusePnp } from './pnp_errors';
import type { PnpLinkStore, PnpSessionLink } from './pnp_link_store';
import { openSessionTokens, sealSessionTokens, type PnpSessionTokens } from './pnp_sealed_values';

export interface PnpSessionDeps {
  readonly links: PnpLinkStore;
  readonly login: PnpLogin;
  readonly key: Buffer;
  readonly now: Date;
}

/**
 * Runs [call] with the member's live access token (add-to-pnp ADR-0003): one
 * about to lapse is refreshed first, a rotated refresh token replaces the old
 * one, and a call PnP refuses as unauthorised is tried once more after a
 * refresh. A refresh PnP refuses, or a second refusal, is `pnp-link-expired` —
 * the member links again. [call] must be safe to run twice (every PnP cart
 * write is absolute — ADR-0004).
 */
export async function withPnpSession<T>(
  deps: PnpSessionDeps,
  uid: string,
  call: (accessToken: string) => Promise<T>,
): Promise<T> {
  let current = await liveSession(deps, uid);
  let refreshed = false;
  if (current.accessExpiresAt <= deps.now) {
    current = await refresh(deps, uid, current);
    refreshed = true;
  }
  try {
    return await call(current.tokens.accessToken);
  } catch (error) {
    if (!(error instanceof PnpSessionExpired)) throw error;
    if (refreshed) throw refusePnp('pnp-link-expired');
  }
  current = await refresh(deps, uid, current);
  try {
    return await call(current.tokens.accessToken);
  } catch (error) {
    if (error instanceof PnpSessionExpired) throw refusePnp('pnp-link-expired');
    throw error;
  }
}

/** The session as stored and opened: what a refresh must still find there to replace it. */
interface OpenSession {
  readonly sealed: string;
  readonly accessExpiresAt: Date;
  readonly linkedAt: Date;
  readonly tokens: PnpSessionTokens;
}

async function liveSession(deps: PnpSessionDeps, uid: string): Promise<OpenSession> {
  const opened = await openStored((await deps.links.read(uid))?.session ?? null, deps.key, uid);
  if (opened === null) throw refusePnp('pnp-link-expired');
  return opened;
}

async function openStored(
  session: PnpSessionLink | null,
  key: Buffer,
  uid: string,
): Promise<OpenSession | null> {
  if (session === null) return null;
  const tokens = await openSessionTokens(key, uid, session.sealed);
  if (tokens === null) {
    logger.warn('pnp session does not open', { uid });
    return null;
  }
  return { ...session, tokens };
}

/**
 * A fresh access token, saved only if the session is still the one it was
 * refreshed from (a compare-and-swap, ADR-0003 §5–6). An unlink or an erasure
 * that landed meanwhile wins: the new tokens are dropped and the link has
 * expired. A refresh racing this one wins too: its tokens are used, so a
 * rotated refresh token is never lost.
 */
async function refresh(
  deps: PnpSessionDeps,
  uid: string,
  current: OpenSession,
): Promise<OpenSession> {
  let fresh;
  try {
    fresh = await asPnp(() => deps.login.refresh(current.tokens.refreshToken), 'refresh failed');
  } catch (error) {
    if (!(error instanceof PnpSessionExpired)) throw error;
    const winner = await awaitRacedRefresh(deps, uid, current.sealed);
    if (winner !== null) return winner;
    logger.info('pnp refresh refused', { uid });
    throw refusePnp('pnp-link-expired');
  }
  const tokens = {
    accessToken: fresh.accessToken,
    refreshToken: fresh.refreshToken ?? current.tokens.refreshToken,
  };
  const next = {
    sealed: await sealSessionTokens(deps.key, uid, tokens),
    accessExpiresAt: accessExpiryOf(fresh, deps.now),
    linkedAt: current.linkedAt,
  };
  const swap = await deps.links.replaceSession(uid, current.sealed, next);
  if (swap === 'replaced') return { ...next, tokens };
  const winner = swap === 'changed' ? await racedRefresh(deps, uid, current.sealed) : null;
  if (winner !== null) return winner;
  logger.info('pnp refresh dropped: the link is gone', { uid });
  throw refusePnp('pnp-link-expired');
}

/** How long a refused refresh waits for a racing refresh to finish saving, in all. */
export const RACE_WAIT_MS = 600;
const RACE_READS = 3;

/**
 * PnP refuses a refresh token another refresh has just rotated before that
 * refresh has saved its answer, so a refused refresh looks again, briefly,
 * for the winner's tokens before calling the link expired.
 */
async function awaitRacedRefresh(
  deps: PnpSessionDeps,
  uid: string,
  replacedSealed: string,
): Promise<OpenSession | null> {
  for (let read = 1; read <= RACE_READS; read += 1) {
    const winner = await racedRefresh(deps, uid, replacedSealed);
    if (winner !== null || read === RACE_READS) return winner;
    await new Promise((resolve) => setTimeout(resolve, RACE_WAIT_MS / RACE_READS));
  }
  return null;
}

/** The session another refresh stored after [replacedSealed], or null when there is none. */
async function racedRefresh(
  deps: PnpSessionDeps,
  uid: string,
  replacedSealed: string,
): Promise<OpenSession | null> {
  const session = (await deps.links.read(uid))?.session ?? null;
  if (session === null || session.sealed === replacedSealed) return null;
  return openStored(session, deps.key, uid);
}
