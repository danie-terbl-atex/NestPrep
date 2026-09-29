import { describe, expect, it } from 'vitest';

import {
  DAY_MS,
  composePremium,
  type PremiumGrant,
  type PremiumSources,
} from '../../../src/subscriptions/premium_composition';

/**
 * How a household's premium is made of what a store sold it and the months it
 * was given (subscriptions ADR-0002). Every ordering a family can live through
 * — free, paying, lapsing, refunded, paying again — pinned to the day, because
 * `premiumUntil` is the one number the rules read.
 */
const T0 = new Date('2026-10-01T08:00:00Z');

function day(offset: number): Date {
  return new Date(T0.getTime() + offset * DAY_MS);
}

function grant(id: string, grantedDay: number, startsDay: number | null = null): PremiumGrant {
  return {
    id,
    days: 30,
    grantedAt: day(grantedDay),
    startsAt: startsDay === null ? null : day(startsDay),
  };
}

function sources(overrides: Partial<PremiumSources> = {}): PremiumSources {
  return {
    storeUntil: null,
    grants: [],
    previous: { referralFrom: null, premiumUntil: null },
    ...overrides,
  };
}

describe('a household with nothing', () => {
  it('has no premium, and nothing waiting', () => {
    const composed = composePremium(sources(), T0);
    expect(composed.premiumUntil).toBeNull();
    expect(composed.referralUntil).toBeNull();
    expect(composed.referralDaysWaiting).toBe(0);
    expect(composed.started).toEqual({});
  });

  it('is exactly what the store says when it only pays', () => {
    const composed = composePremium(sources({ storeUntil: day(20) }), T0);
    expect(composed.premiumUntil).toEqual(day(20));
    expect(composed.storeUntil).toEqual(day(20));
    expect(composed.referralUntil).toBeNull();
  });
});

describe('a free household given a month', () => {
  it('starts the month at once and has premium for thirty days', () => {
    const composed = composePremium(sources({ grants: [grant('g1', 0)] }), T0);
    expect(composed.started).toEqual({ g1: T0 });
    expect(composed.premiumUntil).toEqual(day(30));
    expect(composed.referralUntil).toEqual(day(30));
    expect(composed.referralDaysWaiting).toBe(0);
  });

  it('queues a second month behind the first, never running both at once', () => {
    const first = composePremium(sources({ grants: [grant('g1', 0)] }), T0);
    const second = composePremium(
      sources({
        grants: [grant('g1', 0, 0), grant('g2', 5)],
        previous: { referralFrom: first.referralFrom, premiumUntil: first.premiumUntil },
      }),
      day(5),
    );
    expect(second.started).toEqual({});
    expect(second.referralDaysWaiting).toBe(30);
    expect(second.premiumUntil).toEqual(day(60));
  });

  it('starts the queued month where the first one ended, once that has passed', () => {
    const composed = composePremium(
      sources({
        grants: [grant('g1', 0, 0), grant('g2', 5)],
        previous: { referralFrom: day(30), premiumUntil: day(60) },
      }),
      day(40),
    );
    expect(composed.started).toEqual({ g2: day(30) });
    expect(composed.premiumUntil).toEqual(day(60));
    expect(composed.referralDaysWaiting).toBe(0);
  });

  it('ends at its instant: a month fully run gives nothing', () => {
    const composed = composePremium(
      sources({
        grants: [grant('g1', 0, 0)],
        previous: { referralFrom: day(30), premiumUntil: day(30) },
      }),
      day(31),
    );
    expect(composed.premiumUntil).toBeNull();
    expect(composed.referralUntil).toBeNull();
  });
});

describe('a paying household given a month', () => {
  it('queues it after the paid time — premium runs on to the store date plus thirty days', () => {
    const composed = composePremium(
      sources({
        storeUntil: day(20),
        grants: [grant('g1', 3)],
        previous: { referralFrom: null, premiumUntil: day(20) },
      }),
      day(3),
    );
    expect(composed.started).toEqual({});
    expect(composed.referralDaysWaiting).toBe(30);
    expect(composed.referralFrom).toEqual(day(20));
    expect(composed.premiumUntil).toEqual(day(50));
  });

  it('keeps waiting while the store renews, so a family that keeps paying keeps its month', () => {
    const composed = composePremium(
      sources({
        storeUntil: day(50),
        grants: [grant('g1', 3)],
        previous: { referralFrom: day(20), premiumUntil: day(50) },
      }),
      day(19),
    );
    expect(composed.started).toEqual({});
    expect(composed.referralFrom).toEqual(day(50));
    expect(composed.premiumUntil).toEqual(day(80));
  });

  it('starts it at the lapse nobody noticed, with no gap in premium', () => {
    // The subscription ended on day 20 and the next restatement ran on day 23.
    const composed = composePremium(
      sources({
        storeUntil: null,
        grants: [grant('g1', 3)],
        previous: { referralFrom: day(20), premiumUntil: day(50) },
      }),
      day(23),
    );
    expect(composed.started).toEqual({ g1: day(20) });
    expect(composed.premiumUntil).toEqual(day(50));
    expect(composed.referralUntil).toEqual(day(50));
  });

  it('starts it at once when the store refunds the subscription', () => {
    const composed = composePremium(
      sources({
        storeUntil: null,
        grants: [grant('g1', 3)],
        previous: { referralFrom: day(20), premiumUntil: day(50) },
      }),
      day(10),
    );
    // Not started yet by the old cover (day 20 is ahead), but nothing covers
    // now, so the waiting month begins now.
    expect(composed.referralFrom).toEqual(day(10));
    expect(composed.premiumUntil).toEqual(day(40));
    const next = composePremium(
      sources({
        storeUntil: null,
        grants: [grant('g1', 3)],
        previous: { referralFrom: composed.referralFrom, premiumUntil: composed.premiumUntil },
      }),
      day(12),
    );
    expect(next.started).toEqual({ g1: day(10) });
    expect(next.premiumUntil).toEqual(day(40));
  });

  it('never slides a month that already began when the family buys again', () => {
    const composed = composePremium(
      sources({
        storeUntil: day(45),
        grants: [grant('g1', 3, 20)],
        previous: { referralFrom: day(50), premiumUntil: day(50) },
      }),
      day(25),
    );
    expect(composed.started).toEqual({});
    expect(composed.referralUntil).toEqual(day(50));
    expect(composed.premiumUntil).toEqual(day(50));
  });
});

describe('a household composed for the first time since grants existed', () => {
  it('measures a new grant from the premium it already had', () => {
    const composed = composePremium(
      sources({
        storeUntil: day(10),
        grants: [grant('g1', 0)],
        previous: { referralFrom: null, premiumUntil: day(10) },
      }),
      T0,
    );
    expect(composed.started).toEqual({});
    expect(composed.premiumUntil).toEqual(day(40));
  });

  it('starts a new grant now when the old premium has already ended', () => {
    const composed = composePremium(
      sources({
        grants: [grant('g1', 0)],
        previous: { referralFrom: null, premiumUntil: day(-5) },
      }),
      T0,
    );
    expect(composed.started).toEqual({ g1: T0 });
    expect(composed.premiumUntil).toEqual(day(30));
  });
});
