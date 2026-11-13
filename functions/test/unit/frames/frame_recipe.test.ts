import { describe, expect, it } from 'vitest';

import { catalogueSource } from '../../../src/catalogue/publish_catalogue';
import {
  buildFrameRecipe,
  frameRecipe,
  frameRecipeDocument,
  frameRecipePhotoPath,
  frameRecipeShareInput,
  ownRecipeFrameDocument,
  type FrameRecipeDocument,
  type FrameRecipeShareInput,
} from '../../../src/frames/frame_recipe';
import { stepTimers } from '../../../src/frames/frame_recipe_timers';
import { RECIPES } from '../../../src/recipes/recipe';

const ID = 'bunny-chow';

function stored(status = 'published'): Record<string, unknown> {
  const entry = catalogueSource().entries[RECIPES]?.find(({ id }) => id === ID);
  if (entry === undefined) throw new Error(`the catalogue has no ${ID}`);
  return { ...entry.fields, status, version: 3, updatedAt: new Date() };
}

const document = frameRecipeDocument.parse(stored());

const amountsFor = (recipe: FrameRecipeDocument): (string | null)[] =>
  recipe.ingredients.map(({ quantity }) => (quantity === null ? null : `${String(quantity)} g`));

const replaced = <T>(values: readonly T[], index: number, value: T): T[] =>
  values.map((current, at) => (at === index ? value : current));

const share = (overrides: Partial<FrameRecipeShareInput> = {}): FrameRecipeShareInput => ({
  id: ID,
  people: 4,
  amounts: amountsFor(document),
  ...overrides,
});

describe('a recipe read for the frame', () => {
  it('reads a published or retired recipe and nothing else', () => {
    expect(frameRecipeDocument.safeParse(stored('published')).success).toBe(true);
    expect(frameRecipeDocument.safeParse(stored('retired')).success).toBe(true);
    expect(frameRecipeDocument.safeParse(stored('draft')).success).toBe(false);
    expect(frameRecipeDocument.safeParse({ ...stored(), status: undefined }).success).toBe(false);
  });

  it('finds the hero photo’s Storage path', () => {
    expect(frameRecipePhotoPath(document)).toMatch(/^recipes\/bunny-chow\/hero-[0-9a-f]{8}\.jpg$/);
    expect(frameRecipePhotoPath({ ...document, photo: null })).toBeNull();
  });
});

describe('the recipe a frame cooks along with', () => {
  it('carries the catalogue’s words, the app’s amounts and each step’s timers', () => {
    const amounts = amountsFor(document);
    const built = buildFrameRecipe(document, share({ people: 6, amounts }));
    expect(built).not.toBeNull();
    expect(frameRecipe.parse(built)).toEqual(built);
    expect(built).toMatchObject({
      recipeId: ID,
      name: document.name,
      summary: document.summary,
      people: 6,
      servings: document.servings,
      prepMinutes: document.prepMinutes,
      cookMinutes: document.cookMinutes,
      difficulty: document.difficulty,
      photo: true,
      prepNote: document.prepNote,
    });
    expect(built?.ingredients).toEqual(
      document.ingredients.map(({ group, name, note }, line) => ({
        group,
        amount: amounts[line],
        name,
        note,
      })),
    );
    expect(built?.ingredients.some(({ amount }) => amount === null)).toBe(true);
    expect(built?.steps).toEqual(
      document.steps.map((text) => ({ text, timers: stepTimers(text) })),
    );
    expect(built?.steps.some(({ timers }) => timers.length > 0)).toBe(true);
  });

  it('says there is no photo when the recipe has none', () => {
    expect(buildFrameRecipe({ ...document, photo: null }, share())?.photo).toBe(false);
  });

  it('refuses amounts that do not line up with the ingredients', () => {
    const amounts = amountsFor(document);
    const blank = amounts.indexOf(null);
    const counted = amounts.findIndex((amount) => amount !== null);
    expect(buildFrameRecipe(document, share({ amounts: amounts.slice(1) }))).toBeNull();
    expect(buildFrameRecipe(document, share({ amounts: [...amounts, '1'] }))).toBeNull();
    expect(
      buildFrameRecipe(document, share({ amounts: replaced(amounts, blank, '1 pinch') })),
    ).toBeNull();
    expect(
      buildFrameRecipe(document, share({ amounts: replaced(amounts, counted, null) })),
    ).toBeNull();
  });
});

