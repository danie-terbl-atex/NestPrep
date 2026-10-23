import { describe, expect, it } from 'vitest';

import { allergensMentionedIn, NOT_ALLERGEN_PHRASES } from '../../../src/plan_week/allergen_words';

/**
 * Recipes ADR-0004: a short list of food names that contain an allergen word
 * but never the allergen is not read for allergen words — and nothing else
 * about the safety net loosens. Every exception is proved here in both
 * directions: the phrase no longer names the code, the allergen word alone
 * still does.
 */
describe('food names that are not the allergen', () => {
  it('butternut is not milk', () => {
    expect(allergensMentionedIn('Butternut squash')).toEqual([]);
    expect(allergensMentionedIn('Roast BUTTERNUT')).toEqual([]);
  });

  it('nutmeg, cream of tartar, cream soda and butter beans name no allergen', () => {
    for (const text of [
      'Ground nutmeg',
      'Cream of tartar',
      'Cream soda',
      'Butter beans',
      'Butter bean',
    ]) {
      expect(allergensMentionedIn(text), text).toEqual([]);
    }
  });

  it('butter, peanut butter, a bare nut and cream still match', () => {
    expect(allergensMentionedIn('Butter')).toEqual(['milk']);
    expect(allergensMentionedIn('Peanut butter')).toEqual(['peanut', 'milk']);
    expect(allergensMentionedIn('Nut')).toEqual(['treeNut']);
    expect(allergensMentionedIn('Mixed nuts')).toEqual(['treeNut']);
    expect(allergensMentionedIn('Fresh cream')).toEqual(['milk']);
    expect(allergensMentionedIn('Buttermilk')).toEqual(['milk']);
  });

  it('only the phrase is skipped — every other word beside it still counts', () => {
    expect(allergensMentionedIn('Butternut and butter')).toEqual(['milk']);
    expect(allergensMentionedIn('Nutmeg and walnuts')).toEqual(['treeNut']);
    expect(allergensMentionedIn('Cream of tartar and cream')).toEqual(['milk']);
    expect(allergensMentionedIn('Butternut soup with cream')).toEqual(['milk']);
  });

  it('a variant not on the list is still read the safe way', () => {
    expect(allergensMentionedIn('Butternuts')).toEqual(['milk']);
    expect(allergensMentionedIn('Coconut milk')).toEqual(['milk']);
    expect(allergensMentionedIn('Coconut')).toEqual([]);
  });

  it('is a short list of plain lower-case words, never coconut or pine nut', () => {
    expect(NOT_ALLERGEN_PHRASES.length).toBeLessThanOrEqual(12);
    for (const phrase of NOT_ALLERGEN_PHRASES) expect(phrase).toMatch(/^[a-z]+(?: [a-z]+)*$/);
    expect(NOT_ALLERGEN_PHRASES).not.toContain('coconut');
    expect(NOT_ALLERGEN_PHRASES).not.toContain('pine nut');
  });
});
