import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { WoolworthsUnavailable } from '../../../src/woolworths/woolworths_api';
import {
  ID_SKEW_SECONDS,
  idExpiryOf,
  maskedEmail,
} from '../../../src/woolworths/woolworths_id_token';
import {
  completeWoolworthsLink,
  woolworthsLinkStatusOf,
} from '../../../src/woolworths/woolworths_link';
import { openSessionTokens } from '../../../src/woolworths/woolworths_sealed_values';
import {
  KEY,
  MemoryWoolworthsLinks,
  NOW,
  ScriptedWoolworthsLogin,
  UID,
  fakeIdToken,
} from './fakes';

function deps(): {
  links: MemoryWoolworthsLinks;
  login: ScriptedWoolworthsLogin;
  key: Buffer;
  now: Date;
} {
  return {
    links: new MemoryWoolworthsLinks(),
    login: new ScriptedWoolworthsLogin(),
    key: KEY,
    now: NOW,
  };
}

function reasonOf(error: unknown): unknown {
  return error instanceof HttpsError ? (error.details as { reason?: string }).reason : error;
}

describe('completing a link', () => {
  it('proves the refresh token at Cognito, then seals it with the IdToken and keeps the masked email', async () => {
    const d = deps();
    const status = await completeWoolworthsLink(d, UID, 'phone-refresh');
    expect(status).toEqual({
      linked: true,
      linkedAt: NOW.toISOString(),
      emailMasked: 'd***@a***.io',
    });
    expect(d.login.refreshed).toEqual(['phone-refresh']);
    const session = d.links.links[UID]?.session;
    expect(session?.sealed).not.toContain('phone-refresh');
    const tokens = await openSessionTokens(KEY, UID, session?.sealed ?? '');
    expect(tokens?.refreshToken).toBe('phone-refresh');
    expect(tokens?.idToken.split('.')).toHaveLength(3);
    expect(session?.idExpiresAt.getTime()).toBe(NOW.getTime() + (86_400 - ID_SKEW_SECONDS) * 1000);
  });

  it('keeps a rotated refresh token when Cognito gives one', async () => {
    const d = deps();
    d.login.rotate = true;
    await completeWoolworthsLink(d, UID, 'phone-refresh');
    const tokens = await openSessionTokens(KEY, UID, d.links.links[UID]?.session?.sealed ?? '');
    expect(tokens?.refreshToken).toBe('refresh-1');
  });

  it('a token Cognito refuses is woolworths-link-rejected, and links nothing', async () => {
    const d = deps();
    d.login.refuse = true;
    await expect(completeWoolworthsLink(d, UID, 'bad')).rejects.toSatisfy(
      (e) => reasonOf(e) === 'woolworths-link-rejected',
    );
    expect(d.links.links[UID]).toBeUndefined();
  });

  it('Cognito not answering is woolworths-unavailable', async () => {
    const d = deps();
    d.login.failWith = new WoolworthsUnavailable('network: TimeoutError');
    await expect(completeWoolworthsLink(d, UID, 'phone-refresh')).rejects.toSatisfy(
      (e) => reasonOf(e) === 'woolworths-unavailable',
    );
  });

  it('an IdToken with no readable email links without one', async () => {
    const d = deps();
    d.login.email = 'not-an-email';
    expect(await completeWoolworthsLink(d, UID, 'phone-refresh')).toEqual({
      linked: true,
      linkedAt: NOW.toISOString(),
    });
  });
});

describe('link status', () => {
  it('is only linked while a session is held, and leaves out what it does not know', () => {
    expect(woolworthsLinkStatusOf(null)).toEqual({ linked: false });
    expect(woolworthsLinkStatusOf({ session: null })).toEqual({ linked: false });
  });
});

describe('the email, masked', () => {
  it.each([
    ['daniel@acme.io', 'd***@a***.io'],
    ['parent@oakstreet.nest', 'p***@o***.nest'],
    ['x@mail.co.za', 'x***@m***.co.za'],
    [' Sam@Example.com ', 'S***@E***.com'],
  ])('%s is %s', (email, masked) => {
    expect(maskedEmail(email)).toBe(masked);
  });

  it('is nothing for what is not an email', () => {
    expect(maskedEmail(undefined)).toBeNull();
    expect(maskedEmail('nobody')).toBeNull();
    expect(maskedEmail('a@b@c.io')).toBeNull();
  });
});

describe('when the IdToken is treated as lapsed', () => {
  it('a few minutes before its own exp, or from ExpiresIn when it carries none', () => {
    const exp = Math.floor(NOW.getTime() / 1000) + 3600;
    expect(
      idExpiryOf({ idToken: fakeIdToken({ exp }), refreshToken: null, expiresInSeconds: 60 }, NOW),
    ).toEqual(new Date((exp - ID_SKEW_SECONDS) * 1000));
    expect(
      idExpiryOf({ idToken: 'not.a-jwt', refreshToken: null, expiresInSeconds: 7200 }, NOW),
    ).toEqual(new Date(NOW.getTime() + (7200 - ID_SKEW_SECONDS) * 1000));
  });
});
