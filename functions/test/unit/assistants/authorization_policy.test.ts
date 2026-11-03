import type { DecodedIdToken } from 'firebase-admin/auth';
import type { Firestore } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';

import { ASSISTANT_SCOPES } from '../../../src/assistants/assistant_scopes';
import { pkceMatches, sha256Hex } from '../../../src/assistants/auth/auth_documents';
import {
  SESSION_COOKIE,
  sessionCookie,
  sessionFrom,
} from '../../../src/assistants/auth/auth_reply';
import {
  type ClientResolution,
  clientDocumentUrl,
  resolveClient,
} from '../../../src/assistants/auth/client_registry';
import {
  authorizationServerMetadata,
  protectedResourceMetadata,
} from '../../../src/assistants/auth/discovery';
import {
  REGISTER_OVERALL,
  REGISTER_PER_ADDRESS,
  callerAddress,
} from '../../../src/assistants/auth/auth_rate_limits';
import { checkFreshSignIn } from '../../../src/assistants/auth/fresh_sign_in';
import {
  isAllowedRedirect,
  redirectMatches,
  viaOfRedirect,
} from '../../../src/assistants/auth/redirect_policy';
import { uidsThatLostAssistants } from '../../../src/assistants/connections/prune_assistant_connections';

/**
 * The parts of the assistants' authorization server that need nothing
 * running (assistants ADR-0002, ADR-0003): where a code may go, which client
 * id is a metadata document, PKCE, the browser's session cookie, the
 * discovery documents, a fresh sign-in, and who loses their connections when
 * a household's roles change. The flows themselves are the emulator suite's.
 */

const server = {
  issuer: 'https://nestprep.example',
  resource: 'https://nestprep.example/mcp',
  allowLoopbackRedirects: false,
};

describe('where a code may be sent', () => {
  it('to Claude and ChatGPT’s own callbacks, exactly', () => {
    for (const uri of [
      'https://claude.ai/api/mcp/auth_callback',
      'https://claude.com/api/mcp/auth_callback',
      'https://chatgpt.com/connector_platform_oauth_redirect',
      'https://chatgpt.com/connector/oauth/abc_123-XYZ',
    ]) {
      expect(isAllowedRedirect(uri, false), uri).toBe(true);
    }
  });

  it('nowhere that only looks like them', () => {
    for (const uri of [
      'https://claude.ai/api/mcp/auth_callback/',
      'https://claude.ai/api/mcp/auth_callback?next=evil',
      'https://claude.ai.evil.com/api/mcp/auth_callback',
      'http://claude.ai/api/mcp/auth_callback',
      'https://chatgpt.com/connector/oauth/',
      'https://chatgpt.com/connector/oauth/a/b',
      'https://evil.example/callback',
    ]) {
      expect(isAllowedRedirect(uri, false), uri).toBe(false);
    }
  });

  it('to loopback only when ASSISTANTS_ALLOW_LOOPBACK says so, and only on /callback', () => {
    expect(isAllowedRedirect('http://localhost:33418/callback', false)).toBe(false);
    expect(isAllowedRedirect('http://localhost:33418/callback', true)).toBe(true);
    expect(isAllowedRedirect('http://127.0.0.1:6274/callback', true)).toBe(true);
    expect(isAllowedRedirect('http://localhost:33418/other', true)).toBe(false);
    expect(isAllowedRedirect('http://10.0.0.1:80/callback', true)).toBe(false);
  });

  it('matches a registered redirect exactly, except a loopback port', () => {
    const registered = ['https://claude.ai/api/mcp/auth_callback', 'http://localhost:1/callback'];
    expect(redirectMatches(registered, 'https://claude.ai/api/mcp/auth_callback')).toBe(true);
    expect(redirectMatches(registered, 'https://claude.com/api/mcp/auth_callback')).toBe(false);
    expect(redirectMatches(registered, 'http://localhost:51234/callback')).toBe(true);
    expect(redirectMatches(registered, 'http://127.0.0.1:51234/callback')).toBe(false);
  });

  it('names the assistant by the redirect’s host', () => {
    expect(viaOfRedirect('https://claude.ai/api/mcp/auth_callback')).toBe('claude');
    expect(viaOfRedirect('https://claude.com/api/mcp/auth_callback')).toBe('claude');
    expect(viaOfRedirect('https://chatgpt.com/connector_platform_oauth_redirect')).toBe('chatgpt');
    expect(viaOfRedirect('http://localhost:1/callback')).toBe('assistant');
  });
});

