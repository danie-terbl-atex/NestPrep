import { beforeEach, describe, expect, it } from 'vitest';

import { ASSISTANT_SCOPES } from '../../src/assistants/assistant_scopes';
import { ASSISTANT_TOOLS } from '../../src/assistants/mcp/tools';
import {
  ORIGIN,
  SAM,
  acceptingOnly,
  bearer,
  exchange,
  givenTheOakStreetNest,
  legacy,
  modern,
  principalFor,
  refusingWith,
  rpc,
  type Exchange,
} from './assistants_mcp_fixture';
import { adminDb, clearFirestore } from './emulator_harness';

/**
 * The MCP endpoint's conformance (assistants ADR-0001): Streamable HTTP,
 * stateless, JSON only, for 2026-07-28 clients and for 2025-11-25 and
 * 2025-06-18 clients that open with `initialize`, behind the bearer
 * challenge, both off switches and the scope check (ADR-0003).
 */

const TOKEN = 'npa_good';
const ALL_SCOPES = ASSISTANT_SCOPES.join(' ');
const PRM = `${ORIGIN}/.well-known/oauth-protected-resource/mcp`;
const authenticate = acceptingOnly(TOKEN, principalFor(SAM));

function signedIn(call: { body: unknown; headers: Record<string, string> }): Exchange {
  return { body: call.body, headers: { ...call.headers, ...bearer(TOKEN) } };
}

const EXPECTED_TOOLS = [
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
];

beforeEach(async () => {
  await clearFirestore();
  await givenTheOakStreetNest();
});

describe('a 2025-era client, which opens with initialize', () => {
  for (const version of ['2025-06-18', '2025-11-25']) {
    it(`${version}: initialize answers in JSON with the version asked for and no list changes`, async () => {
      const reply = await exchange(
        authenticate,
        signedIn(
          legacy(
            'initialize',
            {
              protocolVersion: version,
              capabilities: {},
              clientInfo: { name: 'claude-ai', version: '1.0' },
            },
            version,
          ),
        ),
      );
      expect(reply.status).toBe(200);
      expect(reply.headers['content-type']).toMatch(/^application\/json/);
      expect(reply.headers['cache-control']).toBe('no-store');
      expect(reply.headers['mcp-session-id']).toBeUndefined();
      const result = rpc(reply).result;
      expect(result?.['protocolVersion']).toBe(version);
      expect(result?.['capabilities']).toEqual({ tools: { listChanged: false } });
      expect(result?.['serverInfo']).toMatchObject({ name: 'nestprep', version: '1.0.0' });
      expect(result?.['instructions']).toMatch(/get_household first/);
    });

    it(`${version}: notifications/initialized is accepted with 202 and no body`, async () => {
      const reply = await exchange(
        authenticate,
        signedIn({
          body: { jsonrpc: '2.0', method: 'notifications/initialized' },
          headers: { 'MCP-Protocol-Version': version },
        }),
      );
      expect(reply.status).toBe(202);
      expect(reply.body).toBe('');
      expect(reply.headers['cache-control']).toBe('no-store');
    });

    it(`${version}: tools/list names every tool, in order, with title, hints and both schemas`, async () => {
      const reply = await exchange(
        authenticate,
        signedIn(legacy('tools/list', undefined, version)),
      );
      expect(reply.status).toBe(200);
      const tools = rpc(reply).result?.['tools'] as {
        name: string;
        title: string;
        annotations: Record<string, unknown>;
        inputSchema: { type: string; additionalProperties?: boolean };
        outputSchema: { type: string };
      }[];
      expect(tools.map((tool) => tool.name)).toEqual(EXPECTED_TOOLS);
      for (const tool of tools) {
        expect(tool.title.length).toBeGreaterThan(0);
        expect(Object.keys(tool.annotations).sort()).toEqual([
          'destructiveHint',
          'idempotentHint',
          'openWorldHint',
          'readOnlyHint',
          'title',
        ]);
        for (const hint of ['destructiveHint', 'idempotentHint', 'openWorldHint', 'readOnlyHint']) {
          expect(typeof tool.annotations[hint]).toBe('boolean');
        }
        expect(tool.annotations['openWorldHint']).toBe(false);
        expect(tool.inputSchema.type).toBe('object');
        expect(tool.inputSchema.additionalProperties).toBe(false);
        expect(tool.outputSchema.type).toBe('object');
      }
    });

    it(`${version}: tools/call answers with structuredContent and the same JSON as text`, async () => {
      const reply = await exchange(
        authenticate,
        signedIn(legacy('tools/call', { name: 'get_household', arguments: {} }, version)),
      );
      expect(reply.status).toBe(200);
      const result = rpc(reply).result as {
        content: { type: string; text: string }[];
        structuredContent: Record<string, unknown>;
        isError?: boolean;
      };
      expect(result.isError).toBeUndefined();
      expect(result.content).toHaveLength(1);
      expect(JSON.parse(result.content[0]?.text ?? '')).toEqual(result.structuredContent);
      expect(result.structuredContent['household']).toMatchObject({ id: 'h-oak' });
    });

    it(`${version}: ping still answers`, async () => {
      const reply = await exchange(authenticate, signedIn(legacy('ping', undefined, version, 9)));
      expect(reply.status).toBe(200);
      expect(rpc(reply)).toMatchObject({ id: 9, result: {} });
    });

    it(`${version}: an unknown tool is a JSON-RPC error, not a result`, async () => {
      const reply = await exchange(
        authenticate,
        signedIn(legacy('tools/call', { name: 'send_email', arguments: {} }, version)),
      );
      expect(rpc(reply).error?.code).toBe(-32602);
    });
  }
});

