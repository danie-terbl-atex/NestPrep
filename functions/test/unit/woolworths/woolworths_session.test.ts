import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import {
  WoolworthsSessionExpired,
  type WoolworthsTokens,
} from '../../../src/woolworths/woolworths_api';
import {
  openSessionTokens,
  sealSessionTokens,
  type WoolworthsSessionTokens,
} from '../../../src/woolworths/woolworths_sealed_values';
import { withWoolworthsSession } from '../../../src/woolworths/woolworths_session';
import { sealJson } from '../../../src/shared/sealed_json';
import { KEY, MemoryWoolworthsLinks, NOW, ScriptedWoolworthsLogin, UID } from './fakes';

interface Linked {
  readonly links: MemoryWoolworthsLinks;
  readonly login: ScriptedWoolworthsLogin;
  readonly key: Buffer;
  readonly now: Date;
}

const LINKED_AT = new Date('2026-11-01T08:00:00Z');

async function linked(idExpiresAt: Date): Promise<Linked> {
  const links = new MemoryWoolworthsLinks();
  links.links[UID] = {
    session: {
      sealed: await sealSessionTokens(KEY, UID, { refreshToken: 'refresh-0', idToken: 'id-0' }),
      idExpiresAt,
      linkedAt: LINKED_AT,
      emailMasked: 'd***@a***.io',
    },
  };
  return { links, login: new ScriptedWoolworthsLogin(), key: KEY, now: NOW };
}

const future = new Date(NOW.getTime() + 600_000);
const past = new Date(NOW.getTime() - 1);

function reasonOf(error: unknown): unknown {
  return error instanceof HttpsError ? (error.details as { reason?: string }).reason : error;
}

async function storedTokens(d: Linked): Promise<WoolworthsSessionTokens | null> {
  return openSessionTokens(KEY, UID, d.links.links[UID]?.session?.sealed ?? '');
}

describe('using the session', () => {
  it('uses a live IdToken as it is, refreshing nothing', async () => {
    const d = await linked(future);
    expect(await withWoolworthsSession(d, UID, (token) => Promise.resolve(token))).toBe('id-0');
    expect(d.login.refreshed).toEqual([]);
  });

  it('refreshes a lapsing IdToken first and keeps the refresh token Cognito did not rotate', async () => {
    const d = await linked(past);
    const used = await withWoolworthsSession(d, UID, (token) => Promise.resolve(token));
    expect(used).not.toBe('id-0');
    expect(d.login.refreshed).toEqual(['refresh-0']);
    const stored = await storedTokens(d);
    expect(stored).toEqual({ refreshToken: 'refresh-0', idToken: used });
    const session = d.links.links[UID]?.session;
    expect(session?.linkedAt).toEqual(LINKED_AT);
    expect(session?.emailMasked).toBe('d***@a***.io');
    expect(session?.idExpiresAt.getTime()).toBeGreaterThan(NOW.getTime());
  });

  it('keeps a rotated refresh token', async () => {
    const d = await linked(past);
    d.login.rotate = true;
    await withWoolworthsSession(d, UID, (token) => Promise.resolve(token));
    expect((await storedTokens(d))?.refreshToken).toBe('refresh-1');
  });

  it('after one 401, refreshes and tries once more', async () => {
    const d = await linked(future);
    const seen: string[] = [];
    const result = await withWoolworthsSession(d, UID, (token) => {
      seen.push(token);
      return token === 'id-0'
        ? Promise.reject(new WoolworthsSessionExpired())
        : Promise.resolve('ok');
    });
    expect(result).toBe('ok');
    expect(seen).toHaveLength(2);
    expect(d.login.refreshed).toEqual(['refresh-0']);
  });

  it('a second 401 means the link has expired', async () => {
    const d = await linked(future);
    await expect(
      withWoolworthsSession(d, UID, () => Promise.reject(new WoolworthsSessionExpired())),
    ).rejects.toSatisfy((e) => reasonOf(e) === 'woolworths-link-expired');
  });

  it('Cognito refusing the refresh token means the link has expired', async () => {
    const d = await linked(past);
    d.login.refuse = true;
    await expect(withWoolworthsSession(d, UID, () => Promise.resolve(1))).rejects.toSatisfy(
      (e) => reasonOf(e) === 'woolworths-link-expired',
    );
  });

  it('no link is woolworths-not-linked; one sealed under another key has expired', async () => {
    const empty = {
      links: new MemoryWoolworthsLinks(),
      login: new ScriptedWoolworthsLogin(),
      key: KEY,
      now: NOW,
    };
    await expect(withWoolworthsSession(empty, UID, () => Promise.resolve(1))).rejects.toSatisfy(
      (e) => reasonOf(e) === 'woolworths-not-linked',
    );
    const d = await linked(future);
    await expect(
      withWoolworthsSession({ ...d, key: Buffer.alloc(32, 1) }, UID, () => Promise.resolve(1)),
    ).rejects.toSatisfy((e) => reasonOf(e) === 'woolworths-link-expired');
  });
});

