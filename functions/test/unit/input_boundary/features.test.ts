import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { parseInput } from '../../../src/household/parse_input';
import { ALTERNATING } from '../../coparent_fixtures';
import { redeemReferralCodeInput } from '../../../src/referrals/schemas';
import { setChildProfileInput, verifyPurchaseInput } from '../../../src/subscriptions/schemas';
import {
  MAX_TEXTS_PER_CALL,
  MAX_TEXT_LENGTH,
  translateHomeCareTextsInput,
} from '../../../src/home_care/schemas';
import { validBodies } from './valid_bodies';

/** The feature callables' edge — what each one refuses beyond its shape (ENG-09, BE-03). */

describe('translateHomeCareTexts refuses what is not a translation to make', () => {
  const body = validBodies.translateHomeCareTexts.body;
  it.each([
    ['English, which every text is already in', { ...body, language: 'en' }],
    ['a language the helper cannot choose', { ...body, language: 'fr' }],
    ['no texts at all', { ...body, texts: [] }],
    ['a blank text', { ...body, texts: ['   '] }],
    ['a text longer than any step', { ...body, texts: ['x'.repeat(MAX_TEXT_LENGTH + 1)] }],
    ['more texts than a job has', { ...body, texts: Array(MAX_TEXTS_PER_CALL + 1).fill('Mop') }],
  ])('%s', (_, candidate) => {
    expect(() => parseInput(translateHomeCareTextsInput, candidate)).toThrow(HttpsError);
  });

  it('asks for a repeated text once, trimmed', () => {
    const parsed = parseInput(translateHomeCareTextsInput, {
      ...body,
      texts: [' Mop the floor ', 'Mop the floor'],
    });
    expect(parsed.texts).toEqual(['Mop the floor']);
  });
});

describe('verifyPurchase refuses what is not a purchase to verify', () => {
  const body = validBodies.verifyPurchase.body;
  it.each([
    ['a store that is not one of the two', { ...body, store: 'webStore' }],
    ['a trigger the analytics do not know', { ...body, trigger: 'somethingElse' }],
    [
      'a receipt longer than any signed transaction',
      { ...body, verificationData: 'x'.repeat(60_001) },
    ],
    ['an empty receipt', { ...body, verificationData: '   ' }],
  ])('%s', (_, candidate) => {
    expect(() => parseInput(verifyPurchaseInput, candidate)).toThrow(HttpsError);
  });

  it('accepts a restore, which names no trigger', () => {
    expect(() => parseInput(verifyPurchaseInput, { ...body, trigger: null })).not.toThrow();
  });
});

describe('setChildProfile’s parental consent (accounts ADR-0005)', () => {
  const body = { householdId: 'h1', memberId: 'm-kid', isChild: true };

  it('is a policy version, given as the child is marked', () => {
    expect(() =>
      parseInput(setChildProfileInput, { ...body, guardianConsent: { version: 1 } }),
    ).not.toThrow();
  });

  it.each([
    ['a version below 1', { version: 0 }],
    ['a version that is not whole', { version: 1.5 }],
    ['a version as text', { version: '1' }],
    ['a member id of the caller’s choosing', { version: 1, byMemberId: 'm-other' }],
    ['a bare yes', true],
  ])('refuses %s', (_, guardianConsent) => {
    expect(() => parseInput(setChildProfileInput, { ...body, guardianConsent })).toThrow(
      HttpsError,
    );
  });
});

describe('a referral code as a person types it (subscriptions ADR-0002)', () => {
  const body = validBodies.redeemReferralCode.body;

  it('forgives spaces and lower case, and hands on the code as it is stored', () => {
    const parsed = parseInput(redeemReferralCodeInput, { ...body, code: ' abcd 2345 ' });
    expect(parsed.code).toBe('ABCD2345');
  });

  it.each([
    ['a letter people confuse with a digit', 'ABCD0123'],
    ['a code one short', 'ABCD234'],
    ['a code one long', 'ABCD23456'],
    ['something that is not a code at all', 'sam@example.com'],
  ])('refuses %s', (_, code) => {
    expect(() => parseInput(redeemReferralCodeInput, { ...body, code })).toThrow(HttpsError);
  });
});

describe('a school letter', () => {
  const { schema, body } = validBodies.readSchoolLetter;

  it('is a photo or a PDF, and nothing else', () => {
    for (const mimeType of ['image/jpeg', 'image/png', 'application/pdf']) {
      expect(() => parseInput(schema, { ...body, mimeType })).not.toThrow();
    }
    for (const mimeType of ['image/gif', 'text/html', 'application/zip', '']) {
      expect(() => parseInput(schema, { ...body, mimeType }), mimeType).toThrow(HttpsError);
    }
  });

  it('is not empty, and not larger than a callable should carry', () => {
    expect(() => parseInput(schema, { ...body, data: '' })).toThrow(HttpsError);
    expect(() => parseInput(schema, { ...body, data: 'A'.repeat(12_000_000) })).toThrow(HttpsError);
  });
});

describe('a lunch box’s picture', () => {
  const { schema, body } = validBodies.lunchPhoto;

  it('is of a day that exists, written as a day', () => {
    for (const date of ['2026-02-30', '2026-10-5', '05/10/2026', '2026-W41', '']) {
      expect(() => parseInput(schema, { ...body, date }), date).toThrow(HttpsError);
    }
  });
});

describe('co-parenting inputs (household ADR-0004)', () => {
  const accept = validBodies.acceptCoParentInvite;

  it('a child is an existing profile or a new name, never both and never neither', () => {
    expect(() =>
      parseInput(accept.schema, { ...accept.body, childMemberId: null, newChildName: 'Sam' }),
    ).not.toThrow();
    expect(() => parseInput(accept.schema, { ...accept.body, newChildName: 'Sam' })).toThrow(
      HttpsError,
    );
    expect(() => parseInput(accept.schema, { ...accept.body, childMemberId: null })).toThrow(
      HttpsError,
    );
  });

  it('a home is drawn in a palette colour, not any string', () => {
    expect(() =>
      parseInput(accept.schema, { ...accept.body, home: { name: 'Dad', color: '#ff0000' } }),
    ).toThrow(HttpsError);
  });

  it('a blank note is no note', () => {
    const { schema, body } = validBodies.answerCoParentChange;
    expect(parseInput(schema, { ...body, note: '   ' }).note).toBeNull();
  });

  it('a change is a swap or a schedule, and nothing else', () => {
    const { schema, body } = validBodies.proposeCoParentChange;
    expect(() =>
      parseInput(schema, { ...body, change: { kind: 'schedule', schedule: ALTERNATING } }),
    ).not.toThrow();
    expect(() => parseInput(schema, { ...body, change: { kind: 'forever' } })).toThrow(HttpsError);
  });

  it('an answer is accept, decline or withdraw', () => {
    const { schema, body } = validBodies.answerCoParentChange;
    expect(() => parseInput(schema, { ...body, answer: 'insist' })).toThrow(HttpsError);
  });

  it('a handover holds at most thirty bag items', () => {
    const { schema, body } = validBodies.saveCoParentHandover;
    const items = Array.from({ length: 31 }, () => ({ text: 'Sock', packed: false }));
    expect(() => parseInput(schema, { ...body, items })).toThrow(HttpsError);
  });
});
