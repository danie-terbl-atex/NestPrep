import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import {
  PnpSessionExpired,
  type PnpClient,
  type PnpLogin,
  type PnpTokens,
} from '../../../src/pnp/pnp_api';
import { withPnpSession } from '../../../src/pnp/pnp_session';
import { sealJson } from '../../../src/shared/sealed_json';
import {
  openSessionTokens,
  sealLinkSecrets,
  sealSessionTokens,
  type PnpSessionTokens,
} from '../../../src/pnp/pnp_sealed_values';
import { KEY, MemoryPnpLinks, NOW, ScriptedPnpLogin, UID } from './fakes';

/**
 * Keeping the member's PnP session alive (add-to-pnp ADR-0003): refreshed
 * before it lapses, a rotated refresh token kept, one retry after PnP says
 * unauthorised, and a link that is truly spent says so.
 */
interface Linked {
  readonly links: MemoryPnpLinks;
  readonly login: ScriptedPnpLogin;
  readonly key: Buffer;
  readonly now: Date;
}

async function linked(accessExpiresAt: Date): Promise<Linked> {
  const links = new MemoryPnpLinks();
  links.links[UID] = {
    pending: null,
    session: {
      sealed: await sealSessionTokens(KEY, UID, {
        accessToken: 'access-0',
        refreshToken: 'refresh-0',
      }),
      accessExpiresAt,
      linkedAt: new Date('2026-10-01T08:00:00Z'),
    },
  };
  return { links, login: new ScriptedPnpLogin(), key: KEY, now: NOW };
}

const future = new Date(NOW.getTime() + 600_000);
const past = new Date(NOW.getTime() - 1);

function reasonOf(error: unknown): unknown {
  return error instanceof HttpsError ? (error.details as { reason?: string }).reason : error;
}

async function storedTokens(deps: Linked): Promise<PnpSessionTokens | null> {
  return openSessionTokens(KEY, UID, deps.links.links[UID]?.session?.sealed ?? '');
}

describe('using the session', () => {
  it('uses a live access token as it is, refreshing nothing', async () => {
    const d = await linked(future);
    expect(await withPnpSession(d, UID, (token) => Promise.resolve(token))).toBe('access-0');
    expect(d.login.refreshed).toEqual([]);
  });

  it('refreshes a lapsed access token first, and keeps the rotated refresh token', async () => {
    const d = await linked(past);
    expect(await withPnpSession(d, UID, (token) => Promise.resolve(token))).toBe('access-1');
    expect(d.login.refreshed).toEqual(['refresh-0']);
    expect(await storedTokens(d)).toEqual({ accessToken: 'access-1', refreshToken: 'refresh-1' });
    expect(d.links.links[UID]?.session?.linkedAt.toISOString()).toBe('2026-10-01T08:00:00.000Z');
  });

  it('keeps the old refresh token when PnP does not rotate it', async () => {
    const d = await linked(past);
    d.login.rotate = false;
    await withPnpSession(d, UID, (token) => Promise.resolve(token));
    expect((await storedTokens(d))?.refreshToken).toBe('refresh-0');
  });

  it('after one unauthorised answer, refreshes and tries once more', async () => {
    const d = await linked(future);
    const seen: string[] = [];
    const result = await withPnpSession(d, UID, (token) => {
      seen.push(token);
      return token === 'access-0' ? Promise.reject(new PnpSessionExpired()) : Promise.resolve('ok');
    });
    expect(result).toBe('ok');
    expect(seen).toEqual(['access-0', 'access-1']);
  });

  it('a second unauthorised answer means the link has expired', async () => {
    const d = await linked(future);
    await expect(
      withPnpSession(d, UID, () => Promise.reject(new PnpSessionExpired())),
    ).rejects.toSatisfy((e) => reasonOf(e) === 'pnp-link-expired');
  });

  it('a refresh PnP refuses means the link has expired', async () => {
    const d = await linked(past);
    d.login.refuseRefresh = true;
    await expect(withPnpSession(d, UID, () => Promise.resolve(1))).rejects.toSatisfy(
      (e) => reasonOf(e) === 'pnp-link-expired',
    );
  });

  it('no link, or a link sealed under another key, is expired', async () => {
    const empty = {
      links: new MemoryPnpLinks(),
      login: new ScriptedPnpLogin(),
      key: KEY,
      now: NOW,
    };
    await expect(withPnpSession(empty, UID, () => Promise.resolve(1))).rejects.toSatisfy(
      (e) => reasonOf(e) === 'pnp-link-expired',
    );
    const d = await linked(future);
    const otherKey = { ...d, key: Buffer.alloc(32, 1) };
    await expect(withPnpSession(otherKey, UID, () => Promise.resolve(1))).rejects.toSatisfy(
      (e) => reasonOf(e) === 'pnp-link-expired',
    );
  });
});

