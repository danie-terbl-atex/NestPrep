import { describe, expect, it } from 'vitest';

import { KID_REDEEM_OVERALL, KID_REDEEM_PER_ADDRESS } from '../../src/accounts/kid_sign_in_policy';
import { REQUESTS_PER_ADDRESS, REQUESTS_PER_DAY } from '../../src/account_data/deletion_requests';
import { EXPORT_RATE_LIMIT } from '../../src/account_data/export_files';
import { clientAddress } from '../../src/shared/client_address';
import { READABLE_ALPHABET } from '../../src/shared/readable_code';
import { type RateLimitRule, nextWindow, rateLimitId } from '../../src/shared/rate_limit';

/**
 * The rate limits on the endpoints anybody can reach, and on the expensive
 * ones (accounts ADR-0006). The arithmetic is here; the emulator suite proves
 * a callable refuses once it is spent.
 */

const RULE: RateLimitRule = { name: 'test', limit: 3, windowSeconds: 60 };
const at = (seconds: number): Date => new Date(Date.UTC(2026, 8, 29, 8, 0, seconds));

describe('nextWindow', () => {
  it('opens a window on the first attempt', () => {
    expect(nextWindow(null, RULE, at(0))).toEqual({ windowStart: at(0), count: 1 });
  });

  it('counts attempts inside the window up to the limit, then refuses', () => {
    let window = nextWindow(null, RULE, at(0));
    window = window === null ? null : nextWindow(window, RULE, at(10));
    window = window === null ? null : nextWindow(window, RULE, at(20));
    expect(window).toEqual({ windowStart: at(0), count: 3 });
    expect(window === null ? 'spent' : nextWindow(window, RULE, at(30))).toBeNull();
  });

  it('starts again once the window has passed, whatever the count was', () => {
    expect(nextWindow({ windowStart: at(0), count: 3 }, RULE, at(60))).toEqual({
      windowStart: at(60),
      count: 1,
    });
  });
});

describe('rateLimitId', () => {
  it('is a hash — the address or uid it counts is never the document id', () => {
    const id = rateLimitId(RULE, '203.0.113.9');
    expect(id).toMatch(/^[0-9a-f]{64}$/);
    expect(id).not.toContain('203');
  });

  it('keeps two rules for one subject apart', () => {
    expect(rateLimitId(RULE, 'x')).not.toEqual(rateLimitId({ ...RULE, name: 'other' }, 'x'));
  });
});

describe('clientAddress', () => {
  it('takes the first forwarded hop — the caller, not Hosting or the front end', () => {
    expect(
      clientAddress({ headers: { 'x-forwarded-for': '198.51.100.7, 10.0.0.1' }, ip: '10.0.0.2' }),
    ).toBe('198.51.100.7');
  });

  it('falls back to the socket address, then to one shared bucket', () => {
    expect(clientAddress({ headers: {}, ip: '10.0.0.2' })).toBe('10.0.0.2');
    expect(clientAddress({ headers: {} })).toBe('unknown');
    expect(clientAddress(undefined)).toBe('unknown');
  });
});

describe('the limits chosen', () => {
  it('every per-address limit has an overall ceiling a forged header cannot dodge', () => {
    expect(KID_REDEEM_OVERALL.limit).toBeGreaterThan(KID_REDEEM_PER_ADDRESS.limit);
    expect(REQUESTS_PER_DAY.limit).toBeGreaterThan(REQUESTS_PER_ADDRESS.limit);
  });

  it('guessing a six-character kid code is out of reach at the per-address rate', () => {
    // Six places of the readable alphabet; a guesser gets 20 tries per ten minutes.
    const space = READABLE_ALPHABET.length ** 6;
    const triesPerCodeLifetime = KID_REDEEM_PER_ADDRESS.limit;
    expect(triesPerCodeLifetime / space).toBeLessThan(1e-6);
  });

  it('an export is limited per account, a few an hour', () => {
    expect(EXPORT_RATE_LIMIT.limit).toBeLessThanOrEqual(5);
    expect(EXPORT_RATE_LIMIT.windowSeconds).toBe(3600);
  });

  it('every rule has its own name, because the name is part of the key', () => {
    const names = [
      KID_REDEEM_OVERALL,
      KID_REDEEM_PER_ADDRESS,
      REQUESTS_PER_ADDRESS,
      REQUESTS_PER_DAY,
      EXPORT_RATE_LIMIT,
    ].map((rule) => rule.name);
    expect(new Set(names).size).toBe(names.length);
  });
});
