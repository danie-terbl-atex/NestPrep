import type { Recipe } from '../../../src/recipes/recipe';

/** A valid lunch-box recipe for the tests to break one rule at a time. */
export const MUFFIN: Recipe = {
  id: 'test-muffin',
  name: 'Test muffin',
  summary: 'A muffin for the tests.',
  about: null,
  cuisine: 'international',
  contexts: ['lunchBox'],
  placement: { lunchBox: 'treat' },
  tags: [],
  allergens: ['milk', 'egg', 'wheat'],
  dietTags: ['vegetarian'],
  ingredients: [{ name: 'Cake flour', quantity: 1, unit: 'cup', note: null, group: null }],
  steps: ['Bake it.'],
  servings: 6,
  prepMinutes: 10,
  cookMinutes: 20,
  difficulty: 'easy',
  prepAhead: false,
  prepNote: null,
  photo: null,
};

/** A valid dinner recipe with a generated photo. */
export const STEW: Recipe = {
  ...MUFFIN,
  id: 'test-stew',
  name: 'Test stew',
  cuisine: 'southAfrican',
  contexts: ['dinner', 'lunch'],
  placement: { dinner: 'main', lunch: 'main' },
  tags: ['potjie', 'comfort'],
  allergens: [],
  ingredients: [
    { name: 'Lamb', quantity: 1, unit: 'kg', note: null, group: 'For the stew' },
    { name: 'Garlic cloves', quantity: 3, unit: null, note: 'crushed', group: 'For the stew' },
    { name: 'Rice', quantity: 2, unit: 'cup', note: null, group: 'To serve' },
  ],
  prepMinutes: 20,
  cookMinutes: 120,
  difficulty: 'medium',
  photo: { credit: null, licence: null, sourceUrl: null, generated: true },
};