describe('a client id that is a metadata document', () => {
  it('is an https URL with a path, spelled one way', () => {
    expect(clientDocumentUrl('https://claude.ai/oauth/client.json', false)?.host).toBe('claude.ai');
    for (const id of [
      'npc_abc',
      'http://claude.ai/client.json',
      'https://claude.ai',
      'https://claude.ai/',
      'https://claude.ai/a/../client.json',
      'https://claude.ai/client.json#x',
      'https://user:pw@claude.ai/client.json',
      'https://CLAUDE.ai/client.json',
    ]) {
      expect(clientDocumentUrl(id, false), id).toBeNull();
    }
  });

  it('names a domain, never an IP address, however it is written', () => {
    for (const id of [
      'https://[::ffff:a9fe:a9fe]/client.json',
      'https://[::ffff:7f00:1]/client.json',
      'https://169.254.169.254/client.json',
      'https://17.253.144.10/client.json',
      'https://[2606:4700::1111]/client.json',
    ]) {
      expect(clientDocumentUrl(id, false), id).toBeNull();
    }
    expect(clientDocumentUrl('https://169.254.169.254/client.json', true)).toBeNull();
    expect(clientDocumentUrl('http://[::ffff:a9fe:a9fe]/client.json', true)).toBeNull();
  });

  it('may be plain http only for the emulator suite’s local server', () => {
    expect(clientDocumentUrl('http://127.0.0.1:9000/client.json', false)).toBeNull();
    expect(clientDocumentUrl('http://127.0.0.1:9000/client.json', true)?.port).toBe('9000');
  });
});

describe('PKCE and the stored hashes', () => {
  it('verifies RFC 7636’s own example, and nothing else', () => {
    const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
    const challenge = 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM';
    expect(pkceMatches(verifier, challenge)).toBe(true);
    expect(pkceMatches(`${verifier}x`, challenge)).toBe(false);
    expect(pkceMatches(verifier, verifier)).toBe(false);
  });

  it('keys a document by a hash, never the secret', () => {
    expect(sha256Hex('npa_x')).toMatch(/^[0-9a-f]{64}$/);
    expect(sha256Hex('npa_x')).not.toContain('npa_x');
  });
});

describe('the browser’s session cookie', () => {
  it('is the one cookie Hosting forwards, kept to /oauth and away from scripts', () => {
    const cookie = sessionCookie('a'.repeat(43), 600);
    expect(cookie.startsWith(`${SESSION_COOKIE}=`)).toBe(true);
    expect(SESSION_COOKIE).toBe('__session');
    for (const part of ['Path=/oauth', 'Max-Age=600', 'Secure', 'HttpOnly', 'SameSite=Lax']) {
      expect(cookie).toContain(part);
    }
  });

  it('is read back only when it has the shape this server sets', () => {
    const value = 'b'.repeat(43);
    expect(sessionFrom(`other=1; __session=${value}`)).toBe(value);
    expect(sessionFrom('__session=short')).toBeNull();
    expect(sessionFrom(undefined)).toBeNull();
  });
});

describe('discovery', () => {
  it('the protected resource names its resource and this server', () => {
    expect(protectedResourceMetadata(server)).toEqual({
      resource: 'https://nestprep.example/mcp',
      authorization_servers: ['https://nestprep.example'],
      scopes_supported: [...ASSISTANT_SCOPES],
      bearer_methods_supported: ['header'],
      resource_name: 'nestprep',
    });
  });

  it('the server says S256 only, public clients, CIMD, DCR, revocation and iss', () => {
    expect(authorizationServerMetadata(server)).toMatchObject({
      issuer: 'https://nestprep.example',
      authorization_endpoint: 'https://nestprep.example/oauth/authorize',
      token_endpoint: 'https://nestprep.example/oauth/token',
      registration_endpoint: 'https://nestprep.example/oauth/register',
      revocation_endpoint: 'https://nestprep.example/oauth/revoke',
      response_types_supported: ['code'],
      grant_types_supported: ['authorization_code', 'refresh_token'],
      code_challenge_methods_supported: ['S256'],
      token_endpoint_auth_methods_supported: ['none'],
      client_id_metadata_document_supported: true,
      authorization_response_iss_parameter_supported: true,
      scopes_supported: [...ASSISTANT_SCOPES],
    });
  });
});

describe('a fresh sign-in', () => {
  const now = new Date('2026-10-29T10:00:00Z');
  const token = (claims: Partial<DecodedIdToken>): DecodedIdToken => ({
    aud: 'p',
    auth_time: now.getTime() / 1000 - 60,
    exp: 0,
    firebase: { identities: {}, sign_in_provider: 'password' },
    iat: 0,
    iss: 'i',
    sub: 'uid-sam',
    uid: 'uid-sam',
    ...claims,
  });
  const verifying = (decoded: DecodedIdToken) => (): Promise<DecodedIdToken> =>
    Promise.resolve(decoded);

  it('is a signed-in uid within five minutes', async () => {
    expect(await checkFreshSignIn(verifying(token({})), 't', now)).toEqual({
      kind: 'signedIn',
      uid: 'uid-sam',
    });
  });

  it('is refused at five minutes and a second', async () => {
    const stale = token({ auth_time: now.getTime() / 1000 - 301 });
    expect(await checkFreshSignIn(verifying(stale), 't', now)).toEqual({
      kind: 'refused',
      reason: 'staleSignIn',
    });
  });

  it('is never a kid device', async () => {
    const kid = token({ kidProfile: { householdId: 'h', memberId: 'm' } });
    expect(await checkFreshSignIn(verifying(kid), 't', now)).toEqual({
      kind: 'refused',
      reason: 'kidAccount',
    });
  });

  it('is refused when the Admin SDK refuses the token, revoked included', async () => {
    const revoked = (): Promise<DecodedIdToken> =>
      Promise.reject(new Error('auth/id-token-revoked'));
    expect(await checkFreshSignIn(revoked, 't', now)).toEqual({
      kind: 'refused',
      reason: 'signInRequired',
    });
  });
});