function withRefresh(refresh: (refreshToken: string) => Promise<WoolworthsTokens>): {
  refresh: (refreshToken: string) => Promise<WoolworthsTokens>;
} {
  return { refresh };
}

describe('a refresh is saved only over the session it opened (compare-and-swap)', () => {
  it('an unlink that lands while Cognito is answering stays unlinked', async () => {
    const d = await linked(past);
    const unlinkFirst = {
      ...d,
      login: withRefresh(async (token) => {
        await d.links.remove(UID);
        return d.login.refresh(token);
      }),
    };
    await expect(
      withWoolworthsSession(unlinkFirst, UID, () => Promise.resolve(1)),
    ).rejects.toSatisfy((e) => reasonOf(e) === 'woolworths-link-expired');
    expect(d.links.links[UID]).toBeUndefined();
  });

  it('a refresh whose session another refresh replaced uses the stored one', async () => {
    const d = await linked(past);
    const winner = await sealSessionTokens(KEY, UID, {
      refreshToken: 'refresh-won',
      idToken: 'id-won',
    });
    const racing = {
      ...d,
      login: withRefresh(async (token) => {
        const session = d.links.links[UID]?.session;
        if (session != null) d.links.links[UID] = { session: { ...session, sealed: winner } };
        return d.login.refresh(token);
      }),
    };
    expect(await withWoolworthsSession(racing, UID, (token) => Promise.resolve(token))).toBe(
      'id-won',
    );
    expect((await storedTokens(d))?.refreshToken).toBe('refresh-won');
  });

  it('a refresh Cognito refuses because a rival already rotated the token uses the winner', async () => {
    const d = await linked(past);
    const winner = await sealSessionTokens(KEY, UID, {
      refreshToken: 'refresh-won',
      idToken: 'id-won',
    });
    const racing = {
      ...d,
      login: withRefresh(() => {
        const session = d.links.links[UID]?.session;
        if (session != null) {
          d.links.links[UID] = { session: { ...session, sealed: winner, idExpiresAt: future } };
        }
        return Promise.reject(new WoolworthsSessionExpired());
      }),
    };
    expect(await withWoolworthsSession(racing, UID, (token) => Promise.resolve(token))).toBe(
      'id-won',
    );
  });

  it('two pushes at once with a rotating Cognito both run on the stored tokens', async () => {
    const d = await linked(past);
    d.login.rotate = true;
    const [first, second] = await Promise.all([
      withWoolworthsSession(d, UID, (token) => Promise.resolve(token)),
      withWoolworthsSession(d, UID, (token) => Promise.resolve(token)),
    ]);
    const stored = await storedTokens(d);
    expect(stored?.refreshToken).not.toBe('refresh-0');
    expect(first).toBe(second);
    expect(first).toBe(stored?.idToken);
  });
});

describe('what a sealed value is for is part of the seal', () => {
  it('tokens sealed under the bare uid, or for another shop, never open as a Woolworths session', async () => {
    const tokens = { refreshToken: 'r', idToken: 'i' };
    expect(await openSessionTokens(KEY, UID, await sealJson(KEY, UID, tokens))).toBeNull();
    expect(
      await openSessionTokens(KEY, UID, await sealJson(KEY, `pnp:session:${UID}`, tokens)),
    ).toBeNull();
    expect(await openSessionTokens(KEY, UID, await sealSessionTokens(KEY, UID, tokens))).toEqual(
      tokens,
    );
  });
});
