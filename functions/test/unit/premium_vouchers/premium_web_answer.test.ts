import type { Firestore } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';

import { codeHashOf, emailHashOf } from '../../../src/premium_vouchers/premium_hashes';
import {
  GIFT_LOOKUP_PER_ADDRESS,
  GIFT_REASSIGN_PER_ADDRESS,
  PREMIUM_WEB_PER_EMAIL,
  REDEEM_MISSES_OVERALL,
  REDEEM_MISSES_PER_ADDRESS,
  REDEEM_MISSES_TRIPPED,
} from '../../../src/premium_vouchers/premium_web_limits';
import {
  type PremiumWebDeps,
  type WebRequest,
  WEB_ERROR_STATUS,
  WEB_ROUTE_REFUSALS,
  answerPremiumWeb,
  routeOf,
} from '../../../src/premium_vouchers/premium_web_answer';
import type { RedeemAnswer, Redeemer } from '../../../src/premium_vouchers/web_redemption';
import type { RateLimitRule } from '../../../src/shared/rate_limit';

const PEPPER = 'test-pepper';
const TOKEN = 'A'.repeat(43);
const FOUND = 'THANDI30';

const untouchable = new Proxy(
  {},
  {
    get(): never {
      throw new Error('the store was reached');
    },
  },
) as Firestore;

const RULES = [
  GIFT_LOOKUP_PER_ADDRESS,
  GIFT_REASSIGN_PER_ADDRESS,
  PREMIUM_WEB_PER_EMAIL,
  REDEEM_MISSES_OVERALL,
  REDEEM_MISSES_PER_ADDRESS,
  REDEEM_MISSES_TRIPPED,
];

interface World {
  readonly deps: PremiumWebDeps;
  readonly asked: { rule: string; subject: string }[];
  readonly used: Map<string, number>;
  readonly redeemed: Redeemer[];
  at(address: string): PremiumWebDeps;
}

async function aWorld(
  options: { limits?: Partial<Record<string, number>>; answer?: RedeemAnswer } = {},
): Promise<World> {
  const asked: { rule: string; subject: string }[] = [];
  const used = new Map<string, number>();
  const redeemed: Redeemer[] = [];
  const found = await codeHashOf(PEPPER, FOUND);
  const limitOf = (rule: RateLimitRule): number => options.limits?.[rule.name] ?? rule.limit;
  const at = (address: string): PremiumWebDeps => ({
    store: untouchable,
    pepper: () => PEPPER,
    address,
    now: new Date('2026-11-10T10:00:00Z'),
    consume: async (rule, subject): Promise<boolean> => {
      asked.push({ rule: rule.name, subject });
      const key = `${rule.name} ${subject}`;
      const count = used.get(key) ?? 0;
      if (count >= limitOf(rule)) return Promise.resolve(false);
      used.set(key, count + 1);
      return Promise.resolve(true);
    },
    redeem: async (redeemer): Promise<RedeemAnswer> => {
      redeemed.push(redeemer);
      if (redeemer.codeHash !== found) return Promise.resolve({ error: 'codeUnknown' });
      return Promise.resolve(options.answer ?? { result: 'redeemed', days: 30, label: 'Launch' });
    },
  });
  return { deps: at('203.0.113.9'), asked, used, redeemed, at };
}

const post = (path: string, body: unknown): WebRequest => ({ method: 'POST', path, body });
const redeem = (code: string, email = 'a@b.co'): WebRequest =>
  post('/api/premium/redeem', { code, email });

describe('the routes', () => {
  it('are read behind Hosting’s /api/premium prefix and on the function’s own URL', () => {
    expect(routeOf('/api/premium/gift/lookup')).toBe('/gift/lookup');
    expect(routeOf('/api/premium/gift/reassign/')).toBe('/gift/reassign');
    expect(routeOf('/redeem')).toBe('/redeem');
    expect(routeOf('/api/premiumx/redeem')).toBeNull();
    expect(routeOf('/api/premium/other')).toBeNull();
  });

  it('answer only POST', async () => {
    const reply = await answerPremiumWeb((await aWorld()).deps, {
      method: 'GET',
      path: '/api/premium/redeem',
      body: undefined,
    });
    expect(reply).toEqual({ status: 405, body: { error: 'methodNotAllowed' } });
  });

  it('answer 404 for a path that is not one', async () => {
    const reply = await answerPremiumWeb((await aWorld()).deps, post('/api/premium/admin', {}));
    expect(reply).toEqual({ status: 404, body: { error: 'notFound' } });
  });
});

