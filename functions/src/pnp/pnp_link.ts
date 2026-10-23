import { logger } from 'firebase-functions/v2';

import { accessExpiryOf } from './access_expiry';
import { asPnp } from './as_pnp';
import { PNP_REDIRECT_URI } from './http_pnp_login';
import { PnpRefused, PnpUnavailable, type PnpLogin, type PnpTokens } from './pnp_api';
import { refusePnp } from './pnp_errors';
import type { PnpLinkStore } from './pnp_link_store';
import { openLinkSecrets, sealLinkSecrets, sealSessionTokens } from './pnp_sealed_values';
import { pkcePair, randomUrlToken } from './pkce_pair';

/** How long a started link can be completed. */
export const PENDING_LINK_MINUTES = 15;

export const PNP_SCOPE = 'openid offline_access';

export interface PnpLinkDeps {
  readonly links: PnpLinkStore;
  readonly login: PnpLogin;
  readonly key: Buffer;
  readonly now: Date;
}

/**
 * Starts linking the member's own Pick n Pay account (add-to-pnp ADR-0003):
 * a PKCE verifier, a state and a nonce, sealed and kept fifteen minutes,
 * and the URL of PnP's own login page for the app's web view. The verifier
 * never leaves the server.
 */
export async function startPnpLink(
  deps: PnpLinkDeps,
  uid: string,
): Promise<{ authorizeUrl: string }> {
  const client = await asPnp(() => deps.login.client(), 'client not read');
  const { verifier, challenge } = pkcePair();
  const state = randomUrlToken(16);
  const nonce = randomUrlToken(16);
  await deps.links.savePending(uid, {
    sealed: await sealLinkSecrets(deps.key, uid, { verifier, state, nonce }),
    expiresAt: new Date(deps.now.getTime() + PENDING_LINK_MINUTES * 60_000),
  });
  const query = new URLSearchParams({
    response_type: 'code',
    client_id: client.clientId,
    redirect_uri: PNP_REDIRECT_URI,
    scope: PNP_SCOPE,
    state,
    nonce,
    code_challenge: challenge,
    code_challenge_method: 'S256',
  });
  logger.info('pnp link started', { uid });
  return { authorizeUrl: `${client.authorizeEndpoint}?${query.toString()}` };
}

/**
 * Completes the link with the code the app took from PnP's redirect: the
 * pending link is used up first (a code is single-use), the state must be the
 * one this start made, then PnP swaps the code for the member's tokens, which
 * are sealed. The ID token is not kept.
 */
export async function completePnpLink(
  deps: PnpLinkDeps,
  uid: string,
  answer: { code: string; state: string },
): Promise<{ linked: true; linkedAt: string }> {
  const pending = await deps.links.claimPending(uid, deps.now);
  if (pending === null) throw refusePnp('pnp-no-pending-link');
  const secrets = await openLinkSecrets(deps.key, uid, pending.sealed);
  if (secrets === null) {
    logger.warn('pnp pending link does not open', { uid });
    throw refusePnp('pnp-no-pending-link');
  }
  if (secrets.state !== answer.state) {
    logger.warn('pnp link state does not match', { uid });
    throw refusePnp('pnp-link-refused');
  }
  const tokens = await exchange(deps.login, answer.code, secrets.verifier);
  if (tokens.refreshToken === null) {
    // Without one the link would last minutes; PnP's offline_access should give it.
    logger.warn('pnp gave no refresh token', { uid });
    throw refusePnp('pnp-link-refused');
  }
  const linkedAt = deps.now;
  await deps.links.saveSession(uid, {
    sealed: await sealSessionTokens(deps.key, uid, {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    }),
    accessExpiresAt: accessExpiryOf(tokens, deps.now),
    linkedAt,
  });
  logger.info('pnp account linked', { uid });
  return { linked: true, linkedAt: linkedAt.toISOString() };
}

async function exchange(login: PnpLogin, code: string, verifier: string): Promise<PnpTokens> {
  try {
    return await login.exchangeCode(code, verifier);
  } catch (error) {
    if (error instanceof PnpRefused) throw refusePnp('pnp-link-refused');
    throw error instanceof PnpUnavailable ? downFrom(error) : error;
  }
}

function downFrom(error: PnpUnavailable): Error {
  logger.warn('pnp code not exchanged', { reason: error.reason });
  return refusePnp('pnp-down');
}
