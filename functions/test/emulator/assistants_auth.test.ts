import { Timestamp } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import {
  CODE_LIFETIME_MS,
  REFRESH_REUSE_GRACE_MS,
  sha256Hex,
} from '../../src/assistants/auth/auth_documents';
import {
  AUTHORIZE_OVERALL,
  AUTHORIZE_PER_ADDRESS,
  CALLS_PER_GRANT,
  CONSENT_OVERALL,
  REGISTER_OVERALL,
  TOKEN_OVERALL,
  TOKEN_PER_GRANT,
  tokenRateSubject,
} from '../../src/assistants/auth/auth_rate_limits';
import { bearerAuthenticator } from '../../src/assistants/auth/bearer';
import { exchangeToken } from '../../src/assistants/auth/token_endpoint';
import { type AssistantPrincipal, AssistantRefusal } from '../../src/assistants/principal';
import { type RateLimitRule, rateLimitId } from '../../src/shared/rate_limit';
import {
  addProfile,
  household,
  joinAs,
  pairKidDevice,
  samsHousehold,
  type Household,
} from './account_data_fixture';
import {
  AUTH,
  CHATGPT_CALLBACK,
  CLAUDE_CALLBACK,
  ISSUER,
  RESOURCE,
  type ClientDocumentServer,
  allowLocalClientDocuments,
  authorize,
  claudeDocument,
  connectAs,
  consent,
  getJson,
  grantsIn,
  idTokenSignedInAgo,
  newPkce,
  postForm,
  postJson,
  redeem,
  refresh,
  registerChatGpt,
  serveClientDocument,
  tokensFor,
  tokensOf,
} from './assistants_fixture';
import { adminDb, clearFirestore, closeAdmin, signUp } from './emulator_harness';

/**
 * The assistants' authorization server end to end (assistants ADR-0002,
 * ADR-0003), driven as Claude and ChatGPT drive it: discovery, a client
 * metadata document served from this machine or a dynamic registration,
 * authorize with PKCE, the consent page's calls with real Auth-emulator ID
 * tokens, code for tokens, refresh rotation, revocation — and then
 * `authenticateBearer` on what came out. Every way in that should be shut is
 * tried.
 */

let claude: ClientDocumentServer;

beforeAll(async () => {
  claude = await serveClientDocument(claudeDocument());
});

afterAll(async () => {
  await claude.close();
  await closeAdmin();
});

beforeEach(async () => {
  await clearFirestore();
  await allowLocalClientDocuments(true);
});

const authenticate = (authorization: string): Promise<AssistantPrincipal> =>
  bearerAuthenticator(adminDb())(authorization, new Date());

async function refusalOf(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
    return 'allowed';
  } catch (error) {
    if (error instanceof AssistantRefusal) return `${error.kind}:${error.reason}`;
    throw error;
  }
}

async function atCount(rule: RateLimitRule, subject: string, count = rule.limit): Promise<void> {
  await adminDb()
    .collection('rateLimits')
    .doc(rateLimitId(rule, subject))
    .set({
      rule: rule.name,
      windowStart: Timestamp.now(),
      count,
      expiresAt: Timestamp.fromMillis(Date.now() + 3_600_000),
    });
}

async function onlyGrant(householdId: string): Promise<FirebaseFirestore.QueryDocumentSnapshot> {
  const grants = await grantsIn(householdId);
  expect(grants.size).toBe(1);
  const grant = grants.docs[0];
  if (grant === undefined) throw new Error('no grant');
  return grant;
}

describe('discovery', () => {
  it('the protected resource names the resource and this server, at both paths, never cached', async () => {
    for (const path of [
      '/.well-known/oauth-protected-resource',
      '/.well-known/oauth-protected-resource/mcp',
    ]) {
      const answer = await getJson(path);
      expect(answer.status).toBe(200);
      expect(answer.body).toMatchObject({ resource: RESOURCE, authorization_servers: [ISSUER] });
      expect(answer.headers.get('cache-control')).toBe('no-store');
      expect(answer.headers.get('access-control-allow-origin')).toBe('*');
    }
  });

  it('the server metadata says S256, public clients, CIMD and DCR', async () => {
    const answer = await getJson('/.well-known/oauth-authorization-server');
    expect(answer.body).toMatchObject({
      issuer: ISSUER,
      token_endpoint: `${ISSUER}/oauth/token`,
      code_challenge_methods_supported: ['S256'],
      client_id_metadata_document_supported: true,
      registration_endpoint: `${ISSUER}/oauth/register`,
      authorization_response_iss_parameter_supported: true,
    });
  });

  it('anything else is a 404 and a wrong method a 405', async () => {
    expect((await getJson('/oauth/nothing')).status).toBe(404);
    expect((await fetch(`${AUTH}/oauth/token`, { method: 'PUT' })).status).toBe(405);
  });
});

