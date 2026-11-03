import { createHash, randomBytes } from 'node:crypto';
import { type Server, createServer } from 'node:http';
import type { AddressInfo } from 'node:net';

import { expect } from 'vitest';

import { HOSTING_REGION } from '../../src/shared/region';
import { PROJECT_ID, adminDb, httpFunctionUrl, type TestUser } from './emulator_harness';

/**
 * An OAuth client for the assistants' authorization server (assistants
 * ADR-0002), doing exactly what Claude or ChatGPT does over HTTP — discovery,
 * a client metadata document or a registration, authorize with PKCE, the
 * consent page's three calls with an Auth-emulator ID token, the code for
 * tokens, refresh, revoke — so the suite proves the flow, not the parts.
 */

export const AUTH = httpFunctionUrl('assistantAuth', HOSTING_REGION);
export const ISSUER = 'https://nestprep-643b7.web.app';
export const RESOURCE = `${ISSUER}/mcp`;
export const CLAUDE_CALLBACK = 'https://claude.ai/api/mcp/auth_callback';
export const CHATGPT_CALLBACK = 'https://chatgpt.com/connector_platform_oauth_redirect';

export interface Answer {
  readonly status: number;
  readonly body: Record<string, unknown>;
  readonly headers: Headers;
}

export async function getJson(path: string): Promise<Answer> {
  const response = await fetch(`${AUTH}${path}`);
  return { status: response.status, body: await bodyOf(response), headers: response.headers };
}

export async function postJson(path: string, body: unknown, cookie?: string): Promise<Answer> {
  const response = await fetch(`${AUTH}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(cookie === undefined ? {} : { Cookie: cookie }),
    },
    body: JSON.stringify(body),
  });
  return { status: response.status, body: await bodyOf(response), headers: response.headers };
}

/** The token endpoint as clients call it: a form-encoded POST. */
export async function postForm(path: string, fields: Record<string, string>): Promise<Answer> {
  const response = await fetch(`${AUTH}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams(fields).toString(),
  });
  return { status: response.status, body: await bodyOf(response), headers: response.headers };
}

async function bodyOf(response: Response): Promise<Record<string, unknown>> {
  const text = await response.text();
  try {
    const parsed: unknown = JSON.parse(text);
    return typeof parsed === 'object' && parsed !== null ? { ...parsed } : {};
  } catch {
    return { html: text };
  }
}

export interface Pkce {
  readonly verifier: string;
  readonly challenge: string;
}

export function newPkce(): Pkce {
  const verifier = randomBytes(32).toString('base64url');
  return { verifier, challenge: createHash('sha256').update(verifier).digest('base64url') };
}

/**
 * A client metadata document served from this machine, which the Functions
 * emulator may fetch only once `assistantsEmulator/cimd` says so.
 */
export interface ClientDocumentServer {
  readonly clientId: string;
  readonly close: () => Promise<void>;
}

export async function serveClientDocument(
  document: (clientId: string) => Record<string, unknown>,
): Promise<ClientDocumentServer> {
  let clientId = '';
  const server: Server = createServer((req, res) => {
    if (req.url !== '/client.json') {
      res.writeHead(404).end();
      return;
    }
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify(document(clientId)));
  });
  await new Promise<void>((resolve) => {
    server.listen(0, '127.0.0.1', resolve);
  });
  clientId = `http://127.0.0.1:${String((server.address() as AddressInfo).port)}/client.json`;
  return {
    clientId,
    close: () =>
      new Promise<void>((resolve) => {
        server.close(() => {
          resolve();
        });
      }),
  };
}

export const claudeDocument =
  (redirect = CLAUDE_CALLBACK) =>
  (clientId: string): Record<string, unknown> => ({
    client_id: clientId,
    client_name: 'Claude',
    client_uri: 'https://claude.ai',
    redirect_uris: [redirect],
    token_endpoint_auth_method: 'none',
    grant_types: [
      'authorization_code',
      'refresh_token',
      'urn:ietf:params:oauth:grant-type:jwt-bearer',
    ],
    response_types: ['code'],
  });

export async function allowLocalClientDocuments(allow: boolean): Promise<void> {
  await adminDb().collection('assistantsEmulator').doc('cimd').set({ allowLoopback: allow });
}

/** A ChatGPT-shaped client, registered dynamically. */
export async function registerChatGpt(): Promise<string> {
  const registered = await postJson('/oauth/register', {
    client_name: 'ChatGPT',
    redirect_uris: [CHATGPT_CALLBACK],
    token_endpoint_auth_method: 'none',
    grant_types: ['authorization_code', 'refresh_token'],
    response_types: ['code'],
  });
  expect(registered.status).toBe(201);
  const clientId = registered.body['client_id'];
  if (typeof clientId !== 'string') throw new Error('registration gave no client id');
  return clientId;
}

export interface Authorized {
  /** Where the browser was sent: the consent page, or the client with an error. */
  readonly status: number;
  readonly location: URL | null;
  readonly cookie: string | null;
  readonly requestId: string | null;
  readonly html: string;
}

export interface AuthorizeParams {
  readonly clientId: string;
  readonly redirectUri?: string;
  readonly pkce?: Pkce | null;
  readonly method?: string;
  readonly resource?: string | null;
  readonly scope?: string;
  readonly state?: string | null;
  readonly responseType?: string;
}

