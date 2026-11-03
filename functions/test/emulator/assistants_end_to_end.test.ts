import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import {
  Client,
  StreamableHTTPClientTransport,
  UnauthorizedError,
  discoverAuthorizationServerMetadata,
  discoverOAuthProtectedResourceMetadata,
  exchangeAuthorization,
  extractWWWAuthenticateParams,
  refreshAuthorization,
  startAuthorization,
  type AuthorizationServerMetadata,
  type OAuthTokens,
} from '@modelcontextprotocol/client';
import { Timestamp } from 'firebase-admin/firestore';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { z } from 'zod';

import { EVENT_KEYS } from '../../src/assistants/mcp/event_documents';
import { GROCERY_ITEM_KEYS } from '../../src/assistants/mcp/grocery_documents';
import { addProfile, household, joinAs, samsHousehold } from './account_data_fixture';
import {
  CLAUDE_CALLBACK,
  ISSUER,
  RESOURCE,
  type ClientDocumentServer,
  allowLocalClientDocuments,
  claudeDocument,
  serveClientDocument,
} from './assistants_fixture';
import {
  PROJECT_ID,
  clearFirestore,
  closeAdmin,
  httpFunctionUrl,
  type TestUser,
} from './emulator_harness';

/**
 * NestPrep in Claude, end to end (assistants ADR-0001 to ADR-0005): what
 * Claude does when a member adds the connector and then asks it to put an
 * invitation on the calendar and the taco things on the list. Every request
 * is addressed to the public origin and reaches the emulator through
 * `firebase.json`'s own Hosting rewrites, so the issuer, the resource and the
 * routing are the ones members get. Discovery, authorization, the token
 * exchange, the refresh and the MCP calls are the official MCP client SDK's;
 * the consent page's calls are what `connect.js` sends, with a real
 * Auth-emulator ID token; the disconnect is the app's, through the rules.
 * Nothing reaches into Firestore to sign anybody in.
 */

const ROOT = resolve(import.meta.dirname, '../../..');
const FIRESTORE = process.env['FIRESTORE_EMULATOR_HOST'] ?? '127.0.0.1:8080';

const hostingRewrites = z
  .object({
    hosting: z.object({
      rewrites: z.array(
        z.object({
          source: z.string(),
          function: z.object({ functionId: z.string(), region: z.string() }).optional(),
        }),
      ),
    }),
  })
  .parse(JSON.parse(readFileSync(resolve(ROOT, 'firebase.json'), 'utf8'))).hosting.rewrites;

function globToRegExp(glob: string): RegExp {
  const pattern = glob
    .split('**')
    .map((part) =>
      part
        .split('*')
        .map((piece) => piece.replace(/[.+?^${}()|[\]\\]/g, '\\$&'))
        .join('[^/]*'),
    )
    .join('.*');
  return new RegExp(`^${pattern}$`);
}

/** Where Hosting would send a request for [url]: the Function its first matching rewrite names. */
function throughHosting(url: string): string {
  const target = new URL(url);
  expect(target.origin, url).toBe(ISSUER);
  const rewrite = hostingRewrites.find(
    (candidate) =>
      candidate.function !== undefined && globToRegExp(candidate.source).test(target.pathname),
  );
  if (rewrite?.function === undefined) throw new Error(`Hosting serves ${target.pathname} itself`);
  return `${httpFunctionUrl(rewrite.function.functionId, rewrite.function.region)}${target.pathname}${target.search}`;
}

/** A browser, as far as these calls need one: Hosting in front, and the `__session` cookie it was given. */
class Browser {
  session: string | null = null;
  sessionPath: string | null = null;

  readonly fetch = async (input: string | URL, init: RequestInit = {}): Promise<Response> => {
    const url = input.toString();
    const headers = new Headers(init.headers);
    if (this.session !== null && new URL(url).pathname.startsWith(this.sessionPath ?? '/')) {
      headers.set('Cookie', `__session=${this.session}`);
    }
    const response = await fetch(throughHosting(url), { ...init, headers, redirect: 'manual' });
    const setCookie = response.headers.get('set-cookie');
    if (setCookie !== null) {
      const [pair = '', ...attributes] = setCookie.split(';').map((part) => part.trim());
      expect(pair).toMatch(/^__session=[A-Za-z0-9_-]{43}$/);
      expect(attributes).toEqual(
        expect.arrayContaining(['Path=/oauth', 'Secure', 'HttpOnly', 'SameSite=Lax']),
      );
      this.session = pair.slice('__session='.length);
      this.sessionPath = '/oauth';
    }
    return response;
  };
}