describe('a member connects Claude through its client metadata document', () => {
  it('signs in, consents, gets tokens, and the token is that member in that household', async () => {
    const h = await samsHousehold();
    const pkce = newPkce();
    const authorized = await authorize({ clientId: claude.clientId, pkce, scope: '' });
    expect(authorized.status).toBe(302);
    expect(authorized.location?.origin).toBe(ISSUER);
    expect(authorized.cookie).toMatch(/^__session=[A-Za-z0-9_-]{43}$/);

    const requestId = authorized.requestId ?? '';
    const described = await postJson(
      '/oauth/consent/describe',
      { requestId },
      authorized.cookie ?? '',
    );
    expect(described.body).toEqual({
      clientName: 'Claude',
      host: new URL(claude.clientId).host,
      via: 'claude',
      scopes: ['household:read', 'calendar:read', 'calendar:write', 'lists:read', 'lists:write'],
    });
    const listed = await postJson(
      '/oauth/consent/households',
      { requestId, idToken: h.sam.idToken },
      authorized.cookie ?? '',
    );
    expect(listed.body).toEqual({ households: [{ id: h.householdId, name: 'The Parkers' }] });

    const consented = await consent(authorized, h.sam, h.householdId, [
      'household:read',
      'calendar:read',
    ]);
    expect(consented.state).toBe('state-1');
    expect(consented.iss).toBe(ISSUER);
    expect(await adminDb().collection('assistantAuthRequests').doc(requestId).get()).toHaveProperty(
      'exists',
      false,
    );
    expect((await grantsIn(h.householdId)).size).toBe(0);
    const code = await adminDb().collection('assistantCodes').doc(sha256Hex(consented.code)).get();
    expect(code.data()).toMatchObject({
      uid: h.sam.uid,
      householdId: h.householdId,
      memberId: h.samMemberId,
      clientName: 'Claude',
      via: 'claude',
      scopes: ['household:read', 'calendar:read'],
      consent: { version: 1 },
      redirectUri: CLAUDE_CALLBACK,
      resource: RESOURCE,
      redeemedAt: null,
      grantId: null,
    });
    expect((code.get('expiresAt') as Timestamp).toMillis()).toBeLessThanOrEqual(
      Date.now() + CODE_LIFETIME_MS,
    );

    const tokens = tokensOf(await redeem(claude.clientId, consented.code, pkce.verifier));
    expect(tokens.access).toMatch(/^npa_[A-Za-z0-9_-]{43}$/);
    expect(tokens.refresh).toMatch(/^npr_[A-Za-z0-9_-]{43}$/);
    expect(tokens.scope).toBe('household:read calendar:read');

    const grant = await onlyGrant(h.householdId);
    expect(grant.data()).toMatchObject({
      uid: h.sam.uid,
      memberId: h.samMemberId,
      clientId: claude.clientId,
      clientName: 'Claude',
      via: 'claude',
      scopes: ['household:read', 'calendar:read'],
      consent: { version: 1 },
      refreshGeneration: 0,
      lastUsedAt: null,
    });
    expect(await authenticate(`Bearer ${tokens.access}`)).toEqual({
      grantId: grant.id,
      uid: h.sam.uid,
      householdId: h.householdId,
      via: 'claude',
      scopes: ['household:read', 'calendar:read'],
    });

    const stored = await adminDb()
      .collection('assistantTokens')
      .doc(sha256Hex(tokens.access))
      .get();
    expect(stored.exists).toBe(true);
    expect(JSON.stringify(stored.data())).not.toContain(tokens.access);
  });

  it('refreshes by rotation, and may narrow the scopes but never widen them', async () => {
    const h = await samsHousehold();
    const first = await connectAs(claude.clientId, h.sam, h.householdId, {
      scope: 'calendar:read lists:read',
    });
    const second = tokensOf(await refresh(claude.clientId, first.refresh));
    expect(second.refresh).not.toBe(first.refresh);
    expect(second.scope).toBe('calendar:read lists:read');
    expect((await authenticate(`Bearer ${second.access}`)).scopes).toEqual([
      'calendar:read',
      'lists:read',
    ]);

    const narrower = tokensOf(
      await refresh(claude.clientId, second.refresh, { scope: 'lists:read' }),
    );
    expect((await authenticate(`Bearer ${narrower.access}`)).scopes).toEqual(['lists:read']);
    const wider = await refresh(claude.clientId, narrower.refresh, { scope: 'lists:write' });
    expect(wider.body['error']).toBe('invalid_scope');
    expect((await onlyGrant(h.householdId)).get('refreshGeneration')).toBe(2);
  });

  it('two sign-ins in one browser at once both finish', async () => {
    const h = await samsHousehold();
    const [first, second] = [newPkce(), newPkce()];
    const one = await authorize({ clientId: claude.clientId, pkce: first });
    const two = await authorize({ clientId: claude.clientId, pkce: second }, one.cookie ?? '');
    expect(two.cookie).toBe(one.cookie);
    const codeOne = (await consent(one, h.sam, h.householdId)).code;
    const codeTwo = (await consent(two, h.sam, h.householdId)).code;
    tokensOf(await redeem(claude.clientId, codeOne, first.verifier));
    tokensOf(await redeem(claude.clientId, codeTwo, second.verifier));
    expect((await grantsIn(h.householdId)).size).toBe(2);
  });

  it('a sign-in abandoned after consent leaves no connection in the app', async () => {
    const h = await samsHousehold();
    await consent(await authorize({ clientId: claude.clientId }), h.sam, h.householdId);
    expect((await grantsIn(h.householdId)).size).toBe(0);
    expect((await adminDb().collection('assistantTokens').get()).size).toBe(0);
  });
});

