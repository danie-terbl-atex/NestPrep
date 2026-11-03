import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { consumeRateLimit } from '../../shared/rate_limit';
import { ASSISTANT_SCOPES, parseScopes } from '../assistant_scopes';
import type { AuthorizationServer } from './assistants_config';
import {
  AUTH_REQUEST_LIFETIME_MS,
  type StoredAuthRequest,
  authRequestRef,
  later,
  newSecret,
  sha256Hex,
} from './auth_documents';
import { AUTHORIZE_OVERALL, AUTHORIZE_PER_ADDRESS } from './auth_rate_limits';
import { type AuthReply, authorizeErrorPage } from './auth_reply';
import { type ClientLookup, resolveClient } from './client_registry';
import { isAllowedRedirect, redirectMatches } from './redirect_policy';

export interface AuthorizeContext {
  readonly server: AuthorizationServer;
  readonly clients: ClientLookup;
  readonly address: string;
  /** The `__session` the browser already carries, reused so two sign-ins at once both work. */
  readonly session: string | null;
}

const trusted = z.object({
  client_id: z.string().min(1).max(2048),
  redirect_uri: z.string().min(1).max(2048),
});

const request = z.object({
  response_type: z.string().optional(),
  code_challenge: z.string().optional(),
  code_challenge_method: z.string().optional(),
  resource: z.string().optional(),
  scope: z.string().max(1000).optional(),
  state: z.string().min(1).max(2048).optional(),
});

const S256_CHALLENGE = /^[A-Za-z0-9_-]{43}$/;

/**
 * `GET /oauth/authorize` (assistants ADR-0002). The client and its exact
 * redirect are checked first, and until both hold nothing is sent anywhere:
 * a bad one gets a page, never a redirect, so NestPrep cannot be made to
 * bounce a browser to an address it does not trust. After that every error
 * goes back to the client with `state` and `iss`. A good request is saved,
 * tied to this browser by the `__session` cookie, and the browser goes on to
 * the consent page.
 */
export async function authorize(context: AuthorizeContext, query: unknown): Promise<AuthReply> {
  const { store, now } = context.clients;
  if (
    !(await consumeRateLimit(store, AUTHORIZE_OVERALL, 'all', now)) ||
    !(await consumeRateLimit(store, AUTHORIZE_PER_ADDRESS, context.address, now))
  ) {
    return authorizeErrorPage('tooMany');
  }
  const identity = trusted.safeParse(query);
  if (!identity.success) return authorizeErrorPage('unknownClient');
  const { client_id: clientId, redirect_uri: redirectUri } = identity.data;

  const resolution = await resolveClient(context.clients, clientId);
  if (resolution.kind === 'unknown') {
    logger.warn('assistant authorize refused an unknown client', { reason: resolution.reason });
    return authorizeErrorPage('unknownClient');
  }
  const { client } = resolution;
  if (
    !isAllowedRedirect(redirectUri, context.clients.allowLoopbackRedirects) ||
    !redirectMatches(client.redirectUris, redirectUri)
  ) {
    logger.warn('assistant authorize refused a redirect', { kind: client.kind });
    return authorizeErrorPage('badRedirect');
  }

  const parsed = request.safeParse(query);
  const asked = parsed.success ? parsed.data : {};
  const refuse = (error: string, description: string): AuthReply => ({
    kind: 'redirect',
    location: errorRedirect(context.server, redirectUri, error, description, asked.state),
  });
  if (!parsed.success || asked.state === undefined) {
    return refuse('invalid_request', 'state is required');
  }
  if (asked.response_type !== 'code') {
    return refuse('unsupported_response_type', 'only response_type=code is supported');
  }
  if (asked.code_challenge_method !== 'S256' || !S256_CHALLENGE.test(asked.code_challenge ?? '')) {
    return refuse('invalid_request', 'PKCE with code_challenge_method=S256 is required');
  }
  if (asked.resource !== context.server.resource) {
    return refuse('invalid_target', `resource must be ${context.server.resource}`);
  }
  const wanted = parseScopes(asked.scope);

  const session = context.session ?? newSecret();
  const requestId = newSecret();
  const pending: StoredAuthRequest = {
    clientId,
    clientName: client.clientName,
    host: client.host,
    via: client.via,
    redirectUri,
    codeChallenge: asked.code_challenge ?? '',
    state: asked.state,
    resource: asked.resource,
    scopes: wanted.length === 0 ? [...ASSISTANT_SCOPES] : wanted,
    sessionHash: sha256Hex(session),
    createdAt: Timestamp.fromDate(now),
    expiresAt: later(now, AUTH_REQUEST_LIFETIME_MS),
  };
  const batch = store.batch();
  batch.set(authRequestRef(store, requestId), pending);
  await batch.commit();

  return {
    kind: 'redirect',
    location: `${context.server.issuer}/connect?request=${requestId}`,
    session,
  };
}

/** Where an answer goes once the redirect is trusted: the client's own URI, with `iss` (RFC 9207). */
export function clientRedirect(
  server: AuthorizationServer,
  redirectUri: string,
  params: Readonly<Record<string, string | undefined>>,
): string {
  const url = new URL(redirectUri);
  for (const [name, value] of Object.entries(params)) {
    if (value !== undefined) url.searchParams.append(name, value);
  }
  url.searchParams.append('iss', server.issuer);
  return url.toString();
}

function errorRedirect(
  server: AuthorizationServer,
  redirectUri: string,
  error: string,
  description: string,
  state: string | undefined,
): string {
  return clientRedirect(server, redirectUri, { error, error_description: description, state });
}
