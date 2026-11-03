import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import {
  type Attempt,
  type AttemptOutcome,
  type ChallengeStore,
  EMAIL_CODE_TRIES,
  EMAIL_CODE_TRIES_PER_ADDRESS,
  EMAIL_CODE_WINDOW_MS,
  decideAttempt,
  judgeAttempt,
  sentInWindow,
} from '../../../src/premium_vouchers/email_challenges';
import {
  EMAIL_CODES_PER_ACCOUNT_DAY,
  EMAIL_CODES_PER_ADDRESS,
  type EmailCodeDeps,
  sendEmailCode,
  verifyEmailCode,
} from '../../../src/premium_vouchers/email_code';
import type { EmailMessage } from '../../../src/premium_vouchers/email_sender';
import { emailHashOf, otpHashOf } from '../../../src/premium_vouchers/premium_hashes';
import type { StoredChallenge } from '../../../src/premium_vouchers/voucher_documents';
import type { RateLimitRule } from '../../../src/shared/rate_limit';

const PEPPER = 'test-pepper';
const NOW = new Date('2026-11-10T10:00:00Z');
const TARGET = 'buyer@example.com';

interface World {
  readonly deps: EmailCodeDeps;
  readonly events: string[];
  readonly challenges: Map<string, StoredChallenge>;
  readonly triesSpent: Map<string, number>;
}

function aWorld(
  options: {
    refuse?: (rule: RateLimitRule) => boolean;
    sendFails?: boolean;
    sentThisHour?: number;
    proven?: string[];
  } = {},
): World {
  const events: string[] = [];
  const challenges = new Map<string, StoredChallenge>();
  const triesSpent = new Map<string, number>();
  const store: ChallengeStore = {
    sentThisHour: async () => Promise.resolve(options.sentThisHour ?? 0),
    record: async (uid, sent, now) => {
      events.push(`record ${uid}`);
      challenges.set(uid, {
        ...sent,
        expiresAt: new Date(now.getTime() + 10 * 60 * 1000),
        tries: 0,
        sentCount: 1,
        windowStart: now,
      });
      return Promise.resolve();
    },
    attempt: async (uid: string, attempt: Attempt, now: Date): Promise<AttemptOutcome> => {
      events.push(`attempt ${uid}`);
      const challenge = challenges.get(uid) ?? null;
      const spent = triesSpent.get(attempt.emailHash) ?? 0;
      const decision = decideAttempt(
        challenge,
        spent < EMAIL_CODE_TRIES_PER_ADDRESS.limit,
        attempt,
        now,
      );
      if (decision.addsChallengeTry && challenge !== null) {
        challenges.set(uid, { ...challenge, tries: challenge.tries + 1 });
      }
      if (decision.spendsAddressTry) triesSpent.set(attempt.emailHash, spent + 1);
      if (decision.outcome === 'verified') challenges.delete(uid);
      return Promise.resolve(decision.outcome);
    },
  };
  return {
    events,
    challenges,
    triesSpent,
    deps: {
      challenges: store,
      provenHashes: async () => Promise.resolve(options.proven ?? []),
      pepper: PEPPER,
      sender: {
        send: async (message: EmailMessage): Promise<void> => {
          events.push(`send ${message.to}`);
          if (options.sendFails === true) throw new Error('resend down');
          return Promise.resolve();
        },
      },
      newCode: () => '482913',
      consume: async (rule, subject): Promise<boolean> => {
        events.push(`consume ${rule.name} ${subject.includes('@') ? 'PLAIN EMAIL' : 'ok'}`);
        return Promise.resolve(!(options.refuse?.(rule) ?? false));
      },
      now: NOW,
    },
  };
}

async function reasonOf(promise: Promise<unknown>): Promise<string | undefined> {
  try {
    await promise;
    return undefined;
  } catch (error) {
    expect(error).toBeInstanceOf(HttpsError);
    return ((error as HttpsError).details as { reason?: string } | undefined)?.reason;
  }
}

