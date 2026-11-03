import type { Firestore } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';

import { codeHashOf, emailHashOf } from '../../../src/premium_vouchers/premium_hashes';
import {
  GIFT_LOOKUP_PER_ADDRESS,
  GIFT_REASSIGN_PER_ADDRESS,
  PREMIUM_WEB_PER_EMAIL,
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
import type { RedeemOutcome, Redeemer } from '../../../src/premium_vouchers/web_redemption';
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

interface World {
  readonly deps: PremiumWebDeps;
  readonly asked: { rule: string; subject: string }[];
  readonly used: Map<string, number>;
  readonly redeemed: Redeemer[];
  at(address: string): PremiumWebDeps;
}

async function aWorld(
  options: { limits?: Partial<Record<string, number>>; outcome?: RedeemOutcome } = {},
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
    redeem: async (redeemer): Promise<RedeemOutcome> => {
      redeemed.push(redeemer);
      if (options.outcome !== undefined) return Promise.resolve(options.outcome);
      return Promise.resolve({
        answer:
          redeemer.codeHash === found
            ? { result: 'redeemed', days: 30, label: 'Launch' }
            : { error: 'codeUnknown' },
        missCeilingTripped: false,
      });
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
  it('hands the redemption the code and email hashes and the caller’s address, and nothing plain', async () => {
    const world = await aWorld();
    const reply = await answerPremiumWeb(world.deps, redeem('thandi-30', ' Sam@Example.com'));
    expect(reply).toEqual({ status: 200, body: { result: 'redeemed', days: 30, label: 'Launch' } });
    expect(world.redeemed).toEqual([
      {
        codeHash: await codeHashOf(PEPPER, FOUND),
        emailHash: await emailHashOf(PEPPER, 'sam@example.com'),
        emailMasked: 's***@example.com',
        address: '203.0.113.9',
      },
    ]);
    expect(world.asked).toEqual([]);
  });

  it('answers what the redemption decided, its limits included', async () => {
    const world = await aWorld({
      outcome: { answer: { error: 'tooManyTries' }, missCeilingTripped: false },
    });
    expect(await answerPremiumWeb(world.deps, redeem(FOUND))).toEqual({
      status: 429,
      body: { error: 'tooManyTries' },
    });
  });

  it('logs a tripped miss ceiling once a window', async () => {
    const world = await aWorld({
      outcome: { answer: { error: 'tooManyTries' }, missCeilingTripped: true },
    });
    for (let call = 0; call < 3; call += 1) await answerPremiumWeb(world.deps, redeem('NOPE-NOPE'));
    expect(world.asked.map((entry) => entry.rule)).toEqual(
      Array(3).fill(REDEEM_MISSES_TRIPPED.name),
    );
    expect(world.used.get(`${REDEEM_MISSES_TRIPPED.name} all`)).toBe(1);
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
