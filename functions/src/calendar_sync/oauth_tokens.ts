import { z } from 'zod';

import type { OAuthClient } from './sync_config';
import {
  FORM_HEADERS,
  type HttpClient,
  HttpUnreachable,
  formBody,
  jsonOf,
} from '../shared/http_client';

/**
 * The OAuth 2.0 token endpoint as Google and Microsoft both speak it: a code
 * for tokens, and a refresh token for an access token. One implementation for
 * both, parsed at the edge (ENG-09).
 */
const tokenResponse = z.object({
  access_token: z.string().min(1),
  refresh_token: z.string().min(1).optional(),
  id_token: z.string().min(1).optional(),
});

const errorResponse = z.object({ error: z.string() });

const idTokenClaims = z.object({
  email: z.string().optional(),
  preferred_username: z.string().optional(),
});

export type TokenOutcome =
  | {
      readonly kind: 'ok';
      readonly accessToken: string;
      readonly refreshToken: string | null;
      readonly idToken: string | null;
    }
  | { readonly kind: 'revoked' }
  | { readonly kind: 'unreachable' };

export interface TokenEndpoint {
  readonly url: string;
  readonly client: OAuthClient;
  /** Microsoft wants the scopes again on every token request. */
  readonly extra?: Readonly<Record<string, string>>;
}

export async function requestTokens(
  http: HttpClient,
  endpoint: TokenEndpoint,
  grant: Record<string, string>,
): Promise<TokenOutcome> {
  let response;
  try {
    response = await http.send(endpoint.url, {
      method: 'POST',
      headers: FORM_HEADERS,
      body: formBody({
        client_id: endpoint.client.clientId,
        client_secret: endpoint.client.clientSecret,
        ...endpoint.extra,
        ...grant,
      }),
    });
  } catch (error) {
    if (error instanceof HttpUnreachable) return { kind: 'unreachable' };
    throw error;
  }
  const body = jsonOf(response.body);
  if (response.status >= 200 && response.status < 300) {
    const parsed = tokenResponse.safeParse(body);
    if (!parsed.success) return { kind: 'unreachable' };
    return {
      kind: 'ok',
      accessToken: parsed.data.access_token,
      refreshToken: parsed.data.refresh_token ?? null,
      idToken: parsed.data.id_token ?? null,
    };
  }
  // `invalid_grant` is the provider saying the person took NestPrep's access
  // away, or the token expired unused. Anything else is worth another try.
  const refused = errorResponse.safeParse(body);
  if (response.status === 400 && refused.success && refused.data.error === 'invalid_grant') {
    return { kind: 'revoked' };
  }
  if (response.status === 401) return { kind: 'revoked' };
  return { kind: 'unreachable' };
}

export function refreshGrant(refreshToken: string): Record<string, string> {
  return { grant_type: 'refresh_token', refresh_token: refreshToken };
}

export function codeGrant(
  code: string,
  codeVerifier: string,
  redirectUri: string,
): Record<string, string> {
  return {
    grant_type: 'authorization_code',
    code,
    code_verifier: codeVerifier,
    redirect_uri: redirectUri,
  };
}

/**
 * The address on an ID token that came straight back from the provider's own
 * token endpoint over TLS — which is why it is read rather than verified.
 */
export function addressOnIdToken(idToken: string | null): string {
  if (idToken === null) return '';
  const payload = idToken.split('.')[1];
  if (payload === undefined) return '';
  const claims = idTokenClaims.safeParse(
    jsonOf(Buffer.from(payload, 'base64url').toString('utf8')),
  );
  if (!claims.success) return '';
  return claims.data.email ?? claims.data.preferred_username ?? '';
}
