import { logger } from 'firebase-functions/v2';

import { asWoolworths } from './as_woolworths';
import { WoolworthsSessionExpired, type WoolworthsLogin } from './woolworths_api';
import { refuseWoolworths } from './woolworths_errors';
import { idExpiryOf } from './woolworths_id_token';
import type { WoolworthsLinkStore, WoolworthsSessionLink } from './woolworths_link_store';
import {
  openSessionTokens,
  sealSessionTokens,
  type WoolworthsSessionTokens,
} from './woolworths_sealed_values';

export interface WoolworthsSessionDeps {
  readonly links: WoolworthsLinkStore;
  readonly login: WoolworthsLogin;
  readonly key: Buffer;
  readonly now: Date;
}

interface OpenSession extends WoolworthsSessionLink {
  readonly tokens: WoolworthsSessionTokens;
}

export async function withWoolworthsSession<T>(
  deps: WoolworthsSessionDeps,
  uid: string,
  call: (idToken: string) => Promise<T>,
): Promise<T> {
  let current = await liveSession(deps, uid);
  let refreshed = false;
  if (current.idExpiresAt <= deps.now) {
    current = await refresh(deps, uid, current);
    refreshed = true;
  }
  try {
    return await call(current.tokens.idToken);
  } catch (error) {
    if (!(error instanceof WoolworthsSessionExpired)) throw error;
    if (refreshed) throw refuseWoolworths('woolworths-link-expired');
  }
  current = await refresh(deps, uid, current);
  try {
    return await call(current.tokens.idToken);
  } catch (error) {
    if (error instanceof WoolworthsSessionExpired)
      throw refuseWoolworths('woolworths-link-expired');
    throw error;
  }
}

async function liveSession(deps: WoolworthsSessionDeps, uid: string): Promise<OpenSession> {
  const session = (await deps.links.read(uid))?.session ?? null;
  if (session === null) throw refuseWoolworths('woolworths-not-linked');
  const opened = await openStored(session, deps.key, uid);
  if (opened === null) throw refuseWoolworths('woolworths-link-expired');
  return opened;
}

async function openStored(
  session: WoolworthsSessionLink,
  key: Buffer,
  uid: string,
): Promise<OpenSession | null> {
  const tokens = await openSessionTokens(key, uid, session.sealed);
  if (tokens === null) {
    logger.warn('woolworths session does not open', { uid });
    return null;
  }
  return { ...session, tokens };
}

async function refresh(
  deps: WoolworthsSessionDeps,
  uid: string,
  current: OpenSession,
): Promise<OpenSession> {
  let fresh;
  try {
    fresh = await asWoolworths(
      () => deps.login.refresh(current.tokens.refreshToken),
      'refresh failed',
    );
  } catch (error) {
    if (!(error instanceof WoolworthsSessionExpired)) throw error;
    const winner = await awaitRacedRefresh(deps, uid, current.sealed);
    if (winner !== null) return winner;
    logger.info('woolworths refresh refused', { uid });
    throw refuseWoolworths('woolworths-link-expired');
  }
  const tokens = {
    refreshToken: fresh.refreshToken ?? current.tokens.refreshToken,
    idToken: fresh.idToken,
  };
  const next: WoolworthsSessionLink = {
    sealed: await sealSessionTokens(deps.key, uid, tokens),
    idExpiresAt: idExpiryOf(fresh, deps.now),
    linkedAt: current.linkedAt,
    emailMasked: current.emailMasked,
  };
  const swap = await deps.links.replaceSession(uid, current.sealed, next);
  if (swap === 'replaced') return { ...next, tokens };
  const winner = swap === 'changed' ? await racedRefresh(deps, uid, current.sealed) : null;
  if (winner !== null) return winner;
  logger.info('woolworths refresh dropped: the link is gone', { uid });
  throw refuseWoolworths('woolworths-link-expired');
}

export const RACE_WAIT_MS = 600;
const RACE_READS = 3;

// Cognito may refuse a refresh token a racing refresh has just rotated, before
// that refresh has saved; look briefly for the winner before calling it expired.
async function awaitRacedRefresh(
  deps: WoolworthsSessionDeps,
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

async function racedRefresh(
  deps: WoolworthsSessionDeps,
  uid: string,
  replacedSealed: string,
): Promise<OpenSession | null> {
  const session = (await deps.links.read(uid))?.session ?? null;
  if (session === null || session.sealed === replacedSealed) return null;
  return openStored(session, deps.key, uid);
}
