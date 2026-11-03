import { Timestamp } from 'firebase-admin/firestore';

import { ASSISTANT_SCOPES, type AssistantScope } from '../../src/assistants/assistant_scopes';
import {
  mcpHandler,
  type McpHttpRequest,
  type McpHttpResponse,
} from '../../src/assistants/mcp/mcp_handler';
import {
  AssistantRefusal,
  type AssistantPrincipal,
  type AssistantRefusalKind,
  type Authenticate,
} from '../../src/assistants/principal';
import { adminDb } from './emulator_harness';

/**
 * The Oak Street household as the assistant tools meet it (assistants
 * ADR-0001, ADR-0003): an admin and a parent who claimed their profiles, a
 * helper, a shift-only carer, a parent who never claimed one, two children,
 * and a second household whose member ids must never be accepted here.
 */

export const NOW = new Date('2026-10-29T08:00:00Z');
export const TODAY = '2026-10-29';
export const ORIGIN = 'https://nestprep.test';

export const HOUSEHOLD = 'h-oak';
export const OTHER_HOUSEHOLD = 'h-elm';

export interface Person {
  readonly uid: string;
  readonly member: string;
}

export const SAM: Person = { uid: 'uid-sam', member: 'm-sam' };
export const PAT: Person = { uid: 'uid-pat', member: 'm-pat' };
export const THANDI: Person = { uid: 'uid-thandi', member: 'm-thandi' };
export const NOMSA: Person = { uid: 'uid-nomsa', member: 'm-nomsa' };
export const LEE = { uid: 'uid-lee' };
export const EMMA = 'm-emma';
export const MIA = 'm-mia';
export const STRANGER = 'm-stranger';

export async function givenTheOakStreetNest(): Promise<void> {
  const store = adminDb();
  const household = store.collection('households').doc(HOUSEHOLD);
  await household.set({
    name: 'The Oak Street Nest',
    timeZone: 'Africa/Johannesburg',
    members: {
      [SAM.uid]: 'admin',
      [PAT.uid]: 'parent',
      [THANDI.uid]: 'helper',
      [NOMSA.uid]: 'carer',
      [LEE.uid]: 'parent',
    },
    profiles: {
      [SAM.uid]: SAM.member,
      [PAT.uid]: PAT.member,
      [THANDI.uid]: THANDI.member,
      [NOMSA.uid]: NOMSA.member,
    },
    access: {
      [THANDI.uid]: { calendar: 'edit', groceries: 'edit' },
      [NOMSA.uid]: { calendar: 'edit', groceries: 'edit' },
    },
    shiftOnly: { [NOMSA.member]: true },
  });
  const members: [string, string, string, string | null][] = [
    [SAM.member, 'Sam Parker', 'admin', SAM.uid],
    [PAT.member, 'Pat Parker', 'parent', PAT.uid],
    [THANDI.member, 'Thandi Dlamini', 'helper', THANDI.uid],
    [NOMSA.member, 'Nomsa', 'carer', NOMSA.uid],
    [EMMA, 'Emma Parker', 'kid', null],
    [MIA, 'Mia', 'parent', null],
  ];
  for (const [id, displayName, role, claimedBy] of members) {
    await household.collection('members').doc(id).set({
      displayName,
      color: 'violet',
      role,
      claimedBy,
      birthday: '2019-03-14',
    });
  }
  await household
    .collection('familyProfiles')
    .doc(MIA)
    .set({ isChild: true, allergies: ['nuts'] });
  await store.collection('appConfig').doc('flags').set({ assistants: true });

  const other = store.collection('households').doc(OTHER_HOUSEHOLD);
  await other.set({
    name: 'Elm',
    timeZone: 'Africa/Johannesburg',
    members: { 'uid-stranger': 'admin' },
    profiles: { 'uid-stranger': STRANGER },
  });
  await other.collection('members').doc(STRANGER).set({
    displayName: 'Stranger',
    color: 'blue',
    role: 'admin',
    claimedBy: 'uid-stranger',
  });
}

/** A booked shift for Nomsa around [at], which opens her grant (nanny-hub ADR-0006). */
export async function givenNomsaOnShift(at: Date): Promise<void> {
  await adminDb()
    .collection('households')
    .doc(HOUSEHOLD)
    .collection('nannyBookings')
    .doc('shift-1')
    .set({
      carerMemberId: NOMSA.member,
      startsAt: Timestamp.fromMillis(at.getTime() - 3_600_000),
      endsAt: Timestamp.fromMillis(at.getTime() + 3_600_000),
    });
}

