import { describe, expect, it } from 'vitest';

import {
  allergensOfOwnRecipe,
  deleteHouseholdRecipeInput,
  ownRecipeContent,
  saveHouseholdRecipeInput,
  type SaveHouseholdRecipeInput,
} from '../../../src/recipes/own_recipe';

const ID = 'own-0123456789abcdef0123';

const body = (more: Record<string, unknown> = {}): Record<string, unknown> => ({
  householdId: 'h1',
  recipeId: ID,
  name: 'Bobotie',
  summary: 'Spiced mince.',
  contexts: ['dinner'],
  placement: { dinner: 'main' },
  ingredients: [{ name: 'Beef mince', quantity: 1, unit: 'kg', note: null, group: null }],
  steps: ['Brown the mince.'],
  servings: 6,
  prepMinutes: 20,
  cookMinutes: 40,
  notes: null,
  origin: 'typed',
  sourceUrl: null,
  sourceName: null,
  alsoContains: [],
  photo: null,
  gallery: [],
  ...more,
});

const accepts = (more: Record<string, unknown>): boolean =>
  saveHouseholdRecipeInput.safeParse(body(more)).success;

const parsed = (more: Record<string, unknown> = {}): SaveHouseholdRecipeInput =>
  saveHouseholdRecipeInput.parse(body(more));

const line = (name: string): Record<string, unknown> => ({
  name,
  quantity: null,
  unit: null,
  note: null,
  group: null,
});

const photo = (photoId: string): Record<string, unknown> => ({
  photoId,
  credit: null,
  sourceUrl: null,
});

describe('what a save accepts', () => {
  it('takes only an own id, on save and delete alike', () => {
    for (const recipeId of [
      'ai-0123456789abcdef0123',
      'own-0123',
      'own-0123456789ABCDEF0123',
      'own-0123456789abcdef0123/..',
      '../own-0123456789abcdef0123',
      '',
    ]) {
      expect(accepts({ recipeId }), recipeId).toBe(false);
      expect(deleteHouseholdRecipeInput.safeParse({ householdId: 'h1', recipeId }).success).toBe(
        false,
      );
    }
    expect(deleteHouseholdRecipeInput.safeParse({ householdId: 'h1', recipeId: ID }).success).toBe(
      true,
    );
  });

  it('holds 30 lines and 20 steps of 400 characters, and no more', () => {
    const lines = (count: number): unknown[] =>
      Array.from({ length: count }, (_, at) => line(`Thing ${String(at)}`));
    expect(accepts({ ingredients: lines(30) })).toBe(true);
    expect(accepts({ ingredients: lines(31) })).toBe(false);
    expect(accepts({ ingredients: [] })).toBe(false);
    const step = 'x'.repeat(400);
    expect(accepts({ steps: Array.from({ length: 20 }, () => step) })).toBe(true);
    expect(accepts({ steps: Array.from({ length: 21 }, () => step) })).toBe(false);
    expect(accepts({ steps: [`${step}x`] })).toBe(false);
    expect(accepts({ steps: [] })).toBe(false);
  });

  it('holds a quantity to 10,000 and a unit to the vocabulary', () => {
    const quantity = (value: unknown, unit: unknown = 'g'): Record<string, unknown> => ({
      ingredients: [{ ...line('Flour'), quantity: value, unit }],
    });
    expect(accepts(quantity(10_000))).toBe(true);
    expect(accepts(quantity(10_001))).toBe(false);
    expect(accepts(quantity(0))).toBe(false);
    expect(accepts(quantity(0.5, 'cup'))).toBe(true);
    expect(accepts(quantity(1, 'oz'))).toBe(false);
  });

  it('takes breakfast, lunch and dinner, each with a course, and never the lunch box', () => {
    expect(
      accepts({
        contexts: ['breakfast', 'lunch'],
        placement: { breakfast: 'main', lunch: 'side' },
      }),
    ).toBe(true);
    expect(accepts({ contexts: ['lunchBox'], placement: { lunchBox: 'main' } })).toBe(false);
    expect(accepts({ contexts: ['dinner'], placement: {} })).toBe(false);
    expect(accepts({ contexts: ['dinner'], placement: { lunch: 'main' } })).toBe(false);
    expect(accepts({ contexts: ['dinner'], placement: { dinner: 'pudding' } })).toBe(false);
    expect(accepts({ contexts: ['dinner', 'dinner'], placement: { dinner: 'main' } })).toBe(false);
    expect(accepts({ contexts: [], placement: {} })).toBe(false);
  });

  it('refuses an allergen code it does not know', () => {
    expect(accepts({ alsoContains: ['peanut'] })).toBe(true);
    expect(accepts({ alsoContains: ['gluten'] })).toBe(false);
  });

  it('takes photo ids and never a path', () => {
    expect(accepts({ photo: photo('AbCd1234_-') })).toBe(true);
    for (const photoId of ['short', '../AbCd1234', 'a/b/c/d/e/f', 'recipes/x/hero.jpg', '']) {
      expect(accepts({ photo: photo(photoId) }), photoId).toBe(false);
    }
  });

  it('holds a gallery to five, under a cover, each photo once', () => {
    const gallery = (count: number): unknown[] =>
      Array.from({ length: count }, (_, at) => photo(`gallery00${String(at)}`));
    expect(accepts({ photo: photo('coverphoto'), gallery: gallery(5) })).toBe(true);
    expect(accepts({ photo: photo('coverphoto'), gallery: gallery(6) })).toBe(false);
    expect(accepts({ photo: null, gallery: gallery(1) })).toBe(false);
    expect(accepts({ photo: photo('coverphoto'), gallery: [photo('coverphoto')] })).toBe(false);
  });

  it('reads a blank optional text as none', () => {
    expect(parsed({ notes: '   ', sourceName: '' })).toMatchObject({
      notes: null,
      sourceName: null,
    });
  });
});

