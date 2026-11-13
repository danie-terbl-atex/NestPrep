import { Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';

import {
  DEFAULT_AI_SETTINGS,
  MAX_MONTHLY_CALLS,
  chargeOf,
  isFeatureOn,
  readAiSettings,
} from '../../../src/ai/ai_settings';
import {
  ATTEMPT_HEADROOM,
  allowanceAttemptCeiling,
  allowanceAttemptsLeft,
  allowanceAttemptsOf,
  allowanceLeft,
  capFor,
  countOf,
  decideCharge,
  decideClaim,
  monthKeyIn,
  readMonthUsage,
  tierFrom,
} from '../../../src/ai/usage_rules';

/**
 * The kill switch and the monthly cap (foundation ADR-0015) — the two things
 * that keep AI cost per family bounded from the first commit (verdict 003).
 */

describe('the kill switch', () => {
  it('is on with the default caps when nobody has written the document', () => {
    expect(readAiSettings(undefined)).toEqual(DEFAULT_AI_SETTINGS);
    expect(DEFAULT_AI_SETTINGS.monthlyCalls).toEqual({ free: 10, premium: 100 });
  });

  it('enabled: false stops every feature', () => {
    const settings = readAiSettings({ enabled: false });
    expect(isFeatureOn(settings, 'schoolLetter')).toBe(false);
    expect(isFeatureOn(settings, 'planMyWeek')).toBe(false);
  });

  it('an enabled that is not a boolean is off — a typo must not leave the switch open', () => {
    expect(readAiSettings({ enabled: 'false' }).enabled).toBe(false);
    expect(readAiSettings({ enabled: 0 }).enabled).toBe(false);
    expect(readAiSettings('garbage').enabled).toBe(false);
  });

  it('one feature can be switched off under the kill switch', () => {
    const settings = readAiSettings({ features: { schoolLetter: false } });
    expect(isFeatureOn(settings, 'schoolLetter')).toBe(false);
    expect(isFeatureOn(settings, 'planMyWeek')).toBe(true);
  });

  it('a feature switch that is not false leaves the feature on', () => {
    expect(readAiSettings({ features: { schoolLetter: 'off' } }).features.schoolLetter).toBe(true);
  });
});

describe('the caps', () => {
  it('take the stored numbers', () => {
    expect(readAiSettings({ monthlyCalls: { free: 3, premium: 40 } }).monthlyCalls).toEqual({
      free: 3,
      premium: 40,
    });
  });

  it('keep the default where a number is missing', () => {
    expect(readAiSettings({ monthlyCalls: { free: 4 } }).monthlyCalls).toEqual({
      free: 4,
      premium: 100,
    });
  });

  it('ignore a number nobody means — negative, fractional or past the ceiling', () => {
    for (const free of [-1, 2.5, MAX_MONTHLY_CALLS + 1, '10']) {
      expect(readAiSettings({ monthlyCalls: { free } }).monthlyCalls.free, String(free)).toBe(10);
    }
  });

  it('are chosen by tier', () => {
    expect(capFor('free', { free: 10, premium: 100 })).toBe(10);
    expect(capFor('premium', { free: 10, premium: 100 })).toBe(100);
  });
});

describe('the tier', () => {
  const now = new Date('2026-09-29T10:00:00Z');

  it('is premium while premiumUntil is in the future', () => {
    const entitlement = { premiumUntil: Timestamp.fromDate(new Date('2026-10-29T00:00:00Z')) };
    expect(tierFrom(entitlement, now)).toBe('premium');
  });

  it('is free once premiumUntil has passed, at its instant', () => {
    expect(tierFrom({ premiumUntil: Timestamp.fromDate(now) }, now)).toBe('free');
  });

  it('is free with no document, no field, or a field that is not an instant', () => {
    for (const entitlement of [
      undefined,
      {},
      { premiumUntil: null },
      { premiumUntil: '2099-01-01' },
    ]) {
      expect(tierFrom(entitlement, now)).toBe('free');
    }
  });
});

describe('the month a call counts in', () => {
  it('is the household’s month, not UTC’s', () => {
    // 22:30 UTC on 30 September is 00:30 on 1 October in Johannesburg.
    const lateSeptemberUtc = new Date('2026-09-30T22:30:00Z');
    expect(monthKeyIn('Africa/Johannesburg', lateSeptemberUtc)).toBe('2026-10');
    expect(monthKeyIn('UTC', lateSeptemberUtc)).toBe('2026-09');
  });

  it('is UTC’s when the zone cannot be read, rather than failing the call', () => {
    expect(monthKeyIn('Not/AZone', new Date('2026-09-30T22:30:00Z'))).toBe('2026-09');
  });
});

describe('whether one more call fits', () => {
  it('fits under the cap, and says what is left after it', () => {
    expect(decideClaim({ calls: 0, attempts: 0 }, 10)).toEqual({
      allowed: true,
      callsAfter: 1,
      callsLeft: 9,
    });
    expect(decideClaim({ calls: 9, attempts: 9 }, 10)).toEqual({
      allowed: true,
      callsAfter: 10,
      callsLeft: 0,
    });
  });

  it('does not fit at the cap', () => {
    expect(decideClaim({ calls: 10, attempts: 10 }, 10)).toEqual({ allowed: false });
  });

  it('a cap of zero switches the tier off', () => {
    expect(decideClaim({ calls: 0, attempts: 0 }, 0)).toEqual({ allowed: false });
  });

  it('does not fit once failed attempts reach three times the cap, refunds or not', () => {
    expect(decideClaim({ calls: 0, attempts: 10 * ATTEMPT_HEADROOM }, 10)).toEqual({
      allowed: false,
    });
    expect(decideClaim({ calls: 0, attempts: 10 * ATTEMPT_HEADROOM - 1 }, 10).allowed).toBe(true);
  });

  it('reads stored counters defensively — missing or bad is zero', () => {
    expect(readMonthUsage(undefined)).toEqual({ calls: 0, attempts: 0 });
    expect(readMonthUsage({ calls: 4 })).toEqual({ calls: 4, attempts: 0 });
    expect(readMonthUsage({ calls: -2, attempts: 'x' })).toEqual({ calls: 0, attempts: 0 });
  });
});

describe('creations, outside the monthly call cap (avatars ADR-0003 amending foundation ADR-0015)', () => {
  const settings = readAiSettings(undefined);
  const creation = chargeOf(settings, 'avatarCreate');
  const check = chargeOf(settings, 'avatarCheck');
  const NONE = { month: 0, lifetime: 0, attempts: 0 };

  it('are switched on, 12 a month premium and one ever free, unless the console says otherwise', () => {
    expect(isFeatureOn(settings, 'avatarCheck')).toBe(true);
    expect(isFeatureOn(settings, 'avatarCreate')).toBe(true);
    expect(isFeatureOn(settings, 'avatarPortrait')).toBe(true);
    expect(settings.allowances.avatarCreate).toEqual({ premiumMonthly: 12, freeLifetime: 1 });
    expect(
      readAiSettings({ features: { avatarCreate: { premiumMonthly: 20 } } }).allowances
        .avatarCreate,
    ).toEqual({ premiumMonthly: 20, freeLifetime: 1 });
    expect(
      readAiSettings({ features: { avatarCreate: { premiumMonthly: -1, freeLifetime: 'x' } } })
        .allowances.avatarCreate,
    ).toEqual({ premiumMonthly: 12, freeLifetime: 1 });
  });

  it('keep their allowance object without switching the feature off, and false switches it off', () => {
    const tuned = readAiSettings({ features: { avatarCreate: { premiumMonthly: 3 } } });
    expect(isFeatureOn(tuned, 'avatarCreate')).toBe(true);
    expect(isFeatureOn(readAiSettings({ features: { avatarCreate: false } }), 'avatarCreate')).toBe(
      false,
    );
  });

  it('charge a portrait to the same allowance as a creation, the check to nothing, the rest to calls', () => {
    expect(creation).toEqual({
      kind: 'allowance',
      name: 'avatarCreate',
      shares: ['avatarCreate', 'avatarPortrait'],
      allowance: { premiumMonthly: 12, freeLifetime: 1 },
    });
    expect(chargeOf(settings, 'avatarPortrait')).toEqual(creation);
    expect(check).toEqual({
      kind: 'none',
      name: 'avatarCreate',
      allowance: { premiumMonthly: 12, freeLifetime: 1 },
    });
    expect(chargeOf(settings, 'lunchPhoto')).toEqual({ kind: 'calls' });
  });

  it('fit while the allowance has room, whatever the call cap says', () => {
    const spent = { calls: 100, attempts: 100 };
    expect(
      decideCharge(creation, spent, 100, 'premium', { ...NONE, month: 11, lifetime: 40 }),
    ).toEqual({
      allowed: true,
      callsAfter: 100,
      callsLeft: 0,
    });
    expect(
      decideCharge(creation, spent, 100, 'premium', { ...NONE, month: 12, lifetime: 12 }),
    ).toEqual({
      allowed: false,
    });
    expect(decideCharge(creation, { calls: 10, attempts: 10 }, 10, 'free', NONE)).toEqual({
      allowed: true,
      callsAfter: 10,
      callsLeft: 0,
    });
    expect(
      decideCharge(creation, { calls: 0, attempts: 0 }, 10, 'free', { ...NONE, lifetime: 1 }),
    ).toEqual({ allowed: false });
  });

  it('a check or a creation is never refused for the household’s spent calls or attempts', () => {
    const closed = { calls: 10, attempts: 10 * ATTEMPT_HEADROOM };
    expect(decideCharge({ kind: 'calls' }, closed, 10, 'free', NONE).allowed).toBe(false);
    expect(decideCharge(check, closed, 10, 'free', NONE)).toEqual({
      allowed: true,
      callsAfter: 10,
      callsLeft: 0,
    });
    expect(decideCharge(creation, closed, 10, 'free', NONE).allowed).toBe(true);
  });

  it('stop at the allowance’s own attempt ceiling, which never closes anything else', () => {
    const allowance = { premiumMonthly: 12, freeLifetime: 1 };
    expect(allowanceAttemptCeiling('free', allowance)).toBe(9);
    expect(allowanceAttemptCeiling('premium', allowance)).toBe(108);
    expect(allowanceAttemptCeiling('free', { ...allowance, freeLifetime: 0 })).toBe(0);
    const fresh = { calls: 0, attempts: 0 };
    const spent = { ...NONE, attempts: 9 };
    expect(decideCharge(check, fresh, 10, 'free', { ...NONE, attempts: 8 }).allowed).toBe(true);
    expect(decideCharge(check, fresh, 10, 'free', spent).allowed).toBe(false);
    expect(decideCharge(creation, fresh, 10, 'free', spent).allowed).toBe(false);
    expect(decideCharge(check, fresh, 100, 'premium', spent).allowed).toBe(true);
    expect(decideCharge({ kind: 'calls' }, fresh, 10, 'free', spent).allowed).toBe(true);
    expect(allowanceAttemptsLeft('free', { ...NONE, attempts: 7 }, allowance)).toBe(2);
    expect(allowanceAttemptsLeft('free', { ...NONE, attempts: 40 }, allowance)).toBe(0);
  });

  it('read the attempts stored for an allowance, missing or bad as none', () => {
    expect(allowanceAttemptsOf({ allowanceAttempts: { avatarCreate: 4 } }, 'avatarCreate')).toBe(4);
    expect(allowanceAttemptsOf({ attempts: 30 }, 'avatarCreate')).toBe(0);
    expect(allowanceAttemptsOf({ allowanceAttempts: { avatarCreate: -1 } }, 'avatarCreate')).toBe(
      0,
    );
    expect(allowanceAttemptsOf({ allowanceAttempts: 'x' }, 'avatarCreate')).toBe(0);
    expect(allowanceAttemptsOf(undefined, 'avatarCreate')).toBe(0);
  });

  it('count what is left by tier, and sum the features that share it', () => {
    const allowance = { premiumMonthly: 12, freeLifetime: 1 };
    expect(allowanceLeft('premium', { ...NONE, month: 5, lifetime: 30 }, allowance)).toBe(7);
    expect(allowanceLeft('free', NONE, allowance)).toBe(1);
    expect(allowanceLeft('free', { ...NONE, lifetime: 3 }, allowance)).toBe(0);
    const stored = { byFeature: { avatarCreate: 2, avatarPortrait: 1, lunchPhoto: 9 } };
    expect(countOf(stored, ['avatarCreate', 'avatarPortrait'])).toBe(3);
    expect(countOf({ byFeature: { avatarCreate: -4 } }, ['avatarCreate'])).toBe(0);
    expect(countOf(undefined, ['avatarCreate'])).toBe(0);
  });
});
