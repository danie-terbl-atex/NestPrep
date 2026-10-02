import { randomBytes } from 'node:crypto';

import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { CheckersUnavailable } from '../../../src/checkers/checkers_api';
import { linkStatusOf } from '../../../src/checkers/link_status';
import { maskMobile, normaliseSaMobile } from '../../../src/checkers/mobile_number';
import {
  MAX_CODE_ATTEMPTS,
  requestLinkOtp,
  verifyLinkOtp,
  type CodeRequestDeps,
} from '../../../src/checkers/otp_link';
import { openSession, sealPending } from '../../../src/checkers/sealed_values';
import { ACCOUNT, KEY, MOBILE, MemoryLinkStore, NOW, ScriptedLogin } from './fakes';

/**
 * Linking a member's Checkers account by SMS code (the Checkers build
 * contract): a code only to a real SA mobile and within the limits, the
 * number and session sealed at rest, five tries per code, and every refusal
 * told apart by its reason (BE-14).
 */

const UID = 'uid-sam';

function deps(overrides: Partial<CodeRequestDeps> = {}): CodeRequestDeps & {
  links: MemoryLinkStore;
  login: ScriptedLogin;
} {
  return {
    links: new MemoryLinkStore(),
    login: new ScriptedLogin(),
    key: KEY,
    now: NOW,
    allowCode: () => Promise.resolve(true),
    ...overrides,
  } as CodeRequestDeps & { links: MemoryLinkStore; login: ScriptedLogin };
}

function reasonOf(error: unknown): unknown {
  return error instanceof HttpsError ? (error.details as { reason: string }).reason : error;
}

async function refusal(promise: Promise<unknown>): Promise<unknown> {
  try {
    await promise;
  } catch (error) {
    return reasonOf(error);
  }
  throw new Error('expected a refusal');
}

describe('a South African mobile number', () => {
  it.each([
    ['082 123 4567', MOBILE],
    ['+27 82 123 4567', MOBILE],
    ['27821234567', MOBILE],
    ['(082) 123-4567', MOBILE],
    ['0712345678', '+27712345678'],
  ])('reads %s as %s', (typed, e164) => {
    expect(normaliseSaMobile(typed)).toBe(e164);
  });

  it.each([
    ['a landline', '021 123 4567'],
    ['a number one digit short', '082 123 456'],
    ['another country', '+44 7911 123456'],
    ['letters', 'call me'],
  ])('refuses %s', (_, typed) => {
    expect(normaliseSaMobile(typed)).toBeNull();
  });

  it('is shown and stored with only its last four digits', () => {
    expect(maskMobile(MOBILE)).toBe('+27 ** *** 4567');
  });
});

describe('asking for a code', () => {
  it('sends it and keeps the pending code sealed, with no whole number anywhere in the link', async () => {
    const run = deps();
    const answer = await requestLinkOtp(run, UID, '082 123 4567');
    expect(answer).toEqual({ sent: true, mobileMasked: '+27 ** *** 4567' });
    expect(run.login.codesSent).toEqual([MOBILE]);
    const link = run.links.links[UID];
    expect(link?.pending?.attempts).toBe(0);
    expect(link?.pending?.expiresAt.getTime()).toBe(NOW.getTime() + 10 * 60_000);
    expect(JSON.stringify(link)).not.toContain('821234567');
    expect(link?.deviceId).toMatch(/^[0-9a-f]{16}$/);
  });

  it('keeps the same install id on a second ask, as the app does', async () => {
    const run = deps();
    await requestLinkOtp(run, UID, MOBILE);
    const first = run.links.links[UID]?.deviceId;
    await requestLinkOtp(run, UID, MOBILE);
    expect(run.links.links[UID]?.deviceId).toBe(first);
  });

  it('refuses a number that is not a South African mobile, and sends nothing', async () => {
    const run = deps();
    expect(await refusal(requestLinkOtp(run, UID, '021 123 4567'))).toBe('bad-mobile');
    expect(run.login.codesSent).toEqual([]);
  });

  it('refuses past the limit, and sends nothing', async () => {
    const run = deps({ allowCode: () => Promise.resolve(false) });
    expect(await refusal(requestLinkOtp(run, UID, MOBILE))).toBe('otp-rate-limited');
    expect(run.login.codesSent).toEqual([]);
  });

  it('says bad-mobile when Checkers will not send to the number', async () => {
    const run = deps();
    run.login.refuseNumber = true;
    expect(await refusal(requestLinkOtp(run, UID, MOBILE))).toBe('bad-mobile');
    expect(run.links.links[UID]).toBeUndefined();
  });

  it('says checkers-down when Checkers cannot be reached', async () => {
    const run = deps();
    run.login.failWith = new CheckersUnavailable('status 503');
    expect(await refusal(requestLinkOtp(run, UID, MOBILE))).toBe('checkers-down');
  });
});

