import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import { ALLERGEN_WORDS } from '../../../src/plan_week/allergen_words';
import { ALLERGENS } from '../../../src/plan_week/food_safety';

/**
 * The phone strikes products out with `AllergenWords`; the server strikes
 * ideas out and re-checks products with `ALLERGEN_WORDS`. If the two lists
 * drift, the phone and the server disagree about what is safe (lunch-box
 * ADR-0012).
 */
const DART = resolve(
  import.meta.dirname,
  '../../../../app/lib/features/plan_week/model/allergen_words.dart',
);

function dartWordsFor(source: string, code: string): string[] {
  const entry = new RegExp(`Allergen\\.${code}\\s*:\\s*(?:const\\s*)?\\[([^\\]]*)\\]`).exec(source);
  if (entry === null) return [];
  return [...(entry[1] ?? '').matchAll(/'([^']*)'/g)].map((match) => match[1] ?? '');
}

describe('the allergen words', () => {
  it('are the same in the app and in Functions, code by code', () => {
    const source = readFileSync(DART, 'utf8');
    for (const code of ALLERGENS) {
      expect(dartWordsFor(source, code), code).toEqual([...ALLERGEN_WORDS[code]]);
    }
  });
});
