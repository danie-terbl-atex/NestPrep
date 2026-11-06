import { logger } from 'firebase-functions/v2';

import {
  WoolworthsSessionExpired,
  WoolworthsUnavailable,
  type WoolworthsLogin,
  type WoolworthsTokens,
} from './woolworths_api';
import { refuseWoolworths } from './woolworths_errors';
import { idExpiryOf, idTokenClaims, maskedEmail } from './woolworths_id_token';
import type { WoolworthsLink, WoolworthsLinkStore } from './woolworths_link_store';
import { sealSessionTokens } from './woolworths_sealed_values';

export interface WoolworthsLinkStatus {
  readonly linked: boolean;
  readonly linkedAt?: string;
  readonly emailMasked?: string;
}

export interface WoolworthsLinkDeps {
  readonly links: WoolworthsLinkStore;
  readonly login: WoolworthsLogin;
  readonly key: Buffer;
  readonly now: Date;
}

export function woolworthsLinkStatusOf(link: WoolworthsLink | null): WoolworthsLinkStatus {
  const session = link?.session ?? null;
  if (session === null) return { linked: false };
  return {
    linked: true,
    linkedAt: session.linkedAt.toISOString(),
    ...(session.emailMasked === null ? {} : { emailMasked: session.emailMasked }),
  };
}

export async function completeWoolworthsLink(
  deps: WoolworthsLinkDeps,
  uid: string,
  refreshToken: string,
): Promise<WoolworthsLinkStatus> {
  const tokens = await proved(deps.login, refreshToken);
  const session = {
    sealed: await sealSessionTokens(deps.key, uid, {
      refreshToken: tokens.refreshToken ?? refreshToken,
      idToken: tokens.idToken,
    }),
    idExpiresAt: idExpiryOf(tokens, deps.now),
    linkedAt: deps.now,
    emailMasked: maskedEmail(idTokenClaims(tokens.idToken)?.email),
  };
  await deps.links.saveSession(uid, session);
  logger.info('woolworths account linked', { uid });
  return woolworthsLinkStatusOf({ session });
}

async function proved(login: WoolworthsLogin, refreshToken: string): Promise<WoolworthsTokens> {
  try {
    return await login.refresh(refreshToken);
  } catch (error) {
    if (error instanceof WoolworthsSessionExpired) {
      throw refuseWoolworths('woolworths-link-rejected');
    }
    if (error instanceof WoolworthsUnavailable) {
      logger.warn('woolworths link not proved', { reason: error.reason });
      throw refuseWoolworths('woolworths-unavailable');
    }
    throw error;
  }
}