describe('a member connects ChatGPT through dynamic registration', () => {
  it('registers, connects and is marked as ChatGPT', async () => {
    const h = await samsHousehold();
    const clientId = await registerChatGpt();
    expect(clientId).toMatch(/^npc_/);
    const tokens = await connectAs(clientId, h.sam, h.householdId, {
      redirectUri: CHATGPT_CALLBACK,
    });
    expect((await authenticate(`Bearer ${tokens.access}`)).via).toBe('chatgpt');
  });

  it('refuses a redirect off the allowlist, loopback included while the param is off', async () => {
    for (const redirect of [
      'https://evil.example/callback',
      'http://localhost:33418/callback',
      'https://claude.ai/api/mcp/auth_callback?x=1',
    ]) {
      const answer = await postJson('/oauth/register', { redirect_uris: [redirect] });
      expect(answer.status, redirect).toBe(400);
      expect(answer.body['error']).toBe('invalid_redirect_uri');
    }
    const mixed = await postJson('/oauth/register', {
      redirect_uris: [CLAUDE_CALLBACK, CHATGPT_CALLBACK],
    });
    expect(mixed.body['error']).toBe('invalid_redirect_uri');
  });

  it('refuses a confidential client and a body that is not a registration', async () => {
    const secret = await postJson('/oauth/register', {
      redirect_uris: [CHATGPT_CALLBACK],
      token_endpoint_auth_method: 'client_secret_basic',
    });
    expect(secret.body['error']).toBe('invalid_client_metadata');
    expect((await postJson('/oauth/register', { client_name: 'x' })).status).toBe(400);
  });
});

describe('authorize — a client or redirect it cannot trust gets a page, never a redirect', () => {
  async function expectPage(clientId: string, redirectUri = CLAUDE_CALLBACK): Promise<void> {
    const answer = await authorize({ clientId, redirectUri });
    expect(answer.status, clientId).toBe(400);
    expect(answer.location).toBeNull();
    expect(answer.cookie).toBeNull();
    expect(answer.html).toContain('can’t connect to nestprep');
  }

  it('an unknown client id', async () => {
    await expectPage('npc_not-registered');
  });

  it('a redirect the client did not register, even one on the allowlist', async () => {
    await expectPage(claude.clientId, 'https://claude.com/api/mcp/auth_callback');
  });

  it('a registered redirect that is not on the allowlist', async () => {
    const evil = await serveClientDocument(claudeDocument('https://evil.example/callback'));
    await expectPage(evil.clientId, 'https://evil.example/callback');
    await evil.close();
  });

  it('a metadata document whose client_id is not its own address', async () => {
    const liar = await serveClientDocument(() => ({
      client_id: 'https://claude.ai/oauth/client.json',
      client_name: 'Claude',
      redirect_uris: [CLAUDE_CALLBACK],
    }));
    await expectPage(liar.clientId);
    await liar.close();
  });

  it('a metadata document on a private address, escape or not', async () => {
    await expectPage('https://10.0.0.1/client.json');
    await expectPage('https://169.254.169.254/latest/client.json');
  });

  it('a metadata document on this machine once the emulator escape is off', async () => {
    await allowLocalClientDocuments(false);
    await expectPage(claude.clientId);
  });
});

describe('authorize — after the redirect is trusted, errors go back to it with state and iss', () => {
  async function expectError(
    params: Parameters<typeof authorize>[0],
    error: string,
    state: string | null = 'state-1',
  ): Promise<void> {
    const answer = await authorize(params);
    expect(answer.status).toBe(302);
    expect(`${answer.location?.origin ?? ''}${answer.location?.pathname ?? ''}`).toBe(
      CLAUDE_CALLBACK,
    );
    expect(answer.location?.searchParams.get('error')).toBe(error);
    expect(answer.location?.searchParams.get('state')).toBe(state);
    expect(answer.location?.searchParams.get('iss')).toBe(ISSUER);
    expect(answer.cookie).toBeNull();
  }

  it('PKCE missing', async () => {
    await expectError({ clientId: claude.clientId, pkce: null }, 'invalid_request');
  });

  it('PKCE plain', async () => {
    await expectError({ clientId: claude.clientId, method: 'plain' }, 'invalid_request');
  });

  it('the wrong resource, or none', async () => {
    await expectError(
      { clientId: claude.clientId, resource: 'https://evil.example/mcp' },
      'invalid_target',
    );
    await expectError({ clientId: claude.clientId, resource: null }, 'invalid_target');
  });

  it('no state', async () => {
    await expectError({ clientId: claude.clientId, state: null }, 'invalid_request', null);
  });

  it('a response type other than code', async () => {
    await expectError(
      { clientId: claude.clientId, responseType: 'token' },
      'unsupported_response_type',
    );
  });
});