/** [login], with its refresh replaced by [refresh] — to put an unlink or a rival refresh in the middle. */
function withRefresh(
  login: ScriptedPnpLogin,
  refresh: (refreshToken: string) => Promise<PnpTokens>,
): PnpLogin {
  return {
    client: (): Promise<PnpClient> => login.client(),
    exchangeCode: (code: string, verifier: string): Promise<PnpTokens> =>
      login.exchangeCode(code, verifier),
    refresh,
  };
}

describe('a refresh never undoes an unlink, and never loses a rotated token', () => {
  it('an unlink that lands while a refresh is with PnP stays unlinked', async () => {
    const d = await linked(past);
    const login = d.login;
    // PnP answers the refresh only after the member has unlinked.
    const unlinkFirst = {
      ...d,
      login: withRefresh(login, async (token: string) => {
        await d.links.remove(UID);
        return login.refresh(token);
      }),
    };
    await expect(withPnpSession(unlinkFirst, UID, () => Promise.resolve(1))).rejects.toSatisfy(
      (e) => reasonOf(e) === 'pnp-link-expired',
    );
    expect(d.links.links[UID]).toBeUndefined();
  });

  it('two refreshes at once: the second uses the first one’s tokens, and the rotated token is kept', async () => {
    const d = await linked(past);
    const [first, second] = await Promise.all([
      withPnpSession(d, UID, (token) => Promise.resolve(token)),
      withPnpSession(d, UID, (token) => Promise.resolve(token)),
    ]);
    const stored = await storedTokens(d);
    expect(stored?.refreshToken).toMatch(/^refresh-\d$/);
    expect(stored?.refreshToken).not.toBe('refresh-0');
    // Each call ran with a token that is, or was, the stored one — never a dropped one.
    expect([first, second]).toContain(stored?.accessToken);
    // PnP spent refresh-0 on the first refresh and refused it on the second;
    // the second still worked, on the first one's tokens.
    expect(first).toBe(second);
  });

  it('a refresh PnP refuses because another one already rotated the token uses the winner', async () => {
    const d = await linked(past);
    const winner = await sealSessionTokens(KEY, UID, {
      accessToken: 'access-won',
      refreshToken: 'refresh-won',
    });
    const login = d.login;
    const racing = {
      ...d,
      login: withRefresh(login, () => {
        const session = d.links.links[UID]?.session;
        if (session !== undefined && session !== null) {
          d.links.links[UID] = {
            pending: null,
            session: { ...session, sealed: winner, accessExpiresAt: future },
          };
        }
        return Promise.reject(new PnpSessionExpired());
      }),
    };
    expect(await withPnpSession(racing, UID, (token) => Promise.resolve(token))).toBe('access-won');
    expect((await storedTokens(d))?.refreshToken).toBe('refresh-won');
  });

  it('a refresh whose session was replaced meanwhile drops its own tokens and uses the stored ones', async () => {
    const d = await linked(past);
    const winner = await sealSessionTokens(KEY, UID, {
      accessToken: 'access-won',
      refreshToken: 'refresh-won',
    });
    const login = d.login;
    const racing = {
      ...d,
      login: withRefresh(login, async (token: string) => {
        const session = d.links.links[UID]?.session;
        if (session !== undefined && session !== null) {
          d.links.links[UID] = { pending: null, session: { ...session, sealed: winner } };
        }
        return login.refresh(token);
      }),
    };
    expect(await withPnpSession(racing, UID, (token) => Promise.resolve(token))).toBe('access-won');
    expect((await storedTokens(d))?.refreshToken).toBe('refresh-won');
  });
});

describe('what a sealed value is for is part of the seal (ADR-0003)', () => {
  it('tokens sealed for a pending link, or with the bare uid as Checkers does, never open as a session', async () => {
    const tokens = { accessToken: 'a', refreshToken: 'r' };
    const asPending = await sealLinkSecrets(KEY, UID, { verifier: 'a', state: 'r', nonce: 'n' });
    const bareUid = await sealJson(KEY, UID, tokens);
    expect(await openSessionTokens(KEY, UID, asPending)).toBeNull();
    expect(await openSessionTokens(KEY, UID, bareUid)).toBeNull();
    expect(await openSessionTokens(KEY, UID, await sealSessionTokens(KEY, UID, tokens))).toEqual(
      tokens,
    );
  });
});