describe('a recipe shared to a frame', () => {
  const input = { id: ID, people: 4, amounts: ['1 1/2 cups', '250 g', '3', null, '0.5 tsp'] };

  it('takes the amounts as the phone prints them, trimmed', () => {
    expect(frameRecipeShareInput.parse({ ...input, amounts: ['  250 g ', null] })).toEqual({
      ...input,
      amounts: ['250 g', null],
    });
    expect(frameRecipeShareInput.safeParse(input).success).toBe(true);
    expect(frameRecipeShareInput.safeParse({ ...input, amounts: [] }).success).toBe(true);
    expect(frameRecipeShareInput.safeParse({ ...input, amounts: ['a'.repeat(24)] }).success).toBe(
      true,
    );
    expect(frameRecipeShareInput.safeParse({ ...input, people: 1 }).success).toBe(true);
    expect(frameRecipeShareInput.safeParse({ ...input, people: 24 }).success).toBe(true);
  });

  it.each<[string, unknown]>([
    ['an empty amount', { ...input, amounts: [''] }],
    ['a blank amount', { ...input, amounts: ['   '] }],
    ['a long amount', { ...input, amounts: ['a'.repeat(25)] }],
    ['a unicode fraction', { ...input, amounts: ['1½ cups'] }],
    ['a dash', { ...input, amounts: ['2-3'] }],
    ['markup', { ...input, amounts: ['<b>3</b>'] }],
    ['a newline', { ...input, amounts: ['3\ncups'] }],
    ['a number', { ...input, amounts: [3] }],
    ['too many lines', { ...input, amounts: Array<string>(31).fill('1') }],
    ['no amounts', { id: ID, people: 4 }],
    ['nobody', { ...input, people: 0 }],
    ['too many people', { ...input, people: 25 }],
    ['a fraction of a person', { ...input, people: 2.5 }],
    ['an id that is not a recipe’s', { ...input, id: 'Bunny Chow' }],
    ['a path for an id', { ...input, id: '../households/x' }],
    ['a long id', { ...input, id: 'a'.repeat(61) }],
  ])('refuses %s', (_why, value) => {
    expect(frameRecipeShareInput.safeParse(value).success).toBe(false);
  });
});

describe('a household’s own recipe on the frame (photo-frames ADR-0018)', () => {
  const OWN_ID = 'own-0123456789abcdef0123';
  const line = (name: string, quantity: number | null): Record<string, unknown> => ({
    name,
    quantity,
    unit: quantity === null ? null : 'g',
    note: quantity === null ? 'to taste' : null,
    group: null,
  });
  const own = (more: Record<string, unknown> = {}): Record<string, unknown> => ({
    source: 'own',
    name: 'Gran’s bobotie',
    summary: '',
    servings: 6,
    prepMinutes: 0,
    cookMinutes: 40,
    ingredients: [line('Mince', 500), line('Salt', null)],
    steps: ['Bake for 40 minutes.'],
    photo: { card: 'c.jpg', hero: 'h.jpg', credit: null, sourceUrl: null },
    notes: 'Serve with chutney.',
    gallery: [],
    allergens: [],
    ...more,
  });

  it('accepts its id and the household marker, and a share with no marker stays valid', () => {
    const shared = { id: OWN_ID, people: 4, amounts: [] };
    expect(frameRecipeShareInput.parse({ ...shared, household: true }).household).toBe(true);
    expect(frameRecipeShareInput.parse(shared).household).toBeUndefined();
    expect(frameRecipeShareInput.safeParse({ ...shared, household: 'yes' }).success).toBe(false);
  });

  it('builds the same keys a catalogue recipe does, with nothing to show as null', () => {
    const source = ownRecipeFrameDocument.parse(own());
    const built = buildFrameRecipe(source, { id: OWN_ID, people: 4, amounts: ['335 g', null] });
    expect(built).not.toBeNull();
    expect(frameRecipe.parse(built)).toEqual(built);
    const catalogue = buildFrameRecipe(document, share());
    expect(Object.keys(built ?? {}).sort()).toEqual(Object.keys(catalogue ?? {}).sort());
    expect(built).toMatchObject({
      recipeId: OWN_ID,
      difficulty: null,
      prepNote: null,
      prepMinutes: 0,
      cookMinutes: 40,
      photo: true,
    });
    expect(built?.ingredients).toEqual([
      { group: null, amount: '335 g', name: 'Mince', note: null },
      { group: null, amount: null, name: 'Salt', note: 'to taste' },
    ]);
    expect(built?.steps[0]?.timers).toHaveLength(1);
    expect(frameRecipePhotoPath(source)).toBe('h.jpg');
  });

  it('takes 30 lines and no photo', () => {
    const ingredients = Array.from({ length: 30 }, (_, at) => line(`Thing ${String(at)}`, null));
    const source = ownRecipeFrameDocument.parse(own({ ingredients, photo: null }));
    const built = buildFrameRecipe(source, {
      id: OWN_ID,
      people: 2,
      amounts: ingredients.map(() => null),
    });
    expect(built?.ingredients).toHaveLength(30);
    expect(built?.photo).toBe(false);
    expect(frameRecipePhotoPath(source)).toBeNull();
  });

  it('refuses anything that is not an own recipe', () => {
    expect(ownRecipeFrameDocument.safeParse(own({ source: 'ai' })).success).toBe(false);
    expect(ownRecipeFrameDocument.safeParse(own({ source: undefined })).success).toBe(false);
    expect(ownRecipeFrameDocument.safeParse(undefined).success).toBe(false);
  });
});