describe('verifying the code', () => {
  async function sent(): Promise<ReturnType<typeof deps>> {
    const run = deps();
    await requestLinkOtp(run, UID, MOBILE);
    return run;
  }

  it('links the account for the hour, a minute early, with the session sealed', async () => {
    const run = await sent();
    const answer = await verifyLinkOtp(run, UID, '1234');
    const expiresAt = new Date(NOW.getTime() + 59 * 60_000).toISOString();
    expect(answer).toEqual({ linked: true, expiresAt, mobileMasked: '+27 ** *** 4567' });
    const session = run.links.links[UID]?.session;
    expect(session?.sealed).not.toContain('session-token');
    expect(await openSession(KEY, UID, session?.sealed ?? '')).toEqual(ACCOUNT.session);
    expect(run.links.links[UID]?.pending).toBeNull();
    expect(linkStatusOf(run.links.links[UID] ?? null, NOW).linked).toBe(true);
  });

  it('refuses a wrong code, and counts it', async () => {
    const run = await sent();
    expect(await refusal(verifyLinkOtp(run, UID, '9999'))).toBe('wrong-code');
    expect(run.links.links[UID]?.pending?.attempts).toBe(1);
    expect(run.links.links[UID]?.session).toBeNull();
  });

  it(`throws the code away after ${String(MAX_CODE_ATTEMPTS)} tries, even a right one after`, async () => {
    const run = await sent();
    for (let attempt = 0; attempt < MAX_CODE_ATTEMPTS; attempt += 1) {
      expect(await refusal(verifyLinkOtp(run, UID, '9999'))).toBe('wrong-code');
    }
    expect(await refusal(verifyLinkOtp(run, UID, '1234'))).toBe('no-pending-otp');
  });

  it('refuses when no code was asked for', async () => {
    expect(await refusal(verifyLinkOtp(deps(), UID, '1234'))).toBe('no-pending-otp');
  });

  it('refuses a code asked for more than ten minutes ago', async () => {
    const run = await sent();
    const later = { ...run, now: new Date(NOW.getTime() + 11 * 60_000) };
    expect(await refusal(verifyLinkOtp(later, UID, '1234'))).toBe('no-pending-otp');
  });

  it('refuses a pending code sealed for another member', async () => {
    const run = deps();
    await run.links.savePending(UID, 'device', {
      sealed: await sealPending(KEY, 'uid-someone-else', {
        mobile: MOBILE,
        reference: 'r',
        route: 'bff',
      }),
      expiresAt: new Date(NOW.getTime() + 60_000),
      attempts: 0,
      mobileMasked: '+27 ** *** 4567',
    });
    expect(await refusal(verifyLinkOtp(run, UID, '1234'))).toBe('no-pending-otp');
  });

  it('refuses a pending code sealed under another key', async () => {
    const run = await sent();
    expect(await refusal(verifyLinkOtp({ ...run, key: randomBytes(32) }, UID, '1234'))).toBe(
      'no-pending-otp',
    );
  });

  it('says checkers-down when Checkers cannot be reached', async () => {
    const run = await sent();
    run.login.failWith = new CheckersUnavailable('network: TimeoutError');
    expect(await refusal(verifyLinkOtp(run, UID, '1234'))).toBe('checkers-down');
  });
});

describe('the link status', () => {
  it('is not linked with no link at all', () => {
    expect(linkStatusOf(null, NOW)).toEqual({ linked: false, expiresAt: null, mobileMasked: null });
  });

  it('is not linked once the hour is up, and still names the number', () => {
    const link = {
      deviceId: 'd',
      pending: null,
      session: {
        sealed: 'x',
        expiresAt: NOW,
        storeContexts: [],
        mobileMasked: '+27 ** *** 4567',
      },
    };
    expect(linkStatusOf(link, NOW)).toEqual({
      linked: false,
      expiresAt: null,
      mobileMasked: '+27 ** *** 4567',
    });
  });
});