describe('sending an email code', () => {
  it('spends both limits, then sends, and only then stores the challenge', async () => {
    const world = aWorld();
    await sendEmailCode(world.deps, 'uid-1', TARGET);
    expect(world.events).toEqual([
      `consume ${EMAIL_CODES_PER_ACCOUNT_DAY.name} ok`,
      `consume ${EMAIL_CODES_PER_ADDRESS.name} ok`,
      `send ${TARGET}`,
      'record uid-1',
    ]);
  });

  for (const rule of [EMAIL_CODES_PER_ACCOUNT_DAY, EMAIL_CODES_PER_ADDRESS]) {
    it(`stores no challenge when ${rule.name} refuses, so nothing can be guessed`, async () => {
      const world = aWorld({ refuse: (asked) => asked.name === rule.name });
      expect(await reasonOf(sendEmailCode(world.deps, 'uid-1', TARGET))).toBe('tooManyCodes');
      expect(world.events.some((event) => event.startsWith('send'))).toBe(false);
      expect(world.challenges.size).toBe(0);
      expect(
        await reasonOf(verifyEmailCode(world.deps, 'uid-1', { email: TARGET, code: '482913' })),
      ).toBe('emailCodeExpired');
    });
  }

  it('stores no challenge after three sends this hour, and spends no limit on it', async () => {
    const world = aWorld({ sentThisHour: 3 });
    expect(await reasonOf(sendEmailCode(world.deps, 'uid-1', TARGET))).toBe('tooManyCodes');
    expect(world.events).toEqual([]);
  });

  it('stores no challenge when the email is not accepted', async () => {
    const world = aWorld({ sendFails: true });
    await expect(sendEmailCode(world.deps, 'uid-1', TARGET)).rejects.toMatchObject({
      code: 'unavailable',
    });
    expect(world.challenges.size).toBe(0);
    expect(
      await reasonOf(verifyEmailCode(world.deps, 'uid-1', { email: TARGET, code: '482913' })),
    ).toBe('emailCodeExpired');
  });

  it('refuses an email the account has already proved, before anything else', async () => {
    const world = aWorld({ proven: [await emailHashOf(PEPPER, TARGET)] });
    expect(await reasonOf(sendEmailCode(world.deps, 'uid-1', TARGET))).toBe('emailAlreadyVerified');
    expect(world.events).toEqual([]);
  });

  it('counts an address by its hash, never the address', async () => {
    const world = aWorld();
    await sendEmailCode(world.deps, 'uid-1', TARGET);
    expect(world.events.join()).not.toContain('PLAIN EMAIL');
  });
});

describe('verifying an email code', () => {
  const spent = async (world: World, email: string): Promise<number> =>
    world.triesSpent.get(await emailHashOf(PEPPER, email)) ?? 0;
  const verify = async (
    world: World,
    uid: string,
    email: string,
    code: string,
  ): Promise<string | undefined> => reasonOf(verifyEmailCode(world.deps, uid, { email, code }));

  it('spends nothing from an address’s budget without a live challenge', async () => {
    const world = aWorld();
    for (let call = 0; call < 20; call += 1) {
      expect(await verify(world, 'uid-stranger', TARGET, '000000')).toBe('emailCodeExpired');
    }
    expect(await spent(world, TARGET)).toBe(0);
  });

  it('spends a try only on a wrong code for the email the challenge was sent to', async () => {
    const world = aWorld();
    await sendEmailCode(world.deps, 'uid-1', TARGET);
    expect(await verify(world, 'uid-1', TARGET, '000000')).toBe('emailCodeWrong');
    expect(await spent(world, TARGET)).toBe(1);
    expect(await verifyEmailCode(world.deps, 'uid-1', { email: TARGET, code: '482913' })).toEqual({
      verified: true,
      emailMasked: 'b***@example.com',
    });
    expect(await spent(world, TARGET)).toBe(1);
  });

  it('never spends the typed email’s budget for a challenge sent to another email', async () => {
    const world = aWorld();
    await sendEmailCode(world.deps, 'uid-attacker', 'attacker@example.com');
    for (let call = 0; call < 12; call += 1) {
      await verify(world, 'uid-attacker', TARGET, '000000');
    }
    expect(await spent(world, TARGET)).toBe(0);
    expect(await spent(world, 'attacker@example.com')).toBe(0);
  });

  it('never spends a budget for a challenge stuck out of tries', async () => {
    const world = aWorld();
    await sendEmailCode(world.deps, 'uid-1', TARGET);
    for (let call = 0; call < EMAIL_CODE_TRIES; call += 1) {
      await verify(world, 'uid-1', TARGET, '000000');
    }
    expect(await spent(world, TARGET)).toBe(EMAIL_CODE_TRIES);
    for (let call = 0; call < 10; call += 1) {
      expect(await verify(world, 'uid-1', TARGET, '000000')).toBe('emailCodeTooManyTries');
    }
    expect(await spent(world, TARGET)).toBe(EMAIL_CODE_TRIES);
    await sendEmailCode(world.deps, 'uid-owner', TARGET);
    expect(
      await verifyEmailCode(world.deps, 'uid-owner', { email: TARGET, code: '482913' }),
    ).toMatchObject({ verified: true });
  });

  it('refuses every attempt for an address whose budget is spent, the right code included', async () => {
    const world = aWorld();
    world.triesSpent.set(await emailHashOf(PEPPER, TARGET), EMAIL_CODE_TRIES_PER_ADDRESS.limit);
    await sendEmailCode(world.deps, 'uid-1', TARGET);
    expect(await verify(world, 'uid-1', TARGET, '482913')).toBe('emailCodeTooManyTries');
    expect(world.challenges.get('uid-1')?.tries).toBe(0);
  });
});