describe('a 2026-07-28 client, which sends its version on every request', () => {
  it('server/discover names the revision, the capabilities and the server', async () => {
    const reply = await exchange(authenticate, signedIn(modern('server/discover')));
    expect(reply.status).toBe(200);
    expect(reply.headers['content-type']).toMatch(/^application\/json/);
    const result = rpc(reply).result;
    expect(result?.['supportedVersions']).toContain('2026-07-28');
    expect(result?.['capabilities']).toEqual({ tools: { listChanged: false } });
    expect(result?.['resultType']).toBe('complete');
  });

  it('tools/list is complete and cacheable, in the same order', async () => {
    const reply = await exchange(authenticate, signedIn(modern('tools/list')));
    const result = rpc(reply).result as {
      tools: { name: string }[];
      resultType: string;
      ttlMs: number;
      cacheScope: string;
    };
    expect(result.tools.map((tool) => tool.name)).toEqual(EXPECTED_TOOLS);
    expect(result.resultType).toBe('complete');
    expect(typeof result.ttlMs).toBe('number');
    expect(result.cacheScope).toBe('private');
  });

  it('tools/call answers in JSON, never a stream', async () => {
    const reply = await exchange(
      authenticate,
      signedIn(modern('tools/call', { name: 'get_household', arguments: {} })),
    );
    expect(reply.status).toBe(200);
    expect(reply.headers['content-type']).toMatch(/^application\/json/);
    expect(rpc(reply).result).toMatchObject({ resultType: 'complete' });
  });

  it('ping was removed in this revision and is method-not-found', async () => {
    const reply = await exchange(authenticate, signedIn(modern('ping')));
    expect(reply.status).toBe(404);
    expect(rpc(reply).error?.code).toBe(-32601);
  });

  it('an unknown method is 404 with -32601', async () => {
    const reply = await exchange(authenticate, signedIn(modern('resources/list')));
    expect(reply.status).toBe(404);
    expect(rpc(reply).error?.code).toBe(-32601);
  });

  it('an unknown tool is -32602', async () => {
    const reply = await exchange(
      authenticate,
      signedIn(modern('tools/call', { name: 'send_email', arguments: {} })),
    );
    expect(rpc(reply).error?.code).toBe(-32602);
  });

  it('a Mcp-Name header that disagrees with the body is 400 HeaderMismatch', async () => {
    const call = modern('tools/call', { name: 'get_household', arguments: {} });
    const reply = await exchange(authenticate, {
      body: call.body,
      headers: { ...call.headers, 'Mcp-Name': 'list_events', ...bearer(TOKEN) },
    });
    expect(reply.status).toBe(400);
    expect(rpc(reply).error?.code).toBe(-32020);
  });

  it('an unknown revision is 400 with the supported ones', async () => {
    const reply = await exchange(authenticate, {
      body: {
        jsonrpc: '2.0',
        id: 1,
        method: 'tools/list',
        params: {
          _meta: {
            'io.modelcontextprotocol/protocolVersion': '2099-01-01',
            'io.modelcontextprotocol/clientInfo': { name: 'test-client', version: '1.0.0' },
            'io.modelcontextprotocol/clientCapabilities': {},
          },
        },
      },
      headers: {
        'MCP-Protocol-Version': '2099-01-01',
        'Mcp-Method': 'tools/list',
        ...bearer(TOKEN),
      },
    });
    expect(reply.status).toBe(400);
    expect(rpc(reply).error).toMatchObject({
      code: -32022,
      data: { supported: ['2026-07-28'], requested: '2099-01-01' },
    });
  });

  it('subscriptions/listen is not served, so no stream is ever held open', async () => {
    const reply = await exchange(
      authenticate,
      signedIn(modern('subscriptions/listen', { notifications: { toolsListChanged: true } })),
    );
    expect(reply.status).toBe(404);
    expect(rpc(reply).error?.code).toBe(-32601);
  });
});

