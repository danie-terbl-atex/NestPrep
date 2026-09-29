import { describe, expect, it } from 'vitest';

import {
  QUALIFY_WINDOW_MS,
  REDEEM_WINDOW_MS,
  REDEMPTIONS_PER_DAY,
  YEARLY_REWARD_CAP,
  countsAsNewAdult,
  isUnderYearlyCap,
  mayStillRedeem,
  newAdultsSeen,
  qualifyByOf,
  redeemByOf,
  redeemedWithinADay,
  sharesAMember,
} from '../../../src/referrals/referral_policy';

/**
 * What earns a referral month, and what stops one being farmed
 * (subscriptions ADR-0002). A wrong answer here is money, so each edge is
 * pinned.
 */
const DAY_MS = 24 * 60 * 60 * 1000;
const CREATED = new Date('2026-10-01T08:00:00Z');

function after(days: number, from = CREATED): Date {
  return new Date(from.getTime() + days * DAY_MS);
}

describe('entering a code', () => {
  it('is open for the household"s first seven days, to the millisecond', () => {
    expect(mayStillRedeem(CREATED, CREATED)).toBe(true);
    expect(mayStillRedeem(CREATED, after(6.99))).toBe(true);
    expect(mayStillRedeem(CREATED, after(7))).toBe(true);
    expect(mayStillRedeem(CREATED, new Date(CREATED.getTime() + REDEEM_WINDOW_MS + 1))).toBe(false);
    expect(redeemByOf(CREATED)).toEqual(after(7));
  });

  it('is closed to a household whose age is unknown, or whose clock runs backwards', () => {
    expect(mayStillRedeem(null, CREATED)).toBe(false);
    expect(redeemByOf(null)).toBeNull();
    expect(mayStillRedeem(CREATED, after(-1))).toBe(false);
  });

  it('gives the new household fourteen days to become a family', () => {
    expect(qualifyByOf(CREATED).getTime() - CREATED.getTime()).toBe(QUALIFY_WINDOW_MS);
    expect(QUALIFY_WINDOW_MS).toBe(14 * DAY_MS);
  });
});

describe('who counts toward a real family', () => {
  const referred = {
    'uid-sam': 'admin',
    'uid-alex': 'parent',
    'uid-kid': 'kid',
    'uid-thandi': 'helper',
  };
  const referrer = { 'uid-olivia': 'admin' };

  it('is any adult in the new household — family, helper or carer', () => {
    expect(countsAsNewAdult('uid-sam', referred, referrer)).toBe(true);
    expect(countsAsNewAdult('uid-thandi', referred, referrer)).toBe(true);
  });

  it('is never a kid, nor somebody not in the household', () => {
    expect(countsAsNewAdult('uid-kid', referred, referrer)).toBe(false);
    expect(countsAsNewAdult('uid-stranger', referred, referrer)).toBe(false);
  });

  it('is never a member of the household that shared the code — nobody qualifies their own referral', () => {
    const joined = { ...referred, 'uid-olivia': 'parent' };
    expect(countsAsNewAdult('uid-olivia', joined, referrer)).toBe(false);
    expect(newAdultsSeen(['uid-sam', 'uid-olivia'], joined, referrer)).toEqual(['uid-sam']);
  });

  it('counts each adult once however often they opened it', () => {
    expect(newAdultsSeen(['uid-sam', 'uid-sam', 'uid-kid'], referred, referrer)).toEqual([
      'uid-sam',
    ]);
    expect(newAdultsSeen(['uid-sam', 'uid-alex'], referred, referrer)).toHaveLength(2);
  });

  it('sees a shared member between the two households', () => {
    expect(sharesAMember(referred, referrer)).toBe(false);
    expect(sharesAMember({ ...referred, 'uid-olivia': 'parent' }, referrer)).toBe(true);
  });
});

describe('the limits', () => {
  const now = new Date('2026-10-20T08:00:00Z');

  it('pays at most six months into one household in a rolling year', () => {
    const five = [1, 30, 60, 90, 120].map((days) => after(-days, now));
    expect(isUnderYearlyCap(five, now)).toBe(true);
    expect(isUnderYearlyCap([...five, after(-150, now)], now)).toBe(false);
    expect(YEARLY_REWARD_CAP).toBe(6);
  });

  it('forgets a month granted more than a year ago', () => {
    const six = [1, 30, 60, 90, 120, 366].map((days) => after(-days, now));
    expect(isUnderYearlyCap(six, now)).toBe(true);
  });

  it('keeps only the redemptions of the last day, oldest first, at most the limit', () => {
    const times = [after(-2, now), after(-0.5, now), after(-0.1, now), after(-1.01, now)];
    expect(redeemedWithinADay(times, now)).toEqual([after(-0.5, now), after(-0.1, now)]);
    const many = Array.from({ length: 9 }, (_, index) => after(-index / 100, now));
    expect(redeemedWithinADay(many, now)).toHaveLength(REDEMPTIONS_PER_DAY);
  });
});