export function principalFor(
  person: { uid: string },
  scopes: readonly AssistantScope[] = ASSISTANT_SCOPES,
  householdId = HOUSEHOLD,
): AssistantPrincipal {
  return { grantId: `grant-${person.uid}`, uid: person.uid, householdId, via: 'claude', scopes };
}

/** An `Authenticate` that knows one token, the way `authenticateBearer` would. */
export function acceptingOnly(token: string, principal: AssistantPrincipal): Authenticate {
  return (authorization) =>
    authorization === `Bearer ${token}`
      ? Promise.resolve(principal)
      : Promise.reject(new AssistantRefusal('invalidToken', 'unknownToken', 'Unknown token.'));
}

export function refusingWith(kind: AssistantRefusalKind): Authenticate {
  return () => Promise.reject(new AssistantRefusal(kind, kind, `Refused: ${kind}.`));
}

export interface Reply {
  readonly status: number;
  readonly headers: Readonly<Record<string, string>>;
  readonly body: string;
}

class RecordingResponse implements McpHttpResponse {
  status_ = 0;
  readonly headers: Record<string, string> = {};
  body = '';
  ended = false;

  status(code: number): this {
    this.status_ = code;
    return this;
  }

  setHeader(name: string, value: string): this {
    this.headers[name.toLowerCase()] = value;
    return this;
  }

  send(body: string): this {
    this.body = body;
    this.ended = true;
    return this;
  }

  end(): this {
    this.ended = true;
    return this;
  }
}

export interface Exchange {
  readonly method?: string;
  readonly headers?: Record<string, string>;
  readonly body?: unknown;
  readonly rawBody?: string;
}

/**
 * Drives the handler the way Cloud Functions does: Express's request with
 * the JSON body parsed and its bytes in `rawBody`, and a response recorded.
 */
export async function exchange(authenticate: Authenticate, call: Exchange): Promise<Reply> {
  const raw = call.rawBody ?? (call.body === undefined ? undefined : JSON.stringify(call.body));
  const req: McpHttpRequest = {
    method: call.method ?? 'POST',
    headers: {
      'content-type': 'application/json',
      accept: 'application/json, text/event-stream',
      ...Object.fromEntries(
        Object.entries(call.headers ?? {}).map(([name, value]) => [name.toLowerCase(), value]),
      ),
    },
    ...(raw === undefined ? {} : { rawBody: Buffer.from(raw, 'utf8') }),
    ...(call.body === undefined ? {} : { body: call.body }),
  };
  const res = new RecordingResponse();
  await mcpHandler(authenticate, { store: adminDb, now: () => NOW, origin: () => ORIGIN })(
    req,
    res,
  );
  return { status: res.status_, headers: res.headers, body: res.body };
}

export const MODERN = '2026-07-28';

/** A 2026-07-28 request: the body's `_meta` and the headers that mirror it. */
export function modern(
  method: string,
  params: Record<string, unknown> = {},
  id: number | string = 1,
): { body: unknown; headers: Record<string, string> } {
  const name = typeof params['name'] === 'string' ? params['name'] : undefined;
  return {
    body: {
      jsonrpc: '2.0',
      id,
      method,
      params: {
        ...params,
        _meta: {
          'io.modelcontextprotocol/protocolVersion': MODERN,
          'io.modelcontextprotocol/clientInfo': { name: 'test-client', version: '1.0.0' },
          'io.modelcontextprotocol/clientCapabilities': {},
        },
      },
    },
    headers: {
      'MCP-Protocol-Version': MODERN,
      'Mcp-Method': method,
      ...(name === undefined ? {} : { 'Mcp-Name': name }),
    },
  };
}

/** A 2025-era request, after the client's `initialize`. */
export function legacy(
  method: string,
  params: Record<string, unknown> | undefined,
  version: string,
  id: number | string = 1,
): { body: unknown; headers: Record<string, string> } {
  return {
    body: { jsonrpc: '2.0', id, method, ...(params === undefined ? {} : { params }) },
    headers: { 'MCP-Protocol-Version': version },
  };
}

export function bearer(token: string): Record<string, string> {
  return { Authorization: `Bearer ${token}` };
}

/** The JSON-RPC envelope of a reply. */
export function rpc(reply: Reply): {
  id?: unknown;
  result?: Record<string, unknown>;
  error?: { code: number; message: string; data?: unknown };
} {
  return JSON.parse(reply.body) as {
    id?: unknown;
    result?: Record<string, unknown>;
    error?: { code: number; message: string; data?: unknown };
  };
}