describe('who loses their connections when the roles change', () => {
  it('a member who leaves, and family who stop being family', () => {
    expect(
      uidsThatLostAssistants(
        { a: 'admin', p: 'parent', m: 'member', h: 'helper', gone: 'parent' },
        { a: 'admin', p: 'helper', m: 'member', h: 'helper' },
      ).sort(),
    ).toEqual(['gone', 'p']);
  });

  it('nobody when nothing about family changed, or the map is unreadable', () => {
    expect(uidsThatLostAssistants({ a: 'admin', h: 'helper' }, { a: 'admin', h: 'carer' })).toEqual(
      [],
    );
    expect(uidsThatLostAssistants({ a: 'admin' }, { a: 'parent' })).toEqual([]);
    expect(uidsThatLostAssistants(undefined, undefined)).toEqual([]);
  });

  it('a removed helper too, in case a connection outlived a role change', () => {
    expect(uidsThatLostAssistants({ h: 'helper' }, {})).toEqual(['h']);
  });
});

describe('the address a browser is counted by', () => {
  it('is the client Hosting forwarded, not the Hosting proxy Google’s front end appended', () => {
    const forwarded = (value: string | string[]): string =>
      callerAddress({ ip: '10.9.8.7', headers: { 'x-forwarded-for': value } });
    expect(forwarded('203.0.113.50, 142.250.1.100')).toBe('203.0.113.50');
    expect(forwarded(['203.0.113.50 ', '66.249.2.193'])).toBe('203.0.113.50');
    expect(forwarded('1.1.1.1, 203.0.113.50, 66.249.2.103')).toBe('203.0.113.50');
  });

  it('is the only hop of a call made straight to the Function', () => {
    const forwarded = (value: string): string =>
      callerAddress({ ip: '10.9.8.7', headers: { 'x-forwarded-for': value } });
    expect(forwarded('203.0.113.50')).toBe('203.0.113.50');
    expect(forwarded('203.0.113.50, ')).toBe('203.0.113.50');
  });

  it('is the socket’s when nothing was forwarded', () => {
    expect(callerAddress({ ip: '10.9.8.7', headers: {} })).toBe('10.9.8.7');
    expect(callerAddress({ headers: {} })).toBe('unknown');
  });

  it('lets Claude register once per connection: 5,000 a day overall, 30 an hour per address', () => {
    expect(REGISTER_OVERALL).toMatchObject({ limit: 5_000, windowSeconds: 86_400 });
    expect(REGISTER_PER_ADDRESS).toMatchObject({ limit: 30, windowSeconds: 3_600 });
  });
});

describe('a client metadata document', () => {
  const CLAUDE_ID = 'https://claude.ai/oauth/mcp-oauth-client-metadata';
  const claudeAsServed = {
    client_id: CLAUDE_ID,
    client_name: 'Claude',
    client_uri: 'https://claude.ai',
    redirect_uris: ['https://claude.ai/api/mcp/auth_callback'],
    grant_types: [
      'authorization_code',
      'refresh_token',
      'urn:ietf:params:oauth:grant-type:jwt-bearer',
    ],
    response_types: ['code'],
    token_endpoint_auth_method: 'none',
  };
  const nothingCached = { data: (): undefined => undefined };
  const emptyStore = {
    collection: (): unknown => ({
      doc: (): unknown => ({ get: (): Promise<unknown> => Promise.resolve(nothingCached) }),
    }),
    batch: (): unknown => ({
      set: (): undefined => undefined,
      commit: (): Promise<unknown[]> => Promise.resolve([]),
    }),
  } as unknown as Firestore;
  const resolve = (document: Record<string, unknown>): Promise<ClientResolution> =>
    resolveClient(
      {
        store: emptyStore,
        fetchDocument: (): Promise<string> => Promise.resolve(JSON.stringify(document)),
        allowLoopbackRedirects: false,
        allowLocalDocuments: false,
        now: new Date('2026-10-29T20:00:00Z'),
      },
      CLAUDE_ID,
    );

  it('is accepted as Claude serves it, with grant types NestPrep never issues', async () => {
    const resolution = await resolve(claudeAsServed);
    expect(resolution).toMatchObject({ kind: 'client', client: { via: 'claude' } });
  });

  it('is refused when it does not offer the code flow', async () => {
    expect(await resolve({ ...claudeAsServed, grant_types: ['refresh_token'] })).toEqual({
      kind: 'unknown',
      reason: 'documentShape',
    });
    expect(await resolve({ ...claudeAsServed, response_types: ['token'] })).toEqual({
      kind: 'unknown',
      reason: 'documentShape',
    });
  });
});