describe('consent — only for the browser that started it, and only for family', () => {
  let h: Household;

  beforeEach(async () => {
    h = await samsHousehold();
  });

  it('is nothing to a browser without the cookie, or with another one', async () => {
    const authorized = await authorize({ clientId: claude.clientId });
    const requestId = authorized.requestId ?? '';
    expect((await postJson('/oauth/consent/describe', { requestId })).body).toEqual({
      error: 'requestNotFound',
    });
    const other = `__session=${'x'.repeat(43)}`;
    expect((await postJson('/oauth/consent/describe', { requestId }, other)).status).toBe(404);
    const decided = await postJson(
      '/oauth/consent/decide',
      {
        requestId,
        idToken: h.sam.idToken,
        decision: 'allow',
        householdId: h.householdId,
        scopes: ['calendar:read'],
      },
      other,
    );
    expect(decided.status).toBe(404);
    expect((await grantsIn(h.householdId)).size).toBe(0);
  });

  it('is gone once the request expires', async () => {
    const authorized = await authorize({ clientId: claude.clientId });
    await adminDb()
      .collection('assistantAuthRequests')
      .doc(authorized.requestId ?? '')
      .update({ expiresAt: Timestamp.fromMillis(Date.now() - 1000) });
    const answer = await postJson(
      '/oauth/consent/describe',
      { requestId: authorized.requestId },
      authorized.cookie ?? '',
    );
    expect(answer.body['error']).toBe('requestNotFound');
  });

  async function decideAs(
    idToken: string,
    householdId: string,
    scopes: string[] = ['calendar:read'],
    scope?: string,
  ): Promise<{ status: number; error: unknown }> {
    const authorized = await authorize({
      clientId: claude.clientId,
      ...(scope === undefined ? {} : { scope }),
    });
    const answer = await postJson(
      '/oauth/consent/decide',
      { requestId: authorized.requestId, idToken, decision: 'allow', householdId, scopes },
      authorized.cookie ?? '',
    );
    return { status: answer.status, error: answer.body['error'] };
  }

  it('refuses a sign-in older than five minutes', async () => {
    await fetch(
      `http://${process.env['FIREBASE_AUTH_EMULATOR_HOST'] ?? '127.0.0.1:9099'}/identitytoolkit.googleapis.com/v1/accounts:update`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: 'Bearer owner' },
        body: JSON.stringify({
          localId: h.sam.uid,
          validSince: String(Math.floor(Date.now() / 1000) - 3600),
          targetProjectId: 'nestprep-643b7',
        }),
      },
    );
    const fresh = idTokenSignedInAgo(h.sam.uid, 1);
    const stale = idTokenSignedInAgo(h.sam.uid, 6);
    expect(await decideAs(stale, h.householdId)).toEqual({ status: 401, error: 'staleSignIn' });
    expect((await decideAs(fresh, h.householdId)).status).toBe(200);
  });

  it('refuses a token that is not a Firebase ID token', async () => {
    expect(await decideAs('not-a-token', h.householdId)).toEqual({
      status: 401,
      error: 'signInRequired',
    });
  });

  it('refuses a kid device’s sign-in', async () => {
    const tablet = await pairKidDevice(
      h.sam,
      h.householdId,
      await addProfile(h.householdId, 'Mia', 'kid'),
    );
    expect(await decideAs(tablet.idToken, h.householdId)).toEqual({
      status: 401,
      error: 'kidAccount',
    });
  });

  it('lists only households where the member is family, and refuses a helper or carer', async () => {
    for (const role of ['helper', 'carer']) {
      const person = await joinAs(
        h.sam,
        h.householdId,
        await addProfile(h.householdId, role, role),
      );
      const authorized = await authorize({ clientId: claude.clientId });
      const listed = await postJson(
        '/oauth/consent/households',
        { requestId: authorized.requestId, idToken: person.idToken },
        authorized.cookie ?? '',
      );
      expect(listed.body, role).toEqual({ households: [] });
      expect(await decideAs(person.idToken, h.householdId), role).toEqual({
        status: 403,
        error: 'familyOnly',
      });
    }
  });

  it('refuses a household the member is not in', async () => {
    const stranger = await signUp();
    expect(await decideAs(stranger.idToken, h.householdId)).toEqual({
      status: 403,
      error: 'notAMember',
    });
  });

  it('refuses family with no claimed profile', async () => {
    const pat = await signUp();
    await household(h.householdId).update({ [`members.${pat.uid}`]: 'parent' });
    expect(await decideAs(pat.idToken, h.householdId)).toEqual({ status: 403, error: 'noProfile' });
  });

  it('refuses while the flag is off, the kill switch is thrown, or the household said no', async () => {
    await adminDb().collection('appConfig').doc('flags').set({ assistants: false });
    expect(await decideAs(h.sam.idToken, h.householdId)).toEqual({
      status: 503,
      error: 'switchedOff',
    });
    const authorized = await authorize({ clientId: claude.clientId });
    const described = await postJson(
      '/oauth/consent/describe',
      { requestId: authorized.requestId },
      authorized.cookie ?? '',
    );
    expect(described.body['error']).toBe('switchedOff');

    await adminDb().collection('appConfig').doc('flags').set({ assistants: true });
    await adminDb().collection('appConfig').doc('assistants').set({ enabled: false });
    expect(await decideAs(h.sam.idToken, h.householdId)).toEqual({
      status: 503,
      error: 'switchedOff',
    });

    await adminDb().collection('appConfig').doc('assistants').set({ enabled: true });
    await household(h.householdId)
      .collection('assistantSettings')
      .doc('current')
      .set({ allowed: false, updatedBy: h.samMemberId, updatedAt: new Date() });
    expect(await decideAs(h.sam.idToken, h.householdId)).toEqual({
      status: 403,
      error: 'householdSwitchedOff',
    });
    expect((await grantsIn(h.householdId)).size).toBe(0);
  });

  it('refuses scopes the assistant did not ask for', async () => {
    expect(await decideAs(h.sam.idToken, h.householdId, ['lists:write'], 'calendar:read')).toEqual({
      status: 400,
      error: 'invalidScopes',
    });
  });

  it('"Not now" sends the browser back with access_denied, and spends the request', async () => {
    const authorized = await authorize({ clientId: claude.clientId });
    const denied = await postJson(
      '/oauth/consent/decide',
      { requestId: authorized.requestId, decision: 'deny' },
      authorized.cookie ?? '',
    );
    const redirect = new URL(String(denied.body['redirect']));
    expect(redirect.searchParams.get('error')).toBe('access_denied');
    expect(redirect.searchParams.get('state')).toBe('state-1');
    expect(redirect.searchParams.get('iss')).toBe(ISSUER);
    const again = await postJson(
      '/oauth/consent/describe',
      { requestId: authorized.requestId },
      authorized.cookie ?? '',
    );
    expect(again.status).toBe(404);
  });
});