/** An assistant's server: no cookies, no browser, only Hosting in front. */
const serverFetch = (input: string | URL, init?: RequestInit): Promise<Response> =>
  fetch(throughHosting(input.toString()), init);

async function consentCall(
  browser: Browser,
  action: 'describe' | 'households' | 'decide',
  body: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const response = await browser.fetch(`${ISSUER}/oauth/consent/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const answer: unknown = await response.json();
  expect(response.status, JSON.stringify(answer)).toBe(200);
  return z.record(z.string(), z.unknown()).parse(answer);
}

async function mcpClient(token: string, pinned: boolean): Promise<Client> {
  const client = new Client(
    { name: 'claude-ai', version: '1.0.0' },
    pinned ? { versionNegotiation: { mode: { pin: '2026-07-28' } } } : {},
  );
  await client.connect(
    new StreamableHTTPClientTransport(new URL(RESOURCE), {
      authProvider: { token: (): Promise<string> => Promise.resolve(token) },
      fetch: serverFetch,
    }),
  );
  return client;
}

async function structured(
  client: Client,
  name: string,
  args: Record<string, unknown> = {},
): Promise<Record<string, unknown>> {
  const result = await client.callTool({ name, arguments: args });
  expect(result.isError ?? false, JSON.stringify(result.content)).toBe(false);
  return z.record(z.string(), z.unknown()).parse(result.structuredContent);
}

function daysAfter(day: string, days: number): string {
  const date = new Date(`${day}T00:00:00Z`);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

/** A Firestore REST call as the app's signed-in member makes it, so the rules decide. */
function asMember(user: TestUser, path: string, init: RequestInit = {}): Promise<Response> {
  return fetch(
    `http://${FIRESTORE}/v1/projects/${PROJECT_ID}/databases/(default)/documents/${path}`,
    {
      ...init,
      headers: {
        ...Object.fromEntries(new Headers(init.headers)),
        Authorization: `Bearer ${user.idToken}`,
      },
    },
  );
}

const householdAnswer = z.object({
  household: z.object({ id: z.string(), name: z.string(), today: z.string() }),
  you: z.object({ member_id: z.string() }),
  members: z.array(z.object({ id: z.string(), first_name: z.string(), kind: z.string() })),
  connection: z.object({ assistant: z.string(), may: z.array(z.string()) }),
});

const listed = z.object({
  documents: z.array(z.object({ name: z.string() })).default([]),
});

let claude: ClientDocumentServer;

beforeAll(async () => {
  await clearFirestore();
  await allowLocalClientDocuments(true);
  claude = await serveClientDocument(claudeDocument());
});

afterAll(async () => {
  await claude.close();
  await closeAdmin();
});