export async function authorize(params: AuthorizeParams, cookie?: string): Promise<Authorized> {
  const pkce = params.pkce === undefined ? newPkce() : params.pkce;
  const query: Record<string, string> = {
    client_id: params.clientId,
    redirect_uri: params.redirectUri ?? CLAUDE_CALLBACK,
    response_type: params.responseType ?? 'code',
  };
  if (pkce !== null) {
    query['code_challenge'] = pkce.challenge;
    query['code_challenge_method'] = params.method ?? 'S256';
  }
  if (params.resource !== null) query['resource'] = params.resource ?? RESOURCE;
  if (params.state !== null) query['state'] = params.state ?? 'state-1';
  if (params.scope !== undefined) query['scope'] = params.scope;

  const response = await fetch(`${AUTH}/oauth/authorize?${new URLSearchParams(query).toString()}`, {
    redirect: 'manual',
    headers: cookie === undefined ? {} : { Cookie: cookie },
  });
  const location = response.headers.get('location');
  const setCookie = response.headers.get('set-cookie');
  const url = location === null ? null : new URL(location);
  return {
    status: response.status,
    location: url,
    cookie: setCookie === null ? null : (setCookie.split(';')[0] ?? null),
    requestId: url?.pathname === '/connect' ? url.searchParams.get('request') : null,
    html: await response.text(),
  };
}

export interface Consented {
  readonly code: string;
  readonly state: string | null;
  readonly iss: string | null;
}

/** The consent page's three calls, allowing. */
export async function consent(
  authorized: Authorized,
  user: TestUser,
  householdId: string,
  scopes?: readonly string[],
): Promise<Consented> {
  const { requestId, cookie } = authorized;
  if (requestId === null || cookie === null) throw new Error('authorize did not reach consent');
  const described = await postJson('/oauth/consent/describe', { requestId }, cookie);
  expect(described.status).toBe(200);
  const listed = await postJson(
    '/oauth/consent/households',
    { requestId, idToken: user.idToken },
    cookie,
  );
  expect(listed.status).toBe(200);
  const decided = await postJson(
    '/oauth/consent/decide',
    {
      requestId,
      idToken: user.idToken,
      decision: 'allow',
      householdId,
      scopes: scopes ?? described.body['scopes'],
    },
    cookie,
  );
  expect(decided.status, JSON.stringify(decided.body)).toBe(200);
  const redirect = new URL(String(decided.body['redirect']));
  return {
    code: redirect.searchParams.get('code') ?? '',
    state: redirect.searchParams.get('state'),
    iss: redirect.searchParams.get('iss'),
  };
}

export interface Tokens {
  readonly access: string;
  readonly refresh: string;
  readonly scope: string;
}

export function tokensOf(answer: Answer): Tokens {
  expect(answer.status, JSON.stringify(answer.body)).toBe(200);
  return {
    access: String(answer.body['access_token']),
    refresh: String(answer.body['refresh_token']),
    scope: String(answer.body['scope']),
  };
}

export function redeem(
  clientId: string,
  code: string,
  verifier: string,
  overrides: Record<string, string> = {},
): Promise<Answer> {
  return postForm('/oauth/token', {
    grant_type: 'authorization_code',
    code,
    client_id: clientId,
    redirect_uri: CLAUDE_CALLBACK,
    code_verifier: verifier,
    resource: RESOURCE,
    ...overrides,
  });
}

export function refresh(
  clientId: string,
  refreshToken: string,
  overrides: Record<string, string> = {},
): Promise<Answer> {
  return postForm('/oauth/token', {
    grant_type: 'refresh_token',
    refresh_token: refreshToken,
    client_id: clientId,
    ...overrides,
  });
}

/** The whole flow, for a test that needs a connection rather than one of its steps. */
export async function connectAs(
  clientId: string,
  user: TestUser,
  householdId: string,
  options: { redirectUri?: string; scope?: string } = {},
): Promise<Tokens> {
  const pkce = newPkce();
  const authorized = await authorize({
    clientId,
    pkce,
    ...(options.redirectUri === undefined ? {} : { redirectUri: options.redirectUri }),
    ...(options.scope === undefined ? {} : { scope: options.scope }),
  });
  const { code } = await consent(authorized, user, householdId);
  return tokensOf(
    await redeem(clientId, code, pkce.verifier, {
      redirect_uri: options.redirectUri ?? CLAUDE_CALLBACK,
    }),
  );
}

export async function grantsIn(householdId: string): Promise<FirebaseFirestore.QuerySnapshot> {
  return adminDb()
    .collection('households')
    .doc(householdId)
    .collection('assistantConnections')
    .get();
}

export async function tokensFor(grantId: string): Promise<number> {
  return (await adminDb().collection('assistantTokens').where('grantId', '==', grantId).get()).size;
}

/** Waits for a trigger's work, the way the other trigger suites do. */
export async function eventually(check: () => Promise<boolean>, what: string): Promise<void> {
  for (let attempt = 0; attempt < 50; attempt += 1) {
    if (await check()) return;
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
  throw new Error(`timed out waiting for ${what}`);
}

/**
 * An ID token the Auth emulator would accept for [uid] but signed in [minutesAgo]:
 * the emulator does not check signatures, so this is how a stale sign-in is
 * made without waiting five minutes.
 */
export function idTokenSignedInAgo(uid: string, minutesAgo: number): string {
  const now = Math.floor(Date.now() / 1000);
  const encode = (part: object): string => Buffer.from(JSON.stringify(part)).toString('base64url');
  return `${encode({ alg: 'none', typ: 'JWT' })}.${encode({
    iss: `https://securetoken.google.com/${PROJECT_ID}`,
    aud: PROJECT_ID,
    auth_time: now - minutesAgo * 60,
    user_id: uid,
    sub: uid,
    iat: now,
    exp: now + 3600,
    firebase: { identities: {}, sign_in_provider: 'password' },
  })}.`;
}
