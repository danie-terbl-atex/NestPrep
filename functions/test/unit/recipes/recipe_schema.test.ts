import { describe, expect, it } from 'vitest';

import { recipeSource } from '../../../src/recipes/recipe';
import { MUFFIN, STEW } from './recipe_fixture';

/**
 * Recipes ADR-0001 and ADR-0003: the shape every catalogue recipe is parsed
 * into before it is published. A recipe that breaks it never reaches a
 * household, so each refusal here is a recipe the seed will not publish.
 */
const parses = (value: unknown): boolean => recipeSource.safeParse(value).success;

describe('a recipe’s contexts and placement', () => {
  it('accepts the lunch box by compartment and the three meals by course', () => {
    expect(parses(MUFFIN)).toBe(true);
    expect(parses(STEW)).toBe(true);
    expect(
      parses({
        ...STEW,
        contexts: ['breakfast', 'lunch', 'dinner'],
        placement: { breakfast: 'snack', lunch: 'side', dinner: 'dessert' },
      }),
    ).toBe(true);
  });

  it('refuses a placement that does not name exactly the contexts', () => {
    expect(parses({ ...MUFFIN, placement: {} })).toBe(false);
    expect(parses({ ...MUFFIN, contexts: [] })).toBe(false);
    expect(parses({ ...STEW, placement: { dinner: 'main' } })).toBe(false);
    expect(parses({ ...STEW, contexts: ['dinner', 'dinner'] })).toBe(false);
  });

  it('refuses a course in the lunch box and a compartment at a meal', () => {
    expect(parses({ ...MUFFIN, placement: { lunchBox: 'dessert' } })).toBe(false);
    expect(parses({ ...STEW, placement: { dinner: 'treat', lunch: 'main' } })).toBe(false);
    expect(parses({ ...STEW, contexts: ['supper'], placement: { supper: 'main' } })).toBe(false);
  });
});

describe('a recipe’s fields', () => {
  it('refuses an allergen code nobody checks, one listed twice, and extra fields', () => {
    expect(parses({ ...MUFFIN, allergens: ['lupin'] })).toBe(false);
    expect(parses({ ...MUFFIN, allergens: ['milk', 'milk'] })).toBe(false);
    expect(parses({ ...MUFFIN, price: 1200 })).toBe(false);
  });

  it('takes tags only from the vocabulary, once each, four at most', () => {
    expect(parses({ ...STEW, tags: ['potjie', 'braai', 'budget', 'festive'] })).toBe(true);
    expect(parses({ ...STEW, tags: ['spicy'] })).toBe(false);
    expect(parses({ ...STEW, tags: ['potjie', 'potjie'] })).toBe(false);
    expect(parses({ ...STEW, tags: ['potjie', 'braai', 'budget', 'festive', 'comfort'] })).toBe(
      false,
    );
  });

  it('calls a recipe quick only when prep and cooking fit in thirty minutes', () => {
    expect(parses({ ...MUFFIN, tags: ['quick'], prepMinutes: 10, cookMinutes: 20 })).toBe(true);
    expect(parses({ ...MUFFIN, tags: ['quick'], prepMinutes: 10, cookMinutes: 21 })).toBe(false);
  });

  it('bounds cooking time, difficulty, cuisine and about', () => {
    expect(parses({ ...STEW, cookMinutes: 720 })).toBe(true);
    expect(parses({ ...STEW, cookMinutes: 721 })).toBe(false);
    expect(parses({ ...STEW, cookMinutes: -1 })).toBe(false);
    expect(parses({ ...STEW, difficulty: 'hard' })).toBe(false);
    expect(parses({ ...STEW, cuisine: 'french' })).toBe(false);
    expect(parses({ ...STEW, about: 'x'.repeat(400) })).toBe(true);
    expect(parses({ ...STEW, about: 'x'.repeat(401) })).toBe(false);
  });
});

describe('a recipe’s ingredient lines', () => {
  const line = { name: 'Flour', quantity: 1, unit: 'cup', note: null, group: null };

  it('take a unit only from the meal plan’s vocabulary, or none for a count', () => {
    for (const unit of ['g', 'kg', 'ml', 'l', 'pack', 'tin', 'loaf', 'bunch', 'bottle', 'tsp']) {
      expect(parses({ ...MUFFIN, ingredients: [{ ...line, unit }] }), unit).toBe(true);
    }
    expect(parses({ ...MUFFIN, ingredients: [{ ...line, unit: null }] })).toBe(true);
    for (const unit of ['cups', 'clove', 'slices', 'pinch']) {
      expect(parses({ ...MUFFIN, ingredients: [{ ...line, unit }] }), unit).toBe(false);
    }
  });

  it('set a group on every line or on none', () => {
    const grouped = { ...line, group: 'For the crumble' };
    expect(parses({ ...MUFFIN, ingredients: [grouped, grouped] })).toBe(true);
    expect(parses({ ...MUFFIN, ingredients: [grouped, line] })).toBe(false);
    expect(parses({ ...MUFFIN, ingredients: [{ ...line, group: 'x'.repeat(41) }] })).toBe(false);
  });

  it('carry nothing but name, quantity, unit, note and group', () => {
    expect(parses({ ...MUFFIN, ingredients: [{ ...line, searchTerm: 'flour' }] })).toBe(false);
  });
});

describe('a recipe’s photo', () => {
  const licensed = {
    credit: 'A. Photographer',
    licence: 'CC BY-SA 4.0',
    sourceUrl: 'https://commons.wikimedia.org/wiki/File:Bobotie.jpg',
    generated: false,
  };

  it('is generated with no attribution, or openly licensed from Commons with all of it', () => {
    expect(parses({ ...STEW, photo: licensed })).toBe(true);
    expect(parses({ ...STEW, photo: { ...licensed, licence: 'CC0' } })).toBe(true);
    expect(parses({ ...STEW, photo: { ...licensed, licence: 'CC BY 2.0' } })).toBe(true);
    expect(parses({ ...STEW, photo: { ...licensed, generated: true } })).toBe(false);
    expect(parses({ ...STEW, photo: { ...licensed, credit: null } })).toBe(false);
  });

  it('is never non-commercial, no-derivatives, or from somewhere other than Commons', () => {
    expect(parses({ ...STEW, photo: { ...licensed, licence: 'CC BY-NC 4.0' } })).toBe(false);
    expect(parses({ ...STEW, photo: { ...licensed, licence: 'CC BY-ND 4.0' } })).toBe(false);
    expect(
      parses({ ...STEW, photo: { ...licensed, sourceUrl: 'https://recipes.example/bobotie' } }),
    ).toBe(false);
  });

  it('is written without its file paths — the seed adds those', () => {
    expect(parses({ ...STEW, photo: { ...STEW.photo, card: 'recipes/x/card.jpg' } })).toBe(false);
  });
});