describe('what is not JSON-RPC', () => {
  it('a body that is not JSON is a parse error', async () => {
    const reply = await exchange(authenticate, {
      rawBody: '{"jsonrpc": "2.0", "id": 1,',
      headers: { ...bearer(TOKEN), 'MCP-Protocol-Version': '2025-11-25' },
    });
    expect(reply.status).toBe(400);
    expect(rpc(reply).error?.code).toBe(-32700);
  });

  it('JSON that is not a JSON-RPC message is an invalid request', async () => {
    const reply = await exchange(authenticate, {
      body: { hello: 'world' },
      headers: { ...bearer(TOKEN), 'MCP-Protocol-Version': '2025-11-25' },
    });
    expect(reply.status).toBe(400);
    expect(rpc(reply).error?.code).toBe(-32600);
  });

  for (const version of ['2025-03-26', '2025-06-18', '2025-11-25', '2026-07-28']) {
    it(`${version}: a batch is -32600 before any sign-in, so it cannot run many calls on one`, async () => {
      let signIns = 0;
      const counting: typeof authenticate = (authorization, now) => {
        signIns += 1;
        return authenticate(authorization, now);
      };
      const initialize = {
        jsonrpc: '2.0',
        id: 0,
        method: 'initialize',
        params: {
          protocolVersion: version,
          capabilities: {},
          clientInfo: { name: 'x', version: '1' },
        },
      };
      const calls = Array.from({ length: 20 }, (_, index) => ({
        jsonrpc: '2.0',
        id: index + 1,
        method: 'tools/call',
        params: { name: 'get_household', arguments: {} },
      }));
      for (const batch of [[initialize, ...calls], calls, []]) {
        const reply = await exchange(counting, {
          body: batch,
          headers: { ...bearer(TOKEN), 'MCP-Protocol-Version': version },
        });
        expect(reply.status).toBe(400);
        expect(rpc(reply).error?.code).toBe(-32600);
      }
      expect(signIns).toBe(0);
    });
  }

  for (const method of ['GET', 'DELETE', 'PUT']) {
    it(`${method} is 405, before any sign-in`, async () => {
      const reply = await exchange(authenticate, { method });
      expect(reply.status).toBe(405);
      expect(reply.headers['allow']).toBe('POST');
      expect(reply.headers['cache-control']).toBe('no-store');
      expect(reply.headers['www-authenticate']).toBeUndefined();
    });
  }
});

describe('Origin', () => {
  const call = modern('tools/list');

  it('absent is fine: the hosts call from their servers', async () => {
    expect((await exchange(authenticate, signedIn(call))).status).toBe(200);
  });

  for (const origin of [ORIGIN, 'https://claude.ai', 'https://claude.com', 'https://chatgpt.com']) {
    it(`${origin} is accepted`, async () => {
      const reply = await exchange(authenticate, {
        body: call.body,
        headers: { ...call.headers, ...bearer(TOKEN), Origin: origin },
      });
      expect(reply.status).toBe(200);
    });
  }

  for (const origin of [
    'https://evil.example',
    'http://claude.ai',
    'https://nestprep.test.evil.example',
    'null',
  ]) {
    it(`${origin} is refused with 403 before the token is looked at`, async () => {
      const reply = await exchange(refusingWith('invalidToken'), {
        body: call.body,
        headers: { ...call.headers, ...bearer(TOKEN), Origin: origin },
      });
      expect(reply.status).toBe(403);
      expect(reply.headers['www-authenticate']).toBeUndefined();
      expect(rpc(reply).error?.code).toBe(-32000);
    });
  }
});

