import type { Firestore } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';

import { emailHashOf } from '../../../src/premium_vouchers/premium_hashes';
import {
  GIFT_LOOKUP_OVERALL,
  GIFT_LOOKUP_PER_ADDRESS,
  PREMIUM_WEB_OVERALL,
  PREMIUM_WEB_PER_ADDRESS,
  PREMIUM_WEB_PER_EMAIL,
} from '../../../src/premium_vouchers/premium_web_limits';
import {
  type PremiumWebDeps,
  type WebRequest,
  WEB_ERROR_STATUS,
  WEB_ROUTE_REFUSALS,
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
  readonly peeked: { rule: string; subject: string }[];
}

function recording(refuse: (rule: RateLimitRule) => boolean = () => false): Recorder {
  const asked: { rule: string; subject: string }[] = [];
  const peeked: { rule: string; subject: string }[] = [];
  return {
    asked,
    peeked,
    deps: {
      store: untouchable,
      pepper: () => PEPPER,
      address: '203.0.113.9',
      now: new Date('2026-11-10T10:00:00Z'),
      consume: async (rule, subject): Promise<boolean> => {
        asked.push({ rule: rule.name, subject });
        return Promise.resolve(!refuse(rule));
      },
      isWithin: async (rule, subject): Promise<boolean> => {
        peeked.push({ rule: rule.name, subject });
        return Promise.resolve(!refuse(rule));
      },
    },
  };
}

