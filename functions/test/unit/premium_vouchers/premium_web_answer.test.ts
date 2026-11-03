import type { Firestore } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';

import { emailHashOf } from '../../../src/premium_vouchers/premium_hashes';
import {
  PREMIUM_WEB_OVERALL,
  PREMIUM_WEB_PER_ADDRESS,
  PREMIUM_WEB_PER_EMAIL,
} from '../../../src/premium_vouchers/premium_web_limits';
import {
  type PremiumWebDeps,
  type WebRequest,
  WEB_ERROR_STATUS,
  answerPremiumWeb,
  routeOf,
} from '../../../src/premium_vouchers/premium_web_answer';
import type { RateLimitRule } from '../../../src/shared/rate_limit';

const PEPPER = 'test-pepper';
const TOKEN = 'A'.repeat(43);

const untouchable = new Proxy(
  {},
  {
    get(): never {
      throw new Error('the store was reached');
    },
  },
) as Firestore;

interface Recorder {
  readonly deps: PremiumWebDeps;
  readonly asked: { rule: string; subject: string }[];
}

function recording(refuse: (rule: RateLimitRule) => boolean = () => false): Recorder {
  const asked: { rule: string; subject: string }[] = [];
  return {
    asked,
    deps: {
      store: untouchable,
      pepper: () => PEPPER,
      address: '203.0.113.9',
      now: new Date('2026-11-10T10:00:00Z'),
      consume: async (rule, subject): Promise<boolean> => {
        asked.push({ rule: rule.name, subject });
        return Promise.resolve(!refuse(rule));
      },
    },
  };
}

const post = (path: string, body: unknown): WebRequest => ({ method: 'POST', path, body });

describe('the routes', () => {
  it('are read behind Hosting’s /api/premium prefix and on the function’s own URL', () => {
    expect(routeOf('/api/premium/gift/lookup')).toBe('/gift/lookup');
    expect(routeOf('/api/premium/gift/reassign/')).toBe('/gift/reassign');
    expect(routeOf('/redeem')).toBe('/redeem');
    expect(routeOf('/api/premiumx/redeem')).toBeNull();
    expect(routeOf('/api/premium/other')).toBeNull();
  });

  it('answer only POST', async () => {
    const reply = await answerPremiumWeb(recording().deps, {
      method: 'GET',
      path: '/api/premium/redeem',
      body: undefined,
    });
    expect(reply).toEqual({ status: 405, body: { error: 'methodNotAllowed' } });
  });

  it('answer 404 for a path that is not one', async () => {
    const reply = await answerPremiumWeb(recording().deps, post('/api/premium/admin', {}));
    expect(reply).toEqual({ status: 404, body: { error: 'notFound' } });
  });
});

describe('the rate limits', () => {
  it('count every request overall and per address, before anything is read', async () => {
    const { deps, asked } = recording();
    await answerPremiumWeb(deps, post('/api/premium/gift/lookup', 'not even json'));
    expect(asked).toEqual([
      { rule: PREMIUM_WEB_OVERALL.name, subject: 'all' },
      { rule: PREMIUM_WEB_PER_ADDRESS.name, subject: '203.0.113.9' },
    ]);
  });

  for (const rule of [PREMIUM_WEB_OVERALL, PREMIUM_WEB_PER_ADDRESS]) {
    it(`answer 429 tooManyTries past ${rule.name}`, async () => {
      const { deps } = recording((asked) => asked.name === rule.name);
      const reply = await answerPremiumWeb(
        deps,
        post('/api/premium/gift/lookup', { token: TOKEN }),
      );
      expect(reply).toEqual({ status: 429, body: { error: 'tooManyTries' } });
    });
  }

  it('count an email by its hash, so changing its case or spaces changes nothing', async () => {
    const { deps, asked } = recording((rule) => rule.name === PREMIUM_WEB_PER_EMAIL.name);
    for (const email of ['Sam@Example.com', ' sam@example.COM ']) {
      const reply = await answerPremiumWeb(
        deps,
        post('/api/premium/redeem', { code: 'THANDI30', email }),
      );
      expect(reply).toEqual({ status: 429, body: { error: 'tooManyTries' } });
    }
    const subjects = asked
      .filter((entry) => entry.rule === PREMIUM_WEB_PER_EMAIL.name)
      .map((entry) => entry.subject);
    expect(new Set(subjects)).toEqual(new Set([await emailHashOf(PEPPER, 'sam@example.com')]));
    expect(subjects.join()).not.toContain('@');
  });

  it('count the new email of a reassign the same way', async () => {
    const { deps } = recording((rule) => rule.name === PREMIUM_WEB_PER_EMAIL.name);
    const reply = await answerPremiumWeb(
      deps,
      post('/api/premium/gift/reassign', { token: TOKEN, email: 'SAM@example.com' }),
    );
    expect(reply.status).toBe(429);
  });
});

describe('what a request is refused for before anything is looked up', () => {
  it.each([
    ['a lookup with no token', '/gift/lookup', {}, 'badRequest'],
    ['a lookup with a token far too long', '/gift/lookup', { token: 'a'.repeat(65) }, 'badRequest'],
    [
      'a lookup with a token of the wrong shape',
      '/gift/lookup',
      { token: 'short' },
      'voucherNotFound',
    ],
    [
      'a reassign with a token of the wrong shape',
      '/gift/reassign',
      { token: 'x', email: 'a@b.co' },
      'voucherNotFound',
    ],
    [
      'a reassign to something that is not an email',
      '/gift/reassign',
      { token: TOKEN, email: 'nope' },
      'badEmail',
    ],
    ['a reassign with no email', '/gift/reassign', { token: TOKEN }, 'badRequest'],
    ['a redeem with a code too short', '/redeem', { code: 'ab-', email: 'a@b.co' }, 'badCode'],
    [
      'a redeem with a code too long',
      '/redeem',
      { code: 'A'.repeat(21), email: 'a@b.co' },
      'badCode',
    ],
    [
      'a redeem with a body too long to be a code',
      '/redeem',
      { code: 'A'.repeat(65), email: 'a@b.co' },
      'badRequest',
    ],
    [
      'a redeem to something that is not an email',
      '/redeem',
      { code: 'THANDI30', email: 'nope' },
      'badEmail',
    ],
    [
      'a redeem with an email far too long',
      '/redeem',
      { code: 'THANDI30', email: `${'a'.repeat(400)}@b.co` },
      'badRequest',
    ],
  ] as const)('%s', async (_, route, body, error) => {
    const reply = await answerPremiumWeb(recording().deps, post(`/api/premium${route}`, body));
    expect(reply).toEqual({ status: WEB_ERROR_STATUS[error], body: { error } });
  });
});

describe('the status each refusal answers with', () => {
  it('is a 4xx for every refusal and 429 only for the rate limit', () => {
    for (const [error, status] of Object.entries(WEB_ERROR_STATUS)) {
      if (error === 'unavailable') continue;
      expect(status, error).toBeGreaterThanOrEqual(400);
      expect(status, error).toBeLessThan(500);
    }
    expect(WEB_ERROR_STATUS.tooManyTries).toBe(429);
  });
});
