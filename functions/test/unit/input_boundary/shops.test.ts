import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { parseInput } from '../../../src/household/parse_input';
import {
  MAX_ITEMS_PER_PUSH,
  checkersPushToCartInput,
  checkersVerifyOtpInput,
} from '../../../src/checkers/schemas';
import {
  MAX_PACKS_PER_ITEM,
  pnpCompleteLinkInput,
  pnpPushToCartInput,
} from '../../../src/pnp/pnp_schemas';
import { validBodies } from './valid_bodies';

/** The shop callables' edge — Add to Pick n Pay and Add to Checkers (ENG-09, BE-03). */

describe('Add to Pick n Pay refuses what is not a code or a push', () => {
  it('refuses a code or a state that is blank', () => {
    expect(() => parseInput(pnpCompleteLinkInput, { code: ' ', state: 's' })).toThrow(HttpsError);
    expect(() => parseInput(pnpCompleteLinkInput, { code: 'c', state: '' })).toThrow(HttpsError);
  });

  it('refuses a pack count of none, a fraction, or past the bound', () => {
    const body = validBodies.pnpPushToCart.body;
    for (const packs of [0, 1.5, MAX_PACKS_PER_ITEM + 1]) {
      expect(() =>
        parseInput(pnpPushToCartInput, { ...body, quantities: { milk: packs } }),
      ).toThrow(HttpsError);
    }
  });

  it('takes a push without pack counts, and pushes a repeated item once', () => {
    const parsed = parseInput(pnpPushToCartInput, { householdId: 'h1', itemIds: ['a', 'a'] });
    expect(parsed.itemIds).toEqual(['a']);
    expect(parsed.quantities).toBeUndefined();
  });
});

describe('Add to Checkers refuses what is not a code or a push', () => {
  it.each([['123'], ['1234567'], ['12a4'], ['']])('a code of %j', (code) => {
    expect(() => parseInput(checkersVerifyOtpInput, { code })).toThrow(HttpsError);
  });

  it('accepts four to six digits, trimmed', () => {
    expect(parseInput(checkersVerifyOtpInput, { code: ' 1234 ' }).code).toBe('1234');
  });

  it('refuses a push of nothing, or of more than a list holds', () => {
    const body = validBodies.checkersPushToCart.body;
    expect(() => parseInput(checkersPushToCartInput, { ...body, itemIds: [] })).toThrow(HttpsError);
    const tooMany = Array.from(
      { length: MAX_ITEMS_PER_PUSH + 1 },
      (_, index) => `i${String(index)}`,
    );
    expect(() => parseInput(checkersPushToCartInput, { ...body, itemIds: tooMany })).toThrow(
      HttpsError,
    );
  });

  it('pushes a repeated item once', () => {
    const parsed = parseInput(checkersPushToCartInput, { householdId: 'h1', itemIds: ['a', 'a'] });
    expect(parsed.itemIds).toEqual(['a']);
  });
});