describe('the allergen codes it carries', () => {
  const codes = (more: Record<string, unknown>): string[] => allergensOfOwnRecipe(parsed(more));

  it('come from the name, the summary and each line’s name, note and heading', () => {
    expect(codes({ name: 'Peanut stew' })).toEqual(['peanut']);
    expect(codes({ summary: 'With sesame.' })).toEqual(['sesame']);
    expect(codes({ ingredients: [line('Eggs')] })).toEqual(['egg']);
    expect(codes({ ingredients: [{ ...line('Mix'), note: 'with soy' }] })).toEqual(['soy']);
    expect(codes({ ingredients: [{ ...line('Mix'), group: 'For the custard milk' }] })).toEqual([
      'milk',
    ]);
  });

  it('come from the steps and the notes as well, where a lunch recipe stops short', () => {
    expect(codes({ steps: ['Brush with egg.'] })).toEqual(['egg']);
    expect(codes({ notes: 'Lovely with a spoon of cream.' })).toEqual(['milk']);
  });

  it('take the member’s own and can only grow, in family-profiles order', () => {
    expect(codes({ name: 'Egg bake', alsoContains: ['peanut'] })).toEqual(['peanut', 'egg']);
    expect(codes({ name: 'Egg bake', alsoContains: [] })).toEqual(['egg']);
  });

  it('are blind to other languages, which is why the app never shows an all-clear', () => {
    expect(codes({ name: 'Eiers en botter' })).toEqual([]);
  });
});

describe('the document it becomes', () => {
  it('keeps the member’s codes apart from the derived ones, so an edit round-trips them', () => {
    expect(ownRecipeContent(parsed({ alsoContains: ['sesame'] }))).toMatchObject({
      alsoContains: ['sesame'],
      allergens: ['sesame'],
    });
  });

  it('claims nothing it can’t verify, and never names a version or who updated it', () => {
    const content = ownRecipeContent(parsed());
    expect(content).toMatchObject({ source: 'own', dietTags: [], kcalPerServing: null });
    expect(content).not.toHaveProperty('version');
    expect(content).not.toHaveProperty('updatedBy');
    expect(content).not.toHaveProperty('addedBy');
    expect(content).not.toHaveProperty('createdAt');
  });

  it('builds photo paths from ids, under this household and this recipe alone', () => {
    const content = ownRecipeContent(
      parsed({
        photo: { photoId: 'coverphoto', credit: 'drizzleanddip.com', sourceUrl: null },
        gallery: [photo('secondphoto')],
      }),
    );
    expect(content['photo']).toEqual({
      card: `households/h1/recipePhotos/${ID}/coverphoto-card.jpg`,
      hero: `households/h1/recipePhotos/${ID}/coverphoto-hero.jpg`,
      credit: 'drizzleanddip.com',
      sourceUrl: null,
    });
    expect(content['gallery']).toEqual([
      {
        card: `households/h1/recipePhotos/${ID}/secondphoto-card.jpg`,
        hero: `households/h1/recipePhotos/${ID}/secondphoto-hero.jpg`,
        credit: null,
        sourceUrl: null,
      },
    ]);
  });

  it('has none when none was named', () => {
    expect(ownRecipeContent(parsed())).toMatchObject({ photo: null, gallery: [] });
  });
});