function counting(): { deps: PremiumWebDeps; used: Map<string, number> } {
  const used = new Map<string, number>();
  const limits = [
    GIFT_LOOKUP_OVERALL,
    GIFT_LOOKUP_PER_ADDRESS,
    PREMIUM_WEB_OVERALL,
    PREMIUM_WEB_PER_ADDRESS,
    PREMIUM_WEB_PER_EMAIL,
  ];
  const limitOf = (rule: RateLimitRule): number =>
    limits.find((known) => known.name === rule.name)?.limit ?? 0;
  return {
    used,
    deps: {
      store: untouchable,
      pepper: () => PEPPER,
      address: '203.0.113.9',
      now: new Date('2026-11-10T10:00:00Z'),
      consume: async (rule, subject): Promise<boolean> => {
        const key = `${rule.name} ${subject}`;
        const count = used.get(key) ?? 0;
        if (count >= limitOf(rule)) return Promise.resolve(false);
        used.set(key, count + 1);
        return Promise.resolve(true);
      },
      isWithin: async (rule, subject): Promise<boolean> =>
        Promise.resolve((used.get(`${rule.name} ${subject}`) ?? 0) < limitOf(rule)),
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
  it('count the address first, and nothing overall for a request refused before any work', async () => {
    const { deps, asked } = recording();
    await answerPremiumWeb(deps, post('/api/premium/gift/lookup', 'not even json'));
    await answerPremiumWeb(deps, post('/api/premium/redeem', { code: 'ab', email: 'a@b.co' }));
    expect(asked).toEqual([
      { rule: GIFT_LOOKUP_PER_ADDRESS.name, subject: '203.0.113.9' },
      { rule: PREMIUM_WEB_PER_ADDRESS.name, subject: '203.0.113.9' },
    ]);
  });

  it('let one address take only its own places from the overall budget', async () => {
    const { deps, used } = counting();
    for (let call = 0; call < 31; call += 1) {
      await answerPremiumWeb(
        deps,
        post('/api/premium/gift/reassign', { token: 'short', email: 'a@b.co' }),
      );
    }
    expect(used.get(`${PREMIUM_WEB_PER_ADDRESS.name} 203.0.113.9`)).toBe(30);
    expect(used.get(`${PREMIUM_WEB_OVERALL.name} all`) ?? 0).toBe(0);
    const last = await answerPremiumWeb(
      deps,
      post('/api/premium/gift/reassign', { token: TOKEN, email: 'a@b.co' }),
    );
    expect(last).toEqual({ status: 429, body: { error: 'tooManyTries' } });
    expect(used.get(`${PREMIUM_WEB_OVERALL.name} all`) ?? 0).toBe(0);
  });

  it('keep gift links on their own, higher, ceilings, so guessing codes cannot close them', async () => {
    expect(GIFT_LOOKUP_PER_ADDRESS.limit).toBeGreaterThan(PREMIUM_WEB_PER_ADDRESS.limit);
    expect(GIFT_LOOKUP_OVERALL.limit).toBeGreaterThan(PREMIUM_WEB_OVERALL.limit);
    expect(
      new Set([GIFT_LOOKUP_OVERALL.name, GIFT_LOOKUP_PER_ADDRESS.name]).has(
        PREMIUM_WEB_OVERALL.name,
      ),
    ).toBe(false);
    const { deps } = recording(
      (rule) =>
        rule.name === PREMIUM_WEB_OVERALL.name || rule.name === PREMIUM_WEB_PER_ADDRESS.name,
    );
    const redeem = await answerPremiumWeb(
      deps,
      post('/api/premium/redeem', { code: 'THANDI30', email: 'a@b.co' }),
    );
    expect(redeem.status).toBe(429);
    const lookup = await answerPremiumWeb(
      deps,
      post('/api/premium/gift/lookup', { token: 'short' }),
    );
    expect(lookup).toEqual({ status: 404, body: { error: 'voucherNotFound' } });
  });

  for (const [route, perAddress, overall, body] of [
    ['/gift/lookup', GIFT_LOOKUP_PER_ADDRESS, GIFT_LOOKUP_OVERALL, { token: TOKEN }],
    [
      '/redeem',
      PREMIUM_WEB_PER_ADDRESS,
      PREMIUM_WEB_OVERALL,
      { code: 'THANDI30', email: 'a@b.co' },
    ],
  ] as const) {
    for (const rule of [perAddress, overall]) {
      it(`answer ${route} 429 tooManyTries past ${rule.name}, before anything is read`, async () => {
        const { deps } = recording((asked) => asked.name === rule.name);
        const reply = await answerPremiumWeb(deps, post(`/api/premium${route}`, body));
        expect(reply).toEqual({ status: 429, body: { error: 'tooManyTries' } });
      });
    }
  }

  it('check a redeeming email by its hash before the overall budget, and spend it only on a refusal', async () => {
    const { deps, asked, peeked } = recording((rule) => rule.name === PREMIUM_WEB_PER_EMAIL.name);
    for (const email of ['Sam@Example.com', ' sam@example.COM ']) {
      const reply = await answerPremiumWeb(
        deps,
        post('/api/premium/redeem', { code: 'THANDI30', email }),
      );
      expect(reply).toEqual({ status: 429, body: { error: 'tooManyTries' } });
    }
    const hash = await emailHashOf(PEPPER, 'sam@example.com');
    expect(peeked).toEqual([
      { rule: PREMIUM_WEB_PER_EMAIL.name, subject: hash },
      { rule: PREMIUM_WEB_PER_EMAIL.name, subject: hash },
    ]);
    expect(asked.map((entry) => entry.rule)).not.toContain(PREMIUM_WEB_PER_EMAIL.name);
    expect(asked.map((entry) => entry.rule)).not.toContain(PREMIUM_WEB_OVERALL.name);
    expect(JSON.stringify(peeked)).not.toContain('@');
  });

  it('count the new email of a reassign by its hash, before the overall budget', async () => {
    const { deps, asked } = recording((rule) => rule.name === PREMIUM_WEB_PER_EMAIL.name);
    const reply = await answerPremiumWeb(
      deps,
      post('/api/premium/gift/reassign', { token: TOKEN, email: 'SAM@example.com' }),
    );
    expect(reply.status).toBe(429);
    expect(asked.map((entry) => entry.rule)).toEqual([
      PREMIUM_WEB_PER_ADDRESS.name,
      PREMIUM_WEB_PER_EMAIL.name,
    ]);
    expect(asked[1]?.subject).toBe(await emailHashOf(PEPPER, 'sam@example.com'));
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

describe('each route’s refusals', () => {
  it('are listed for the pages, and every one has a 4xx status', () => {
    for (const [route, refusals] of Object.entries(WEB_ROUTE_REFUSALS)) {
      expect(refusals, route).toContain('badRequest');
      expect(refusals, route).toContain('tooManyTries');
      for (const refusal of refusals) expect(WEB_ERROR_STATUS[refusal], refusal).toBeLessThan(500);
    }
    expect(WEB_ROUTE_REFUSALS['/gift/reassign']).toContain('voucherReassignLimit');
    expect(WEB_ROUTE_REFUSALS['/redeem']).not.toContain('alreadyRedeemed');
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
