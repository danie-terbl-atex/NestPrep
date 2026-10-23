import { describe, expect, it } from 'vitest';

import {
  householdRecipeContent,
  householdRecipeId,
  householdRecipeInput,
  saveLunchRecipesInput,
  MAX_RECIPES_PER_SAVE,
  type HouseholdRecipeInput,
} from '../../../src/recipes/household_recipe';

/**
 * A household recipe (recipes ADR-0002): its allergen codes are the server's
 * — every word of it, plus what the store's labels add, never fewer — and its
 * id is its content, so saving it twice writes it once.
 */

const WRAP: HouseholdRecipeInput = {
  name: 'Mexican wholewheat wrap',
  summary: 'Chicken, corn and cheese rolled in a soft wrap.',
  ingredients: [
    { name: 'Wholewheat tortillas', quantity: 1, unit: null },
    { name: 'Chicken strips', quantity: 50, unit: 'g' },
    { name: 'Sweetcorn', quantity: 2, unit: 'tbsp' },
  ],
  steps: ['Warm the tortilla.', 'Fill and roll.'],
  prepMinutes: 10,
  prepAhead: false,
  prepNote: null,
  alsoContains: [],
};

describe('a household recipe’s allergen codes', () => {
  it('are derived from its words, in family-profiles order', () => {
    expect(householdRecipeContent(WRAP).allergens).toEqual(['milk', 'wheat']);
  });

  it('take what the store’s labels add on top, and can never be made fewer', () => {
    const labelled = householdRecipeContent({ ...WRAP, alsoContains: ['soy'] });
    expect(labelled.allergens).toEqual(['milk', 'wheat', 'soy']);
    const plain = householdRecipeContent({ ...WRAP, summary: 'A wrap.' });
    expect(plain.allergens).toEqual(['wheat']);
  });

  it('is a lunch main, one box’s worth, from the AI, with no notes of its own', () => {
    const content = householdRecipeContent(WRAP);
    expect(content).toMatchObject({
      source: 'ai',
      contexts: ['lunchBox'],
      placement: { lunchBox: 'main' },
      servings: 1,
      dietTags: [],
    });
    expect(content.ingredients[1]).toEqual({
      name: 'Chicken strips',
      quantity: 50,
      unit: 'g',
      note: null,
    });
  });
});

describe('a household recipe is read on its search words too (ADR-0023 §1)', () => {
  it('derives the code an ingredient’s search term names, without storing the term', () => {
    const content = householdRecipeContent({
      ...WRAP,
      summary: 'A wrap.',
      ingredients: [
        { name: 'Wholewheat tortillas', quantity: 1, unit: null },
        { name: 'Spread', quantity: 1, unit: 'tbsp', searchTerm: 'peanut butter' },
      ],
    });
    expect(content.allergens).toContain('peanut');
    expect(JSON.stringify(content.ingredients)).not.toContain('searchTerm');
  });
});

describe('a household recipe’s id is its content', () => {
  it('is the same for the same recipe, and different for another', () => {
    const id = householdRecipeId(householdRecipeContent(WRAP));
    expect(id).toMatch(/^ai-[0-9a-f]{20}$/);
    expect(householdRecipeId(householdRecipeContent({ ...WRAP }))).toBe(id);
    expect(householdRecipeId(householdRecipeContent({ ...WRAP, prepMinutes: 12 }))).not.toBe(id);
  });
});

describe('what the phone may send', () => {
  it('accepts a recipe within the bounds, and refuses one past them', () => {
    expect(householdRecipeInput.safeParse(WRAP).success).toBe(true);
    for (const broken of [
      { ...WRAP, name: '' },
      { ...WRAP, ingredients: [] },
      { ...WRAP, steps: Array.from({ length: 7 }, () => 'Stir.') },
      { ...WRAP, prepMinutes: 0 },
      { ...WRAP, alsoContains: ['gluten'] },
      { ...WRAP, ingredients: [{ name: 'Rice', quantity: 1, unit: 'handful' }] },
    ]) {
      expect(householdRecipeInput.safeParse(broken).success).toBe(false);
    }
  });

  it('saves a week’s dishes at a time, a bounded few', () => {
    const many = Array.from({ length: MAX_RECIPES_PER_SAVE + 1 }, () => WRAP);
    expect(saveLunchRecipesInput.safeParse({ householdId: 'h1', recipes: [WRAP] }).success).toBe(
      true,
    );
    expect(saveLunchRecipesInput.safeParse({ householdId: 'h1', recipes: many }).success).toBe(
      false,
    );
    expect(saveLunchRecipesInput.safeParse({ householdId: 'h1', recipes: [] }).success).toBe(false);
  });
});
