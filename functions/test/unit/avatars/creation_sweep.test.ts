import { Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';

import { isAbandonedClaim, ledgerMonths, stuckEnding } from '../../../src/avatars/creation_sweep';

/** The decisions of the hourly sweep of stuck creations (avatars ADR-0003). */

const cutoff = new Date('2026-11-13T10:00:00Z');
const before = Timestamp.fromDate(new Date('2026-11-13T09:59:00Z'));
const after = Timestamp.fromDate(new Date('2026-11-13T10:01:00Z'));

describe('a stuck creation', () => {
  it('fails unless its picture was already kept', () => {
    expect(stuckEnding({ status: 'checking' })).toBe('failed');
    expect(stuckEnding({ status: 'drawing', imageHash: 'a'.repeat(32) })).toBe('failed');
    expect(stuckEnding({ status: 'drawing', imageHash: 'a'.repeat(32), keepsakeId: 'k1' })).toBe(
      'ready',
    );
  });
});

describe('a claim on the ledger', () => {
  const claim = { status: 'claimed', feature: 'avatarCreate', claimedAt: before };

  it('is abandoned when it is a creation’s, still claimed and older than the hour', () => {
    expect(isAbandonedClaim(claim, cutoff)).toBe(true);
    expect(isAbandonedClaim({ ...claim, feature: 'avatarPortrait' }, cutoff)).toBe(true);
    expect(isAbandonedClaim({ ...claim, feature: 'avatarCheck' }, cutoff)).toBe(true);
  });

  it('is left alone when settled, recent, another feature’s or undated', () => {
    expect(isAbandonedClaim({ ...claim, status: 'succeeded' }, cutoff)).toBe(false);
    expect(isAbandonedClaim({ ...claim, status: 'failed' }, cutoff)).toBe(false);
    expect(isAbandonedClaim({ ...claim, claimedAt: after }, cutoff)).toBe(false);
    expect(isAbandonedClaim({ ...claim, feature: 'schoolLetter' }, cutoff)).toBe(false);
    expect(isAbandonedClaim({ ...claim, claimedAt: null }, cutoff)).toBe(false);
  });
});

describe('the months a creation may be counted in', () => {
  it('is the household’s month it was asked in', () => {
    expect(ledgerMonths('Africa/Johannesburg', new Date('2026-11-13T08:00:00Z'))).toEqual([
      '2026-11',
    ]);
  });

  it('is both months for one asked in the last minutes of a month, in the household’s zone', () => {
    expect(ledgerMonths('Africa/Johannesburg', new Date('2026-11-30T21:55:00Z'))).toEqual([
      '2026-11',
      '2026-12',
    ]);
    expect(ledgerMonths('UTC', new Date('2026-11-30T21:55:00Z'))).toEqual(['2026-11']);
  });
});