describe('the token endpoint', () => {
  let h: Household;

  beforeEach(async () => {
    h = await samsHousehold();
  });

  async function codeFor(): Promise<{ code: string; verifier: string }> {
    const pkce = newPkce();
    const { code } = await consent(
      await authorize({ clientId: claude.clientId, pkce }),
      h.sam,
      h.householdId,
    );
    return { code, verifier: pkce.verifier };
  }

  it('a wrong verifier is refused, and burns the code', async () => {
    const { code, verifier } = await codeFor();
    const wrong = await redeem(claude.clientId, code, newPkce().verifier);
    expect(wrong.body['error']).toBe('invalid_grant');
    expect((await redeem(claude.clientId, code, verifier)).body['error']).toBe('invalid_grant');
    expect((await grantsIn(h.householdId)).size).toBe(0);
  });

  it('a missing verifier is refused', async () => {
    const { code } = await codeFor();
    const answer = await postForm('/oauth/token', {
      grant_type: 'authorization_code',
      code,
      client_id: claude.clientId,
      redirect_uri: CLAUDE_CALLBACK,
    });
    expect(answer.body['error']).toBe('invalid_grant');
  });

  it('a code works once, and presented again ends the connection it made', async () => {
    const { code, verifier } = await codeFor();
    const tokens = tokensOf(await redeem(claude.clientId, code, verifier));
    const grantId = (await onlyGrant(h.householdId)).id;
    const kept = await adminDb().collection('assistantCodes').doc(sha256Hex(code)).get();
    expect(kept.get('grantId')).toBe(grantId);
    expect(kept.get('redeemedAt')).toBeInstanceOf(Timestamp);

    expect((await redeem(claude.clientId, code, verifier)).body['error']).toBe('invalid_grant');
    expect((await grantsIn(h.householdId)).size).toBe(0);
    expect(await tokensFor(grantId)).toBe(0);
    expect(await refusalOf(authenticate(`Bearer ${tokens.access}`))).toBe('invalidToken:unknown');
    expect((await refresh(claude.clientId, tokens.refresh)).body['error']).toBe('invalid_grant');
  });

  it('an expired code is refused', async () => {
    const { code, verifier } = await codeFor();
    await adminDb()
      .collection('assistantCodes')
      .doc(sha256Hex(code))
      .update({ expiresAt: Timestamp.fromMillis(Date.now() - 1000) });
    expect((await redeem(claude.clientId, code, verifier)).body['error']).toBe('invalid_grant');
  });

  it('a code for another redirect, another client or another resource is refused', async () => {
    for (const overrides of [
      { redirect_uri: 'https://claude.com/api/mcp/auth_callback' },
      { client_id: 'npc_someone-else' },
    ]) {
      const { code, verifier } = await codeFor();
      const answer = await redeem(claude.clientId, code, verifier, overrides);
      expect(answer.body['error'], JSON.stringify(overrides)).toBe('invalid_grant');
    }
    const { code, verifier } = await codeFor();
    const wrongResource = await redeem(claude.clientId, code, verifier, {
      resource: 'https://evil.example/mcp',
    });
    expect(wrongResource.body['error']).toBe('invalid_target');
  });

  it('a code whose member stopped being family before it was redeemed makes no connection', async () => {
    const { code, verifier } = await codeFor();
    await adminDb()
      .collection('households')
      .doc(h.householdId)
      .update({ [`members.${h.sam.uid}`]: 'helper' });
    expect((await redeem(claude.clientId, code, verifier)).body['error']).toBe('invalid_grant');
    expect((await grantsIn(h.householdId)).size).toBe(0);
  });

  describe('a spent refresh token presented again', () => {
    const rotatedAt = new Date();
    const tokenKey = Buffer.alloc(32, 3);

    async function refreshAt(
      secondsAfterRotation: number,
      refreshToken: string,
      resource = RESOURCE,
    ): Promise<{ status: number; body: Record<string, unknown> }> {
      const reply = await exchangeToken(
        {
          store: adminDb(),
          server: { issuer: new URL(resource).origin, resource, allowLoopbackRedirects: false },
          now: new Date(rotatedAt.getTime() + secondsAfterRotation * 1000),
          tokenKey: () => tokenKey,
        },
        { grant_type: 'refresh_token', refresh_token: refreshToken, client_id: claude.clientId },
      );
      if (reply.kind !== 'json') throw new Error(`token endpoint answered ${reply.kind}`);
      return { status: reply.status, body: { ...reply.body } };
    }

    it('within a minute of its rotation is a retry: the very same pair, and no second chain', async () => {
      const first = await connectAs(claude.clientId, h.sam, h.householdId);
      const rotated = await refreshAt(0, first.refresh);
      expect(rotated.status).toBe(200);
      const retried = await refreshAt(REFRESH_REUSE_GRACE_MS / 1000 - 1, first.refresh);
      expect(retried.status, JSON.stringify(retried.body)).toBe(200);
      expect(retried.body['access_token']).toBe(rotated.body['access_token']);
      expect(retried.body['refresh_token']).toBe(rotated.body['refresh_token']);
      expect(retried.body['expires_in']).toBe(3600 - (REFRESH_REUSE_GRACE_MS / 1000 - 1));
      expect((await onlyGrant(h.householdId)).get('refreshGeneration')).toBe(1);
      expect(
        (await adminDb().collection('assistantTokens').where('kind', '==', 'refresh').get()).size,
      ).toBe(2);
      expect((await authenticate(`Bearer ${String(rotated.body['access_token'])}`)).uid).toBe(
        h.sam.uid,
      );
    });

    it('keeps the pair sealed, and wipes it once that pair is rotated in turn', async () => {
      const first = await connectAs(claude.clientId, h.sam, h.householdId);
      const rotated = await refreshAt(0, first.refresh);
      const spent = adminDb().collection('assistantTokens').doc(sha256Hex(first.refresh));
      const sealed = JSON.stringify((await spent.get()).get('successor'));
      expect(sealed).toMatch(/"sealed":"v1\./);
      expect(sealed).not.toContain(String(rotated.body['access_token']));
      expect(sealed).not.toContain(String(rotated.body['refresh_token']));
      expect((await refreshAt(10, String(rotated.body['refresh_token']))).status).toBe(200);
      expect((await spent.get()).get('successor')).toBeNull();
    });

    it('after that minute is theft: the grant and every token it issued go', async () => {
      const first = await connectAs(claude.clientId, h.sam, h.householdId);
      const grantId = (await onlyGrant(h.householdId)).id;
      const rotated = await refreshAt(0, first.refresh);
      const reused = await refreshAt(REFRESH_REUSE_GRACE_MS / 1000 + 1, first.refresh);
      expect(reused.body['error']).toBe('invalid_grant');
      expect((await grantsIn(h.householdId)).size).toBe(0);
      expect(await tokensFor(grantId)).toBe(0);
      expect(await refusalOf(authenticate(`Bearer ${String(rotated.body['access_token'])}`))).toBe(
        'invalidToken:unknown',
      );
      expect((await refresh(claude.clientId, String(rotated.body['refresh_token']))).status).toBe(
        400,
      );
    });

    it('once its successor has itself been rotated is theft, even inside the minute', async () => {
      const first = await connectAs(claude.clientId, h.sam, h.householdId);
      const rotated = await refreshAt(0, first.refresh);
      expect((await refreshAt(10, String(rotated.body['refresh_token']))).status).toBe(200);
      expect((await refreshAt(20, first.refresh)).body['error']).toBe('invalid_grant');
      expect((await grantsIn(h.householdId)).size).toBe(0);
    });

    it('by two refreshes racing over HTTP: both get the same pair, and the connection stays', async () => {
      const first = await connectAs(claude.clientId, h.sam, h.householdId);
      const answers = await Promise.all([
        refresh(claude.clientId, first.refresh),
        refresh(claude.clientId, first.refresh),
      ]);
      const [one, two] = answers.map(tokensOf);
      expect(one?.refresh).toBe(two?.refresh);
      expect(one?.access).toBe(two?.access);
      expect((await onlyGrant(h.householdId)).get('refreshGeneration')).toBe(1);
    });

    it('minted for another origin is refused, at refresh as at the MCP endpoint', async () => {
      const tokens = await connectAs(claude.clientId, h.sam, h.householdId);
      const stored = await adminDb()
        .collection('assistantTokens')
        .doc(sha256Hex(tokens.access))
        .get();
      expect(stored.get('resource')).toBe(RESOURCE);
      const moved = 'https://mcp.nestprep.io/mcp';
      expect(
        await refusalOf(
          bearerAuthenticator(adminDb(), moved)(`Bearer ${tokens.access}`, new Date()),
        ),
      ).toBe('invalidToken:otherResource');
      expect((await refreshAt(0, tokens.refresh, moved)).body['error']).toBe('invalid_grant');
      expect((await authenticate(`Bearer ${tokens.access}`)).uid).toBe(h.sam.uid);
      expect((await refreshAt(0, tokens.refresh)).status).toBe(200);
    });
  });

  describe('is counted per client and grant, never per address', () => {
    it('one grant over its limit is refused while another grant refreshes, from the same address', async () => {
      const one = await connectAs(claude.clientId, h.sam, h.householdId);
      const oneGrant = (await onlyGrant(h.householdId)).id;
      const two = await connectAs(claude.clientId, h.sam, h.householdId);
      await atCount(TOKEN_PER_GRANT, tokenRateSubject(claude.clientId, oneGrant));
      expect((await refresh(claude.clientId, one.refresh)).status).toBe(429);
      tokensOf(await refresh(claude.clientId, two.refresh));
    });

    it('and an overall ceiling no client or grant changes', async () => {
      const tokens = await connectAs(claude.clientId, h.sam, h.householdId);
      await atCount(TOKEN_OVERALL, 'all');
      expect((await refresh(claude.clientId, tokens.refresh)).status).toBe(429);
    });
  });

  it('an expired refresh token, or one for another client, is refused', async () => {
    const tokens = await connectAs(claude.clientId, h.sam, h.householdId);
    expect((await refresh('npc_someone-else', tokens.refresh)).body['error']).toBe('invalid_grant');
    await adminDb()
      .collection('assistantTokens')
      .doc(sha256Hex(tokens.refresh))
      .update({ expiresAt: Timestamp.fromMillis(Date.now() - 1000) });
    expect((await refresh(claude.clientId, tokens.refresh)).body['error']).toBe('invalid_grant');
  });

  it('an access token is not a refresh token, and other grant types are unsupported', async () => {
    const tokens = await connectAs(claude.clientId, h.sam, h.householdId);
    expect((await refresh(claude.clientId, tokens.access)).body['error']).toBe('invalid_grant');
    const password = await postForm('/oauth/token', { grant_type: 'password' });
    expect(password.body['error']).toBe('unsupported_grant_type');
    expect((await postForm('/oauth/token', {})).body['error']).toBe('invalid_request');
  });

  it('accepts JSON as well as a form', async () => {
    const { code, verifier } = await codeFor();
    const answer = await postJson('/oauth/token', {
      grant_type: 'authorization_code',
      code,
      client_id: claude.clientId,
      redirect_uri: CLAUDE_CALLBACK,
      code_verifier: verifier,
    });
    expect(answer.headers.get('cache-control')).toBe('no-store');
    expect(tokensOf(answer).access).toMatch(/^npa_/);
  });
});

describe('revoke', () => {
  it('an access token ends alone; a refresh token disconnects; always 200', async () => {
    const h = await samsHousehold();
    const tokens = await connectAs(claude.clientId, h.sam, h.householdId);
    expect((await postForm('/oauth/revoke', { token: 'npa_unknown' })).status).toBe(200);
    expect(
      (await postForm('/oauth/revoke', { token: tokens.access, client_id: 'npc_other' })).status,
    ).toBe(200);
    expect((await authenticate(`Bearer ${tokens.access}`)).uid).toBe(h.sam.uid);

    await postForm('/oauth/revoke', { token: tokens.access });
    expect(await refusalOf(authenticate(`Bearer ${tokens.access}`))).toBe('invalidToken:unknown');
    expect((await grantsIn(h.householdId)).size).toBe(1);

    await postForm('/oauth/revoke', { token: tokens.refresh, token_type_hint: 'refresh_token' });
    expect((await grantsIn(h.householdId)).size).toBe(0);
  });
});

describe('authenticateBearer', () => {
  let h: Household;

  beforeEach(async () => {
    h = await samsHousehold();
  });

  it('never accepts a Firebase ID token, a refresh token or anything malformed', async () => {
    const tokens = await connectAs(claude.clientId, h.sam, h.householdId);
    expect(await refusalOf(authenticate(`Bearer ${h.sam.idToken}`))).toBe('invalidToken:malformed');
    expect(await refusalOf(authenticate(`Bearer ${tokens.refresh}`))).toBe(
      'invalidToken:malformed',
    );
    expect(await refusalOf(authenticate(tokens.access))).toBe('invalidToken:malformed');
    expect(await refusalOf(bearerAuthenticator(adminDb())(undefined, new Date()))).toBe(
      'invalidToken:malformed',
    );
    expect(await refusalOf(authenticate(`Bearer npa_${'A'.repeat(43)}`))).toBe(
      'invalidToken:unknown',
    );
  });

  it('refuses an expired access token, and deletes it', async () => {
    const tokens = await connectAs(claude.clientId, h.sam, h.householdId);
    const ref = adminDb().collection('assistantTokens').doc(sha256Hex(tokens.access));
    await ref.update({ expiresAt: Timestamp.fromMillis(Date.now() - 1000) });
    expect(await refusalOf(authenticate(`Bearer ${tokens.access}`))).toBe('invalidToken:expired');
    expect((await ref.get()).exists).toBe(false);
  });

  it('refuses once the grant is disconnected in the app, and cleans the token up', async () => {
    const tokens = await connectAs(claude.clientId, h.sam, h.householdId);
    await (await onlyGrant(h.householdId)).ref.delete();
    expect(await refusalOf(authenticate(`Bearer ${tokens.access}`))).toBe('invalidToken:grantGone');
    const ref = adminDb().collection('assistantTokens').doc(sha256Hex(tokens.access));
    expect((await ref.get()).exists).toBe(false);
  });

  it('notes when the connection was last used, at most every fifteen minutes', async () => {
    const tokens = await connectAs(claude.clientId, h.sam, h.householdId);
    await authenticate(`Bearer ${tokens.access}`);
    const first = (await onlyGrant(h.householdId)).get('lastUsedAt') as Timestamp;
    expect(first).toBeInstanceOf(Timestamp);
    await authenticate(`Bearer ${tokens.access}`);
    expect(((await onlyGrant(h.householdId)).get('lastUsedAt') as Timestamp).isEqual(first)).toBe(
      true,
    );
  });

  it('allows 300 calls an hour per connection', async () => {
    const tokens = await connectAs(claude.clientId, h.sam, h.householdId);
    const grantId = (await onlyGrant(h.householdId)).id;
    await adminDb()
      .collection('rateLimits')
      .doc(rateLimitId(CALLS_PER_GRANT, grantId))
      .set({
        rule: CALLS_PER_GRANT.name,
        windowStart: Timestamp.now(),
        count: CALLS_PER_GRANT.limit,
        expiresAt: Timestamp.fromMillis(Date.now() + 3_600_000),
      });
    expect(await refusalOf(authenticate(`Bearer ${tokens.access}`))).toBe(
      'rateLimited:callsPerHour',
    );
  });
});

describe('the browser’s endpoints are counted by the hop Google appended, under overall ceilings', () => {
  const authorizeFrom = (forwardedFor: string): Promise<Response> =>
    fetch(`${AUTH}/oauth/authorize`, {
      redirect: 'manual',
      headers: { 'X-Forwarded-For': forwardedFor },
    });

  it('a caller who writes a new first hop each time is still one address', async () => {
    const statuses: number[] = [];
    for (let attempt = 0; attempt <= AUTHORIZE_PER_ADDRESS.limit; attempt += 1) {
      statuses.push(
        (await authorizeFrom(`10.0.0.${String(attempt)}, 198.51.100.9, 66.249.2.193`)).status,
      );
    }
    expect(statuses.slice(0, -1).every((status) => status === 400)).toBe(true);
    expect(statuses.at(-1)).toBe(429);
    expect((await authorizeFrom('198.51.100.10')).status).toBe(400);
  });

  it('authorize and consent stop for everybody at their overall ceilings', async () => {
    await atCount(AUTHORIZE_OVERALL, 'all');
    expect((await authorizeFrom('198.51.100.11')).status).toBe(429);
    await atCount(CONSENT_OVERALL, 'all');
    expect((await postJson('/oauth/consent/describe', { requestId: 'x' })).status).toBe(429);
  });

  it('registration has room for Claude registering once per connection', async () => {
    await atCount(REGISTER_OVERALL, 'all', 500);
    expect(await registerChatGpt()).toMatch(/^npc_/);
    await atCount(REGISTER_OVERALL, 'all');
    const refused = await postJson('/oauth/register', {
      client_name: 'ChatGPT',
      redirect_uris: [CHATGPT_CALLBACK],
    });
    expect(refused.status).toBe(429);
  });
});