describe('the bearer challenge', () => {
  const call = modern('tools/list');

  it('no token: 401 naming the resource metadata and every scope', async () => {
    const reply = await exchange(acceptingOnly(TOKEN, principalFor(SAM)), call);
    expect(reply.status).toBe(401);
    expect(reply.headers['www-authenticate']).toBe(
      `Bearer resource_metadata="${PRM}", scope="${ALL_SCOPES}"`,
    );
    expect(reply.headers['cache-control']).toBe('no-store');
  });

  it('a token that is not ours, or a Firebase ID token: 401 invalid_token', async () => {
    for (const token of ['npa_unknown', 'eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJ1aWQifQ.sig']) {
      const reply = await exchange(acceptingOnly(TOKEN, principalFor(SAM)), {
        body: call.body,
        headers: { ...call.headers, ...bearer(token) },
      });
      expect(reply.status).toBe(401);
      expect(reply.headers['www-authenticate']).toBe(
        `Bearer error="invalid_token", resource_metadata="${PRM}", scope="${ALL_SCOPES}"`,
      );
    }
  });

  for (const tool of ASSISTANT_TOOLS) {
    it(`${tool.name} without ${tool.scope}: 403 insufficient_scope naming it`, async () => {
      const scopes = ASSISTANT_SCOPES.filter((scope) => scope !== tool.scope);
      const reply = await exchange(acceptingOnly(TOKEN, principalFor(SAM, scopes)), {
        ...signedIn(modern('tools/call', { name: tool.name, arguments: {} })),
      });
      expect(reply.status).toBe(403);
      expect(reply.headers['www-authenticate']).toBe(
        `Bearer error="insufficient_scope", scope="${tool.scope}", resource_metadata="${PRM}"`,
      );
    });
  }

  it('the scope check holds for a 2025-era call too', async () => {
    const reply = await exchange(acceptingOnly(TOKEN, principalFor(SAM, ['household:read'])), {
      ...signedIn(
        legacy('tools/call', { name: 'add_grocery_items', arguments: { items: [] } }, '2025-11-25'),
      ),
    });
    expect(reply.status).toBe(403);
    expect(reply.headers['www-authenticate']).toContain('scope="lists:write"');
  });

  it('listing the tools needs no particular scope', async () => {
    const reply = await exchange(
      acceptingOnly(TOKEN, principalFor(SAM, ['household:read'])),
      signedIn(modern('tools/list')),
    );
    expect(reply.status).toBe(200);
  });

  it('a connection over its call limit: 429', async () => {
    const reply = await exchange(refusingWith('rateLimited'), signedIn(call));
    expect(reply.status).toBe(429);
    expect(reply.headers['www-authenticate']).toBeUndefined();
  });
});

describe('switched off', () => {
  const call = modern('tools/list');

  it('the assistants flag absent in the cloud: 503', async () => {
    await adminDb().collection('appConfig').doc('flags').set({});
    const reply = await exchange(authenticate, signedIn(call));
    expect(reply.status).toBe(503);
    expect(reply.headers['cache-control']).toBe('no-store');
  });

  it('the flag off: 503', async () => {
    await adminDb().collection('appConfig').doc('flags').set({ assistants: false });
    expect((await exchange(authenticate, signedIn(call))).status).toBe(503);
  });

  it('the kill switch thrown: 503, for every request', async () => {
    await adminDb().collection('appConfig').doc('assistants').set({ enabled: false });
    expect((await exchange(authenticate, signedIn(call))).status).toBe(503);
    const tool = await exchange(
      authenticate,
      signedIn(modern('tools/call', { name: 'get_household', arguments: {} })),
    );
    expect(tool.status).toBe(503);
  });

  it('an authenticator that says switched off: 503', async () => {
    expect((await exchange(refusingWith('switchedOff'), signedIn(call))).status).toBe(503);
  });
});
