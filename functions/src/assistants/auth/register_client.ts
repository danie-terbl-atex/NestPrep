import { type Firestore, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { consumeRateLimit } from '../../shared/rate_limit';
import {
  REGISTERED_CLIENT_LIFETIME_MS,
  REGISTERED_CLIENT_PREFIX,
  type StoredClient,
  clientRef,
  later,
  newSecret,
} from './auth_documents';
import { REGISTER_OVERALL, REGISTER_PER_ADDRESS } from './auth_rate_limits';
import { type AuthReply, json, oauthError } from './auth_reply';
import { clientGrantTypes, clientResponseTypes } from './client_registry';
import { hostOf, isAllowedRedirect, viaOfRedirect } from './redirect_policy';

export interface RegisterContext {
  readonly store: Firestore;
  readonly address: string;
  readonly allowLoopbackRedirects: boolean;
  readonly now: Date;
}

const registration = z.object({
  redirect_uris: z.array(z.string().max(2048)).min(1).max(10),
  client_name: z.string().trim().min(1).max(100).optional(),
  token_endpoint_auth_method: z.literal('none').optional(),
  grant_types: clientGrantTypes.optional(),
  response_types: clientResponseTypes.optional(),
  application_type: z.enum(['web', 'native']).optional(),
});

/**
 * `POST /oauth/register` (RFC 7591, assistants ADR-0002): dynamic
 * registration, for a client that has no metadata document. Public clients
 * only, every redirect on the allowlist and all of them the same assistant,
 * so registering is no way round the allowlist; the client id is NestPrep's
 * own random handle.
 */
export async function registerClient(context: RegisterContext, body: unknown): Promise<AuthReply> {
  const { store, now } = context;
  const allowed =
    (await consumeRateLimit(store, REGISTER_OVERALL, 'all', now)) &&
    (await consumeRateLimit(store, REGISTER_PER_ADDRESS, context.address, now));
  if (!allowed) return oauthError(429, 'temporarily_unavailable', 'too many registrations');

  const input = registration.safeParse(body);
  if (!input.success) return oauthError(400, 'invalid_client_metadata');
  const redirectUris = input.data.redirect_uris;
  const first = redirectUris[0] ?? '';
  const via = viaOfRedirect(first);
  if (
    !redirectUris.every(
      (uri) => isAllowedRedirect(uri, context.allowLoopbackRedirects) && viaOfRedirect(uri) === via,
    )
  ) {
    logger.warn('assistant registration refused a redirect', { redirects: redirectUris.length });
    return oauthError(400, 'invalid_redirect_uri');
  }

  const clientId = `${REGISTERED_CLIENT_PREFIX}${newSecret()}`;
  const host = hostOf(first);
  const client: StoredClient = {
    kind: 'dcr',
    clientId,
    clientName: input.data.client_name ?? host,
    host,
    redirectUris,
    via,
    fetchedAt: Timestamp.fromDate(now),
    expiresAt: later(now, REGISTERED_CLIENT_LIFETIME_MS),
  };
  const batch = store.batch();
  batch.set(clientRef(store, clientId), client);
  await batch.commit();
  logger.info('assistant client registered', { via });

  return json(201, {
    client_id: clientId,
    client_id_issued_at: Math.floor(now.getTime() / 1000),
    client_name: client.clientName,
    redirect_uris: redirectUris,
    grant_types: ['authorization_code', 'refresh_token'],
    response_types: ['code'],
    token_endpoint_auth_method: 'none',
  });
}