describe('a parent connects Claude, and Claude does what the parent asked', () => {
  it('discovers, signs in, consents, calls the tools, refreshes, and is disconnected by the app', async () => {
    const h = await samsHousehold();
    const patMemberId = await addProfile(h.householdId, 'Pat Parker', 'parent');
    const emmaMemberId = await addProfile(h.householdId, 'Emma Parker', 'kid');
    const pat = await joinAs(h.sam, h.householdId, patMemberId);
    await household(h.householdId).collection('groceryItems').doc('milk').set({
      name: 'Milk',
      quantity: '2 L',
      addedBy: h.samMemberId,
      addedAt: Timestamp.now(),
      boughtAt: null,
      boughtBy: null,
      sourceKey: null,
      sourceWeek: null,
      sourceNote: null,
    });

    const unauthenticated = await serverFetch(RESOURCE, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'tools/list' }),
    });
    expect(unauthenticated.status).toBe(401);
    const challenge = extractWWWAuthenticateParams(unauthenticated);
    expect(challenge.resourceMetadataUrl?.toString()).toBe(
      `${ISSUER}/.well-known/oauth-protected-resource/mcp`,
    );
    expect(challenge.scope).toBe(
      'household:read calendar:read calendar:write lists:read lists:write',
    );

    const resource = await discoverOAuthProtectedResourceMetadata(
      RESOURCE,
      { resourceMetadataUrl: challenge.resourceMetadataUrl ?? '' },
      serverFetch,
    );
    expect(resource.resource).toBe(RESOURCE);
    const [issuer] = resource.authorization_servers ?? [];
    expect(issuer).toBe(ISSUER);
    const metadata: AuthorizationServerMetadata | undefined =
      await discoverAuthorizationServerMetadata(issuer ?? '', { fetchFn: serverFetch });
    if (metadata === undefined) throw new Error('no authorization server metadata');
    expect(metadata.client_id_metadata_document_supported).toBe(true);
    expect(metadata.code_challenge_methods_supported).toEqual(['S256']);

    const clientInformation = { client_id: claude.clientId };
    const scope = (resource.scopes_supported ?? []).join(' ');
    const { authorizationUrl, codeVerifier } = await startAuthorization(issuer ?? '', {
      metadata,
      clientInformation,
      redirectUrl: CLAUDE_CALLBACK,
      scope,
      state: 'claude-state-7',
      resource: RESOURCE,
    });
    expect(authorizationUrl.searchParams.get('code_challenge_method')).toBe('S256');

    const browser = new Browser();
    const toConsent = await browser.fetch(authorizationUrl);
    expect(toConsent.status).toBe(302);
    const consentPage = new URL(toConsent.headers.get('location') ?? '');
    expect(`${consentPage.origin}${consentPage.pathname}`).toBe(`${ISSUER}/connect`);
    expect(existsSync(resolve(ROOT, 'hosting/public/connect/index.html'))).toBe(true);
    expect(browser.session).not.toBeNull();
    const requestId = consentPage.searchParams.get('request') ?? '';

    expect(await consentCall(browser, 'describe', { requestId })).toEqual({
      clientName: 'Claude',
      host: new URL(claude.clientId).host,
      via: 'claude',
      scopes: scope.split(' '),
    });
    expect(await consentCall(browser, 'households', { requestId, idToken: pat.idToken })).toEqual({
      households: [{ id: h.householdId, name: 'The Parkers' }],
    });
    const decided = await consentCall(browser, 'decide', {
      requestId,
      idToken: pat.idToken,
      decision: 'allow',
      householdId: h.householdId,
      scopes: scope.split(' '),
    });
    const callback = new URL(z.string().parse(decided['redirect']));
    expect(`${callback.origin}${callback.pathname}`).toBe(CLAUDE_CALLBACK);
    expect(callback.searchParams.get('state')).toBe('claude-state-7');

    const tokens: OAuthTokens = await exchangeAuthorization(issuer ?? '', {
      metadata,
      clientInformation,
      authorizationCode: callback.searchParams.get('code') ?? '',
      iss: callback.searchParams.get('iss') ?? '',
      codeVerifier,
      redirectUri: CLAUDE_CALLBACK,
      resource: RESOURCE,
      fetchFn: serverFetch,
    });
    expect(tokens.token_type).toBe('Bearer');
    expect(tokens.scope).toBe(scope);

    const assistant = await mcpClient(tokens.access_token, true);
    expect(assistant.getNegotiatedProtocolVersion()).toBe('2026-07-28');
    const tools = await assistant.listTools();
    expect(tools.tools.map((tool) => tool.name)).toEqual([
      'get_household',
      'list_events',
      'create_event',
      'update_event',
      'delete_event',
      'get_grocery_list',
      'add_grocery_items',
      'update_grocery_item',
      'tick_grocery_items',
      'remove_grocery_items',
    ]);

    const home = householdAnswer.parse(await structured(assistant, 'get_household'));
    expect(home.you.member_id).toBe(patMemberId);
    expect(home.connection).toEqual({ assistant: 'claude', may: scope.split(' ') });
    const emma = home.members.find((member) => member.first_name === 'Emma');
    expect(emma).toEqual({ id: emmaMemberId, first_name: 'Emma', kind: 'child' });

    const partyDay = daysAfter(home.household.today, 9);
    const created = z.object({ event: z.object({ id: z.string() }) }).parse(
      await structured(assistant, 'create_event', {
        title: "Lily's 7th birthday party",
        date: partyDay,
        start_time: '14:00',
        end_time: '16:30',
        note: 'Jump City, Rivonia. RSVP to Lily’s mom by Friday.',
        member_ids: [emmaMemberId],
      }),
    );
    const event = await household(h.householdId).collection('events').doc(created.event.id).get();
    expect(Object.keys(event.data() ?? {}).sort()).toEqual([...EVENT_KEYS, 'createdVia'].sort());
    expect(event.data()).toEqual({
      title: "Lily's 7th birthday party",
      note: 'Jump City, Rivonia. RSVP to Lily’s mom by Friday.',
      date: partyDay,
      startMinute: 14 * 60,
      endMinute: 16 * 60 + 30,
      recurrence: null,
      memberIds: [emmaMemberId],
      createdBy: patMemberId,
      createdAt: expect.any(Timestamp) as unknown,
      createdVia: 'claude',
    });
    const edited = await asMember(
      pat,
      `households/${h.householdId}/events/${created.event.id}?updateMask.fieldPaths=title`,
      {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ fields: { title: { stringValue: "Lily's party" } } }),
      },
    );
    expect(edited.status, await edited.text()).toBe(200);
    expect((await event.ref.get()).get('createdVia')).toBe('claude');

    const groceries = z
      .object({
        added: z.array(z.object({ id: z.string(), name: z.string() })),
        already_on_list: z.array(
          z.object({ requested: z.string(), item: z.object({ id: z.string() }) }),
        ),
      })
      .parse(
        await structured(assistant, 'add_grocery_items', {
          items: [
            { name: 'Taco shells', quantity: '2 boxes' },
            { name: 'milk' },
            { name: 'Avocados' },
          ],
        }),
      );
    expect(groceries.added.map((item) => item.name)).toEqual(['Taco shells', 'Avocados']);
    expect(groceries.already_on_list).toEqual([
      { requested: 'milk', item: expect.objectContaining({ id: 'milk' }) as unknown },
    ]);
    const shells = await household(h.householdId)
      .collection('groceryItems')
      .doc(groceries.added[0]?.id ?? '')
      .get();
    expect(Object.keys(shells.data() ?? {}).sort()).toEqual(
      [...GROCERY_ITEM_KEYS, 'addedVia'].sort(),
    );
    expect(shells.data()).toMatchObject({
      name: 'Taco shells',
      quantity: '2 boxes',
      addedBy: patMemberId,
      addedVia: 'claude',
      boughtBy: null,
    });
    await assistant.close();

    const refreshed = await refreshAuthorization(issuer ?? '', {
      metadata,
      clientInformation,
      refreshToken: tokens.refresh_token ?? '',
      resource: RESOURCE,
      fetchFn: serverFetch,
    });
    expect(refreshed.access_token).not.toBe(tokens.access_token);
    expect(refreshed.refresh_token).not.toBe(tokens.refresh_token);

    const legacy = await mcpClient(refreshed.access_token, false);
    expect(legacy.getNegotiatedProtocolVersion()).toBe('2025-11-25');
    const list = z
      .object({ items: z.array(z.object({ name: z.string() })) })
      .parse(await structured(legacy, 'get_grocery_list'));
    expect(list.items.map((item) => item.name).sort()).toEqual(['Avocados', 'Milk', 'Taco shells']);
    await legacy.close();

    const connections = listed.parse(
      await (await asMember(pat, `households/${h.householdId}/assistantConnections`)).json(),
    ).documents;
    expect(connections).toHaveLength(1);
    const grantPath = connections[0]?.name.split('/documents/')[1] ?? '';
    const disconnected = await asMember(pat, grantPath, { method: 'DELETE' });
    expect(disconnected.status, await disconnected.text()).toBe(200);

    const afterwards = await mcpClient(refreshed.access_token, true).then(
      () => 'connected',
      (error: unknown) => error,
    );
    expect(afterwards).toBeInstanceOf(UnauthorizedError);
    const refused = await serverFetch(RESOURCE, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        Authorization: `Bearer ${refreshed.access_token}`,
        'MCP-Protocol-Version': '2025-11-25',
      },
      body: JSON.stringify({ jsonrpc: '2.0', id: 2, method: 'tools/list' }),
    });
    expect(refused.status).toBe(401);
    expect(extractWWWAuthenticateParams(refused).error).toBe('invalid_token');
    await expect(
      refreshAuthorization(issuer ?? '', {
        metadata,
        clientInformation,
        refreshToken: refreshed.refresh_token ?? '',
        resource: RESOURCE,
        fetchFn: serverFetch,
      }),
    ).rejects.toThrow();
  });
});
