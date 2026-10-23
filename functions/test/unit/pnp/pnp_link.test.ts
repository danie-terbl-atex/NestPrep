import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { PnpUnavailable } from '../../../src/pnp/pnp_api';
import { PENDING_LINK_MINUTES, completePnpLink, startPnpLink } from '../../../src/pnp/pnp_link';
import { pnpLinkStatusOf } from '../../../src/pnp/pnp_link_state';
import { openLinkSecrets, openSessionTokens } from '../../../src/pnp/pnp_sealed_values';
import { CLIENT, KEY, MemoryPnpLinks, NOW, ScriptedPnpLogin, UID } from './fakes';

/**
 * Linking a member's Pick n Pay account on PnP's own login page (add-to-pnp
 * ADR-0003): the start keeps the verifier and state sealed on the server, the
 * completion takes the code once, with the right state, and seals the tokens.
 */
interface Deps {
  readonly links: MemoryPnpLinks;
  readonly login: ScriptedPnpLogin;
  readonly key: Buffer;
  readonly now: Date;
}

function deps(now = NOW): Deps {
  return { links: new MemoryPnpLinks(), login: new ScriptedPnpLogin(), key: KEY, now };
}

function reasonOf(error: unknown): unknown {
  return error instanceof HttpsError ? (error.details as { reason?: string }).reason : error;
}

async function started(): Promise<{ d: Deps; url: URL; state: string }> {
  const d = deps();
  const { authorizeUrl } = await startPnpLink(d, UID);
  const url = new URL(authorizeUrl);
  return { d, url, state: url.searchParams.get('state') ?? '' };
}

describe('starting a link', () => {
  it('answers PnP’s own authorize URL with PKCE, for the website’s redirect', async () => {
    const { url } = await started();
    expect(`${url.origin}${url.pathname}`).toBe(CLIENT.authorizeEndpoint);
    expect(url.searchParams.get('client_id')).toBe(CLIENT.clientId);
    expect(url.searchParams.get('redirect_uri')).toBe('https://www.pnp.co.za/oidc_login');
    expect(url.searchParams.get('scope')).toBe('openid offline_access');
    expect(url.searchParams.get('code_challenge_method')).toBe('S256');
    expect(url.searchParams.get('response_type')).toBe('code');
  });

  it('never puts the verifier or the client secret in the URL', async () => {
    const { d, url } = await started();
    const pending = d.links.links[UID]?.pending;
    const secrets = await openLinkSecrets(KEY, UID, pending?.sealed ?? '');
    expect(url.toString()).not.toContain(secrets?.verifier ?? 'missing');
    expect(url.toString()).not.toContain(CLIENT.clientSecret);
  });

  it('keeps the pending link sealed, for fifteen minutes', async () => {
    const { d, state } = await started();
    const pending = d.links.links[UID]?.pending;
    expect(pending?.sealed).not.toContain(state);
    expect(pending?.expiresAt.getTime()).toBe(NOW.getTime() + PENDING_LINK_MINUTES * 60_000);
  });

  it('is pnp-down when PnP’s client cannot be read', async () => {
    const d = deps();
    d.login.failWith = new PnpUnavailable('status 503');
    await expect(startPnpLink(d, UID)).rejects.toSatisfy((e) => reasonOf(e) === 'pnp-down');
  });
});

describe('completing a link', () => {
  it('swaps the code with the verifier and seals both tokens', async () => {
    const { d, state } = await started();
    const answer = await completePnpLink(d, UID, { code: 'good-code', state });
    expect(answer).toEqual({ linked: true, linkedAt: NOW.toISOString() });
    const session = d.links.links[UID]?.session;
    expect(session?.sealed).not.toContain('refresh-0');
    expect(await openSessionTokens(KEY, UID, session?.sealed ?? '')).toEqual({
      accessToken: 'access-1',
      refreshToken: 'refresh-0',
    });
    expect(d.login.exchanged[0]?.verifier).toHaveLength(43);
    expect(pnpLinkStatusOf(d.links.links[UID] ?? null)).toEqual({
      linked: true,
      linkedAt: NOW.toISOString(),
    });
  });

  it('refuses a state the start did not make, and asks PnP nothing', async () => {
    const { d } = await started();
    await expect(completePnpLink(d, UID, { code: 'good-code', state: 'forged' })).rejects.toSatisfy(
      (e) => reasonOf(e) === 'pnp-link-refused',
    );
    expect(d.login.exchanged).toEqual([]);
  });

  it('a start is used once: a second completion has nothing pending', async () => {
    const { d, state } = await started();
    await completePnpLink(d, UID, { code: 'good-code', state });
    await expect(completePnpLink(d, UID, { code: 'good-code', state })).rejects.toSatisfy(
      (e) => reasonOf(e) === 'pnp-no-pending-link',
    );
  });

  it('a start fifteen minutes old has lapsed', async () => {
    const { d, state } = await started();
    const later = { ...d, now: new Date(NOW.getTime() + (PENDING_LINK_MINUTES + 1) * 60_000) };
    await expect(completePnpLink(later, UID, { code: 'good-code', state })).rejects.toSatisfy(
      (e) => reasonOf(e) === 'pnp-no-pending-link',
    );
  });

  it('with no start at all there is nothing to complete', async () => {
    await expect(completePnpLink(deps(), UID, { code: 'good-code', state: 's' })).rejects.toSatisfy(
      (e) => reasonOf(e) === 'pnp-no-pending-link',
    );
  });

  it('a start sealed for somebody else does not open', async () => {
    const { d, state } = await started();
    const pending = d.links.links[UID]?.pending ?? null;
    d.links.links['uid-other'] = { pending, session: null };
    await expect(completePnpLink(d, 'uid-other', { code: 'good-code', state })).rejects.toSatisfy(
      (e) => reasonOf(e) === 'pnp-no-pending-link',
    );
  });

  it('a code PnP refuses is pnp-link-refused, and links nothing', async () => {
    const { d, state } = await started();
    await expect(completePnpLink(d, UID, { code: 'bad-code', state })).rejects.toSatisfy(
      (e) => reasonOf(e) === 'pnp-link-refused',
    );
    expect(d.links.links[UID]?.session ?? null).toBeNull();
  });

  it('tokens without a refresh token do not make a link', async () => {
    const { d, state } = await started();
    d.login.giveRefresh = false;
    await expect(completePnpLink(d, UID, { code: 'good-code', state })).rejects.toSatisfy(
      (e) => reasonOf(e) === 'pnp-link-refused',
    );
  });

  it('PnP not answering is pnp-down', async () => {
    const { d, state } = await started();
    d.login.failWith = new PnpUnavailable('network: TimeoutError');
    await expect(completePnpLink(d, UID, { code: 'good-code', state })).rejects.toSatisfy(
      (e) => reasonOf(e) === 'pnp-down',
    );
  });

  it('starting again keeps a session the member already has', async () => {
    const { d, state } = await started();
    await completePnpLink(d, UID, { code: 'good-code', state });
    await startPnpLink(d, UID);
    expect(d.links.links[UID]?.session).not.toBeNull();
    expect(d.links.links[UID]?.pending).not.toBeNull();
  });
});

describe('link status', () => {
  it('is not linked with no document or no session', () => {
    expect(pnpLinkStatusOf(null)).toEqual({ linked: false, linkedAt: null });
    expect(pnpLinkStatusOf({ pending: { sealed: 'x', expiresAt: NOW }, session: null })).toEqual({
      linked: false,
      linkedAt: null,
    });
  });
});