describe('deciding one attempt', () => {
  const emailHash = 'e'.repeat(64);
  const codeHash = 'c'.repeat(64);
  const live: StoredChallenge = {
    emailHash,
    codeHash,
    expiresAt: new Date(NOW.getTime() + 60_000),
    tries: 0,
    sentCount: 1,
    windowStart: NOW,
  };

  it('counts against the address only a wrong code for that address', () => {
    expect(decideAttempt(live, true, { emailHash, codeHash: 'd'.repeat(64) }, NOW)).toEqual({
      outcome: 'emailCodeWrong',
      addsChallengeTry: true,
      spendsAddressTry: true,
    });
    expect(decideAttempt(live, true, { emailHash: 'f'.repeat(64), codeHash }, NOW)).toEqual({
      outcome: 'emailCodeWrong',
      addsChallengeTry: true,
      spendsAddressTry: false,
    });
  });

  it('counts nothing for no challenge, a stuck one, an expired one, a spent budget or the right code', () => {
    const nothing = { addsChallengeTry: false, spendsAddressTry: false };
    expect(decideAttempt(null, true, { emailHash, codeHash }, NOW)).toEqual({
      outcome: 'emailCodeExpired',
      ...nothing,
    });
    expect(decideAttempt({ ...live, tries: 5 }, true, { emailHash, codeHash }, NOW)).toEqual({
      outcome: 'emailCodeTooManyTries',
      ...nothing,
    });
    expect(decideAttempt({ ...live, expiresAt: NOW }, true, { emailHash, codeHash }, NOW)).toEqual({
      outcome: 'emailCodeExpired',
      ...nothing,
    });
    expect(decideAttempt(live, false, { emailHash, codeHash }, NOW)).toEqual({
      outcome: 'emailCodeTooManyTries',
      ...nothing,
    });
    expect(decideAttempt(live, true, { emailHash, codeHash }, NOW)).toEqual({
      outcome: 'verified',
      ...nothing,
    });
  });
});

describe('judging one attempt', () => {
  const emailHash = 'e'.repeat(64);
  const codeHash = 'c'.repeat(64);
  const live: StoredChallenge = {
    emailHash,
    codeHash,
    expiresAt: new Date(NOW.getTime() + 60_000),
    tries: 0,
    sentCount: 1,
    windowStart: NOW,
  };

  it('is expired with no challenge, or past its expiry', () => {
    expect(judgeAttempt(null, { emailHash, codeHash }, NOW)).toBe('emailCodeExpired');
    expect(judgeAttempt({ ...live, expiresAt: NOW }, { emailHash, codeHash }, NOW)).toBe(
      'emailCodeExpired',
    );
  });

  it('allows five tries per code', () => {
    expect(judgeAttempt({ ...live, tries: EMAIL_CODE_TRIES }, { emailHash, codeHash }, NOW)).toBe(
      'emailCodeTooManyTries',
    );
    expect(EMAIL_CODE_TRIES).toBe(5);
  });

  it('needs both the code and the email to match', async () => {
    expect(judgeAttempt(live, { emailHash, codeHash }, NOW)).toBe('verified');
    expect(judgeAttempt(live, { emailHash, codeHash: 'd'.repeat(64) }, NOW)).toBe('emailCodeWrong');
    expect(judgeAttempt(live, { emailHash: 'f'.repeat(64), codeHash }, NOW)).toBe('emailCodeWrong');
    expect(await otpHashOf(PEPPER, 'uid-1', '482913')).not.toBe(
      await otpHashOf(PEPPER, 'uid-2', '482913'),
    );
  });

  it('counts sends inside the hour that began with the first', () => {
    expect(sentInWindow(null, NOW)).toBe(0);
    expect(sentInWindow({ ...live, sentCount: 3 }, NOW)).toBe(3);
    const old = new Date(NOW.getTime() - EMAIL_CODE_WINDOW_MS);
    expect(sentInWindow({ ...live, sentCount: 3, windowStart: old }, NOW)).toBe(0);
  });
});

describe('the limits', () => {
  it('are a daily cap per account, five sends and ten tries an hour per address', () => {
    expect(EMAIL_CODES_PER_ACCOUNT_DAY).toMatchObject({ limit: 10, windowSeconds: 86_400 });
    expect(EMAIL_CODES_PER_ADDRESS).toMatchObject({ limit: 5, windowSeconds: 3_600 });
    expect(EMAIL_CODE_TRIES_PER_ADDRESS).toMatchObject({ limit: 10, windowSeconds: 3_600 });
  });
});
