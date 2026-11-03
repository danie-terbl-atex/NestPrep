import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import {
  type Attempt,
  type AttemptOutcome,
  type ChallengeStore,
  EMAIL_CODE_TRIES,
  EMAIL_CODE_WINDOW_MS,
  judgeAttempt,
  sentInWindow,
} from '../../../src/premium_vouchers/email_challenges';
import {
  EMAIL_CODES_PER_ACCOUNT_DAY,
  EMAIL_CODES_PER_ADDRESS,
  EMAIL_CODE_TRIES_PER_ADDRESS,
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
      return Promise.resolve(judgeAttempt(challenges.get(uid) ?? null, attempt, now));
    },
  };
  return {
    events,
    challenges,
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
      isWithin: async (rule): Promise<boolean> => {
        events.push(`check ${rule.name}`);
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
  const spentTries = (world: World): number =>
    world.events.filter((event) => event.startsWith(`consume ${EMAIL_CODE_TRIES_PER_ADDRESS.name}`))
      .length;

  it('spends nothing from the address’s try budget without a live challenge', async () => {
    const world = aWorld();
    for (let call = 0; call < 20; call += 1) {
      expect(
        await reasonOf(
          verifyEmailCode(world.deps, 'uid-stranger', { email: TARGET, code: '000000' }),
        ),
      ).toBe('emailCodeExpired');
    }
    expect(spentTries(world)).toBe(0);
  });

  it('spends a try on a wrong guess against a live challenge, and none on the right code', async () => {
    const world = aWorld();
    await sendEmailCode(world.deps, 'uid-1', TARGET);
    expect(
      await reasonOf(verifyEmailCode(world.deps, 'uid-1', { email: TARGET, code: '000000' })),
    ).toBe('emailCodeWrong');
    expect(spentTries(world)).toBe(1);
    await verifyEmailCode(world.deps, 'uid-1', { email: TARGET, code: '482913' });
    expect(spentTries(world)).toBe(1);
  });

  it('spends a try on a guess at a challenge already out of tries', async () => {
    const world = aWorld();
    await sendEmailCode(world.deps, 'uid-1', TARGET);
    const challenge = world.challenges.get('uid-1');
    if (challenge !== undefined) world.challenges.set('uid-1', { ...challenge, tries: 5 });
    expect(
      await reasonOf(verifyEmailCode(world.deps, 'uid-1', { email: TARGET, code: '482913' })),
    ).toBe('emailCodeTooManyTries');
    expect(spentTries(world)).toBe(1);
  });

  it('reads the address’s try budget before any challenge is looked at', async () => {
    const world = aWorld({ refuse: (rule) => rule.name === EMAIL_CODE_TRIES_PER_ADDRESS.name });
    await sendEmailCode(aWorld().deps, 'uid-1', TARGET);
    expect(
      await reasonOf(verifyEmailCode(world.deps, 'uid-1', { email: TARGET, code: '482913' })),
    ).toBe('emailCodeTooManyTries');
    expect(world.events.some((event) => event.startsWith('attempt'))).toBe(false);
  });

  it('verifies the code sent, for the email it was sent to', async () => {
    const world = aWorld();
    await sendEmailCode(world.deps, 'uid-1', TARGET);
    expect(await verifyEmailCode(world.deps, 'uid-1', { email: TARGET, code: '482913' })).toEqual({
      verified: true,
      emailMasked: 'b***@example.com',
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