describe('gift links', () => {
  it('are limited per address only, so no shared budget can close them', async () => {
    const world = await aWorld();
    await answerPremiumWeb(world.deps, post('/api/premium/gift/lookup', { token: 'short' }));
    await answerPremiumWeb(
      world.deps,
      post('/api/premium/gift/reassign', { token: 'x', email: 'a@b.co' }),
    );
    expect(world.asked).toEqual([
      { rule: GIFT_LOOKUP_PER_ADDRESS.name, subject: '203.0.113.9' },
      { rule: GIFT_REASSIGN_PER_ADDRESS.name, subject: '203.0.113.9' },
    ]);
  });

  it('answer 429 past the address’s own ceiling, and lookups have a higher one', async () => {
    expect(GIFT_LOOKUP_PER_ADDRESS.limit).toBeGreaterThan(GIFT_REASSIGN_PER_ADDRESS.limit);
    const world = await aWorld();
    const answers: number[] = [];
    for (let call = 0; call <= GIFT_LOOKUP_PER_ADDRESS.limit; call += 1) {
      answers.push(
        (await answerPremiumWeb(world.deps, post('/api/premium/gift/lookup', { token: 'short' })))
          .status,
      );
    }
    expect(answers.at(-2)).toBe(404);
    expect(answers.at(-1)).toBe(429);
    const elsewhere = await answerPremiumWeb(
      world.at('198.51.100.1'),
      post('/api/premium/gift/lookup', { token: 'short' }),
    );
    expect(elsewhere.status).toBe(404);
  });

  it('count the new email of a reassign by its hash, so its case changes nothing', async () => {
    const world = await aWorld({ limits: { [PREMIUM_WEB_PER_EMAIL.name]: 0 } });
    const reply = await answerPremiumWeb(
      world.deps,
      post('/api/premium/gift/reassign', { token: TOKEN, email: ' SAM@example.com' }),
    );
    expect(reply).toEqual({ status: 429, body: { error: 'tooManyTries' } });
    expect(world.asked[1]).toEqual({
      rule: PREMIUM_WEB_PER_EMAIL.name,
      subject: await emailHashOf(PEPPER, 'sam@example.com'),
    });
  });
});

describe('redeeming a code', () => {
  it('honours a found code whatever any limit says', async () => {
    const world = await aWorld({
      limits: Object.fromEntries(RULES.map((rule) => [rule.name, 0])),
    });
    const reply = await answerPremiumWeb(world.deps, redeem('thandi-30'));
    expect(reply).toEqual({ status: 200, body: { result: 'redeemed', days: 30, label: 'Launch' } });
    expect(world.asked).toEqual([]);
  });

  it('counts a miss per address, and adds it to the overall budget only while that address is under its own', async () => {
    const world = await aWorld();
    const answers: number[] = [];
    for (let call = 0; call < 40; call += 1) {
      answers.push((await answerPremiumWeb(world.deps, redeem('ZZZZ-ZZZZ'))).status);
    }
    expect(
      answers.slice(0, REDEEM_MISSES_PER_ADDRESS.limit).every((status) => status === 404),
    ).toBe(true);
    expect(answers.slice(REDEEM_MISSES_PER_ADDRESS.limit).every((status) => status === 429)).toBe(
      true,
    );
    expect(world.used.get(`${REDEEM_MISSES_OVERALL.name} all`)).toBe(
      REDEEM_MISSES_PER_ADDRESS.limit,
    );
    expect((await answerPremiumWeb(world.deps, redeem(FOUND))).status).toBe(200);
  });

  it('once the overall miss budget is spent, refuses only misses, and logs it once a window', async () => {
    const world = await aWorld({ limits: { [REDEEM_MISSES_OVERALL.name]: 2 } });
    const statuses: number[] = [];
    for (let address = 0; address < 4; address += 1) {
      statuses.push(
        (await answerPremiumWeb(world.at(`198.51.100.${String(address)}`), redeem('NOPE-NOPE')))
          .status,
      );
    }
    expect(statuses).toEqual([404, 404, 429, 429]);
    expect(world.used.get(`${REDEEM_MISSES_TRIPPED.name} all`)).toBe(1);
    expect((await answerPremiumWeb(world.at('198.51.100.9'), redeem(FOUND))).status).toBe(200);
  });

  it('never counts a miss against the email, so garbage cannot lock anybody out', async () => {
    const world = await aWorld();
    for (let call = 0; call < 12; call += 1) {
      await answerPremiumWeb(
        world.at(`198.51.100.${String(call)}`),
        redeem('ZZZZ', 'victim@example.com'),
      );
    }
    expect(world.asked.map((entry) => entry.rule)).not.toContain(PREMIUM_WEB_PER_EMAIL.name);
  });

  it('counts a real code’s refusal against the email, by its hash', async () => {
    const world = await aWorld({ answer: { error: 'codePaused' } });
    for (let call = 0; call < PREMIUM_WEB_PER_EMAIL.limit; call += 1) {
      expect((await answerPremiumWeb(world.deps, redeem(FOUND, 'Sam@Example.com'))).body).toEqual({
        error: 'codePaused',
      });
    }
    expect((await answerPremiumWeb(world.deps, redeem(FOUND, ' sam@example.com'))).body).toEqual({
      error: 'tooManyTries',
    });
    const subjects = new Set(world.asked.map((entry) => entry.subject));
    expect(subjects).toEqual(new Set([await emailHashOf(PEPPER, 'sam@example.com')]));
  });

  it('looks nothing up for a body that is not a code and an email', async () => {
    const world = await aWorld();
    await answerPremiumWeb(world.deps, redeem('ab'));
    await answerPremiumWeb(world.deps, redeem(FOUND, 'nope'));
    expect(world.redeemed).toEqual([]);
    expect(world.asked).toEqual([]);
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
    const reply = await answerPremiumWeb((await aWorld()).deps, post(`/api/premium${route}`, body));
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
