import { describe, expect, it } from 'vitest';

import { recipeDocument } from '../../../src/recipes/recipe_document';
import { MUFFIN, STEW } from './recipe_fixture';

/**
 * Recipes ADR-0003: what `recipes/{id}` holds — every field the app reads,
 * spelled out (BE-02), with the photo's Storage paths beside its attribution.
 */
const PATHS = {
  hero: 'recipes/test-stew/hero-0123abcd.jpg',
  card: 'recipes/test-stew/card-4567ef01.jpg',
};

describe('a stored recipe', () => {
  it('holds exactly the published fields, and never its id', () => {
    expect(Object.keys(recipeDocument(STEW, PATHS)).sort()).toEqual(
      [
        'about',
        'allergens',
        'contexts',
        'cookMinutes',
        'cuisine',
        'dietTags',
        'difficulty',
        'ingredients',
        'kcalPerServing',
        'name',
        'photo',
        'placement',
        'prepAhead',
        'prepMinutes',
        'prepNote',
        'servings',
        'source',
        'steps',
        'summary',
        'tags',
      ].sort(),
    );
    expect(recipeDocument(STEW, PATHS).source).toBe('nestprep');
  });

  it('carries each ingredient’s group and a photo’s paths with its attribution', () => {
    const stored = recipeDocument(STEW, PATHS);
    expect(stored.ingredients[0]).toEqual({
      name: 'Lamb',
      quantity: 1,
      unit: 'kg',
      note: null,
      group: 'For the stew',
    });
    expect(stored.photo).toEqual({
      ...PATHS,
      credit: null,
      licence: null,
      sourceUrl: null,
      generated: true,
    });
  });

  it('stores no photo for a recipe without one, and refuses a photo nobody published', () => {
    expect(recipeDocument(MUFFIN, null).photo).toBeNull();
    expect(recipeDocument(MUFFIN, PATHS).photo).toBeNull();
    expect(() => recipeDocument(STEW, null)).toThrow(/test-stew has a photo nobody published/);
  });

  it('lists allergen codes in the family-profiles order', () => {
    const shuffled = recipeDocument({ ...MUFFIN, allergens: ['wheat', 'milk', 'egg'] }, null);
    expect(shuffled.allergens).toEqual(['milk', 'egg', 'wheat']);
  });
});
