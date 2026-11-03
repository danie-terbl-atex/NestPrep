import { describe, expect, it } from 'vitest';

import {
  CLAIM_GRACE_MS,
  claimByOf,
  claimWindowRefusalOf,
  isNewToPremium,
  isPastClaimBy,
  isUsedUp,
  redeemRefusalOf,
  sastDate,
  usedCodeWithinYear,
} from '../../../src/premium_vouchers/code_policy';
import type { StoredCode, StoredVoucher } from '../../../src/premium_vouchers/voucher_documents';
import type { GrantSource } from '../../../src/subscriptions/household_premium';
import type { PremiumGrant } from '../../../src/subscriptions/premium_composition';

const DAY_MS = 24 * 60 * 60 * 1000;
const NOW = new Date('2026-11-10T10:00:00Z');
const days = (offset: number): Date => new Date(NOW.getTime() + offset * DAY_MS);

function aCode(overrides: Partial<StoredCode> = {}): StoredCode {
  return {
    shape: 'shared',
    display: 'THANDI30',
    label: 'Thandi’s readers',
    batchId: null,
    days: 30,
    maxClaims: 10,
    claimCount: 0,
    validFrom: days(-5),
    validUntil: days(20),
    status: 'active',
    eligibility: 'newToPremium',
    attribution: null,
    isTest: false,
    ...overrides,
  };
}

function aVoucher(overrides: Partial<StoredVoucher> = {}): StoredVoucher {
  return {
    kind: 'code',
    orderId: null,
    sku: null,
    codeId: 'code-hash',
    days: 30,
    emailHash: 'email-hash',
    emailMasked: 's***@example.com',
    claimTokenHash: null,
    status: 'waiting',
    isTest: false,
    attribution: null,
    claimBy: days(50),
    ...overrides,
  };
}

function aGrant(source: GrantSource, grantedDaysAgo: number): PremiumGrant {
  return {
    id: `${source}-${String(grantedDaysAgo)}`,
    source,
    days: 30,
    grantedAt: days(-grantedDaysAgo),
    startsAt: null,
  };
}

describe('redeeming a code on the web', () => {
  it('goes ahead for an active code inside its window with places left', () => {
    expect(redeemRefusalOf(aCode(), NOW)).toBeNull();
    expect(redeemRefusalOf(aCode({ validUntil: null, maxClaims: null }), NOW)).toBeNull();
  });

  it('refuses a paused code', () => {
    expect(redeemRefusalOf(aCode({ status: 'paused' }), NOW)).toEqual({ error: 'codePaused' });
  });

  it('refuses a code that has not started, saying the SAST date it starts', () => {
    const validFrom = new Date('2026-11-30T22:00:00Z');
    expect(redeemRefusalOf(aCode({ validFrom }), NOW)).toEqual({
      error: 'codeNotStarted',
      startsOn: '2026-12-01',
    });
  });

  it('refuses a code that has ended, saying the SAST date it ended', () => {
    const validUntil = new Date('2026-11-09T21:59:59Z');
    expect(redeemRefusalOf(aCode({ validUntil }), NOW)).toEqual({
      error: 'codeExpired',
      endedOn: '2026-11-09',
    });
  });

  it('refuses a code whose places are all claimed, as a pre-check only', () => {
    expect(redeemRefusalOf(aCode({ maxClaims: 2, claimCount: 2 }), NOW)).toEqual({
      error: 'codeUsedUp',
    });
    expect(isUsedUp(aCode({ maxClaims: 2, claimCount: 1 }))).toBe(false);
    expect(isUsedUp(aCode({ maxClaims: null, claimCount: 999 }))).toBe(false);
  });

  it('reads dates in South African time', () => {
    expect(sastDate(new Date('2026-12-31T22:30:00Z'))).toBe('2027-01-01');
    expect(sastDate(new Date('2026-12-31T21:30:00Z'))).toBe('2026-12-31');
  });
});

describe('claiming a code voucher in the app', () => {
  it('may happen until thirty days after the code ends', () => {
    expect(claimByOf(aCode())).toEqual(new Date(days(20).getTime() + CLAIM_GRACE_MS));
    expect(claimByOf(aCode({ validUntil: null }))).toBeNull();
    const ended = aCode({ validFrom: days(-60), validUntil: days(-10) });
    expect(claimWindowRefusalOf(ended, aVoucher({ claimBy: null }), NOW)).toBeNull();
    const longEnded = aCode({ validFrom: days(-90), validUntil: days(-31) });
    expect(claimWindowRefusalOf(longEnded, aVoucher({ claimBy: null }), NOW)).toBe('codeExpired');
  });

  it('is refused past the voucher’s own claimBy', () => {
    expect(isPastClaimBy(aVoucher({ claimBy: days(-1) }), NOW)).toBe(true);
    expect(isPastClaimBy(aVoucher({ claimBy: null }), NOW)).toBe(false);
    expect(claimWindowRefusalOf(aCode(), aVoucher({ claimBy: days(-1) }), NOW)).toBe('codeExpired');
  });

  it('is refused for a paused, archived or missing code', () => {
    expect(claimWindowRefusalOf(aCode({ status: 'paused' }), aVoucher(), NOW)).toBe('codePaused');
    expect(claimWindowRefusalOf(aCode({ status: 'archived' }), aVoucher(), NOW)).toBe(
      'codeExpired',
    );
    expect(claimWindowRefusalOf(null, aVoucher(), NOW)).toBe('codeExpired');
  });

  it('goes ahead for an active code inside its window', () => {
    expect(claimWindowRefusalOf(aCode(), aVoucher(), NOW)).toBeNull();
  });
});

describe('one code grant per household per rolling year (D16)', () => {
  it('counts only code grants', () => {
    expect(usedCodeWithinYear([aGrant('frame', 10), aGrant('referral', 10)], NOW)).toBe(false);
    expect(usedCodeWithinYear([aGrant('code', 10)], NOW)).toBe(true);
  });

  it('forgets a code grant older than 365 days', () => {
    expect(usedCodeWithinYear([aGrant('code', 366)], NOW)).toBe(false);
    expect(usedCodeWithinYear([aGrant('code', 364)], NOW)).toBe(true);
  });
});

describe('new to Premium', () => {
  it('means no store purchase and no grant of any source', () => {
    expect(isNewToPremium([], false)).toBe(true);
    expect(isNewToPremium([], true)).toBe(false);
    expect(isNewToPremium([aGrant('frame', 1)], false)).toBe(false);
    expect(isNewToPremium([aGrant('referral', 200)], false)).toBe(false);
  });
});
