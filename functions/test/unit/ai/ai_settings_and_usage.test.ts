import { Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';

import {
  DEFAULT_AI_SETTINGS,
  MAX_MONTHLY_CALLS,
  isFeatureOn,
  readAiSettings,
} from '../../../src/ai/ai_settings';
import {
  ATTEMPT_HEADROOM,
  capFor,
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
