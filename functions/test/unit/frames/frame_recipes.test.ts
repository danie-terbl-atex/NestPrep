import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { catalogueSource } from '../../../src/catalogue/publish_catalogue';
import { type FrameDaySources, assembleFrameDay } from '../../../src/frames/frame_day';
import { refuseFrame } from '../../../src/frames/frame_errors';
import { assembleFrameMeals } from '../../../src/frames/frame_meal_week';
import {
  FRAME_CATALOGUE_RECIPE_LIMIT,
  FRAME_PLAN_MEAL_PER_CREDENTIAL,
  FRAME_RECIPE_PER_CREDENTIAL,
  FRAME_RECIPES_PER_CREDENTIAL,
} from '../../../src/frames/frame_policy';
import {
  frameRecipe,
  frameRecipeDocument,
  ownRecipeFrameDocument,
} from '../../../src/frames/frame_recipe';
import {
  type FrameRecipeEntry,
  frameRecipeAt,
  frameRecipeEntry,
  frameRecipeLink,
  frameRecipeListing,
  frameRecipeMeal,
  frameRecipesInOrder,
  frameRecipesVersion,
  frameRequestDocument,
  frameRequestId,
  inPlanReach,
  mealIdOf,
  mealsEditorsOf,
  planSlotKey,
  recipeOfPhotoId,
  recipesShown,
} from '../../../src/frames/frame_recipes';
import {
  type FramePanels,
  getFrameRecipeInput,
  getFrameRecipesInput,
  planFrameMealInput,
} from '../../../src/frames/frame_schemas';
import { ROLE_DEFAULTS } from '../../../src/household/access';
import { parseInput } from '../../../src/household/parse_input';
import type { MemberRecord, StoredHousehold } from '../../../src/notifications/recipients';
import { RECIPES } from '../../../src/recipes/recipe';
import { familySizeOf } from '../../../src/recipes/recipe_scale';

const SECRET = 'a'.repeat(43);
const OWN_ID = 'own-0123456789abcdef0123';

const PANELS: FramePanels = {
  calendar: false,
  todos: false,
  meals: true,
  lunch: false,
  addEvents: false,
  share: false,
  people: false,
  helperMemberId: null,
};

interface Golden {
  readonly recipes: {
    readonly id: string;
    readonly startingPeople: Record<string, number>;
    readonly scaled: Record<
      string,
      { amounts: (string | null)[]; mealLines: [string, number | null, string | null][] }
    >;
  }[];
}
const golden = JSON.parse(
  readFileSync(resolve(__dirname, '../../fixtures/recipe_scale_golden.json'), 'utf8'),
) as Golden;

function published(id: string): Record<string, unknown> {
  const entry = catalogueSource().entries[RECIPES]?.find((each) => each.id === id);
  if (entry === undefined) throw new Error(`the catalogue has no ${id}`);
  return { ...entry.fields, status: 'published', version: 1 };
}

const OWN = {
  source: 'own',
  name: 'Gran’s bobotie',
  summary: 'The one from the blue book.',
  contexts: ['dinner'],
  servings: 4,
  prepMinutes: 20,
  cookMinutes: 45,
  dietTags: [],
  ingredients: [
    { name: 'Beef mince', quantity: 500, unit: 'g', note: null, group: null },
    { name: 'Milk', quantity: 1, unit: 'cup', note: null, group: null },
    { name: 'Bay leaves', quantity: 3, unit: null, note: null, group: null },
    { name: 'Chutney', quantity: 2, unit: 'jar', note: null, group: null },
    { name: 'Salt', quantity: null, unit: null, note: 'to taste', group: null },
  ],
  steps: ['Brown the mince.', 'Bake for 45 minutes.'],
  photo: null,
};

describe('the gate', () => {
  it('is Premium and the Meals panel, both', () => {
    expect(recipesShown(PANELS, true)).toBe(true);
    expect(recipesShown(PANELS, false)).toBe(false);
    expect(recipesShown({ ...PANELS, meals: false }, true)).toBe(false);
  });

  it('refuses with its own reason', () => {
    expect(refuseFrame('recipesOff').code).toBe('failed-precondition');
    expect(refuseFrame('recipesOff').details).toEqual({ reason: 'recipesOff' });
  });

  it('lists the whole published catalogue', () => {
    expect(catalogueSource().entries[RECIPES]?.length ?? 0).toBeLessThanOrEqual(
      FRAME_CATALOGUE_RECIPE_LIMIT,
    );
  });

  it('has its limits', () => {
    expect(FRAME_RECIPES_PER_CREDENTIAL).toEqual({
      name: 'getFrameRecipes:credential',
      limit: 60,
      windowSeconds: 3600,
    });
    expect(FRAME_RECIPE_PER_CREDENTIAL).toEqual({
      name: 'getFrameRecipe:credential',
      limit: 120,
      windowSeconds: 3600,
    });
    expect(FRAME_PLAN_MEAL_PER_CREDENTIAL).toEqual({
      name: 'planFrameMeal:credential',
      limit: 60,
      windowSeconds: 3600,
    });
  });
});

describe('a recipe named by the frame', () => {
  it('is a catalogue slug or an own recipe’s id, each in its own place', () => {
    expect(frameRecipeLink('bunny-chow', false)).toEqual({ id: 'bunny-chow', household: false });
    expect(frameRecipeLink(OWN_ID, true)).toEqual({ id: OWN_ID, household: true });
    expect(frameRecipeLink(OWN_ID, false)).toBeNull();
    expect(frameRecipeLink('bunny-chow', true)).toBeNull();
    expect(frameRecipeLink('ai-0123456789abcdef0123', true)).toBeNull();
    expect(frameRecipeLink('Bunny Chow', false)).toBeNull();
  });

  it('and its photo by the meal id it would plan as', () => {
    expect(mealIdOf({ id: 'bunny-chow', household: false })).toBe('recipe-bunny-chow');
    expect(recipeOfPhotoId('recipe-bunny-chow')).toEqual({ id: 'bunny-chow', household: false });
    expect(recipeOfPhotoId(`recipe-${OWN_ID}`)).toEqual({ id: OWN_ID, household: true });
    expect(recipeOfPhotoId('recipe-own-nothex')).toBeNull();
    expect(recipeOfPhotoId('bunny-chow')).toBeNull();
    expect(recipeOfPhotoId('recipe-ai-0123456789abcdef0123')).toEqual({
      id: 'ai-0123456789abcdef0123',
      household: false,
    });
  });
});

describe('the list a frame browses', () => {
  const entryOf = (data: unknown, id: string, household: boolean): FrameRecipeEntry => {
    const listing = frameRecipeListing.parse(data);
    const link = frameRecipeLink(id, household);
    if (link === null) throw new Error(id);
    return frameRecipeEntry(link, listing);
  };

  it('is light: what a card shows, and no ingredients or steps', () => {
    const entry = entryOf(published('bunny-chow'), 'bunny-chow', false);
    expect(Object.keys(entry).sort()).toEqual(
      ['contexts', 'diet', 'household', 'id', 'minutes', 'name', 'photo', 'servings'].sort(),
    );
    expect(entry).toMatchObject({ id: 'bunny-chow', household: false, photo: true });
    expect(entry.minutes).toBeGreaterThan(0);
  });

  it('an own recipe with no photo and no time says so', () => {
    expect(
      entryOf(
        { ...OWN, prepMinutes: 0, cookMinutes: 0, contexts: ['dinner', 'brunch'] },
        OWN_ID,
        true,
      ),
    ).toEqual({
      id: OWN_ID,
      household: true,
      name: 'Gran’s bobotie',
      contexts: ['dinner'],
      servings: 4,
      photo: false,
      diet: [],
    });
  });

  it('is in name order, and its version moves only with what it shows', () => {
    const a = entryOf({ ...OWN, name: 'Apple crumble' }, OWN_ID, true);
    const b = entryOf(published('bunny-chow'), 'bunny-chow', false);
    const list = frameRecipesInOrder([b, a]);
    expect(list.map(({ name }) => name)).toEqual(['Apple crumble', b.name]);
    expect(frameRecipesVersion(list)).toBe(frameRecipesVersion(frameRecipesInOrder([a, b])));
    expect(frameRecipesVersion(list)).toMatch(/^[0-9a-f]{16}$/);
    expect(frameRecipesVersion([{ ...a, servings: 6 }, b])).not.toBe(frameRecipesVersion(list));
  });

  it('takes a version, or none', () => {
    expect(parseInput(getFrameRecipesInput, { secret: SECRET })).toEqual({
      secret: SECRET,
      version: null,
    });
    expect(parseInput(getFrameRecipesInput, { secret: SECRET, version: 'abc' }).version).toBe(
      'abc',
    );
    expect(() => parseInput(getFrameRecipesInput, { secret: 'x' })).toThrow(HttpsError);
  });
});

describe('a recipe a frame cooks', () => {
  const recipe = frameRecipeDocument.parse(published('bunny-chow'));
  const want = golden.recipes.find(({ id }) => id === 'bunny-chow');

  it('is scaled to the family exactly as the phone scales it', () => {
    const people = want?.startingPeople['5'] ?? 0;
    const built = frameRecipeAt({ id: 'bunny-chow', household: false }, recipe, 5);
    expect(built).not.toBeNull();
    expect(frameRecipe.parse(built)).toEqual(built);
    expect(built?.people).toBe(people);
    expect(built?.ingredients.map(({ amount }) => amount)).toEqual(
      want?.scaled[String(people)]?.amounts,
    );
  });

  it('is as written when the household has no family to count', () => {
    expect(frameRecipeAt({ id: 'bunny-chow', household: false }, recipe, 0)?.people).toBe(
      recipe.servings,
    );
  });

  it('an own recipe too, keeping a unit this build does not know', () => {
    const own = ownRecipeFrameDocument.parse(OWN);
    const built = frameRecipeAt({ id: OWN_ID, household: true }, own, 6);
    expect(built).toMatchObject({ recipeId: OWN_ID, people: 6, servings: 4, difficulty: null });
    expect(built?.ingredients.map(({ amount }) => amount)).toEqual([
      '750 g',
      '1 1/2 cups',
      '4 1/2',
      '3 jar',
      null,
    ]);
  });

  it('takes the recipe’s id and where it lives', () => {
    expect(parseInput(getFrameRecipeInput, { secret: SECRET, id: 'bunny-chow' })).toEqual({
      secret: SECRET,
      id: 'bunny-chow',
      household: false,
    });
    expect(
      parseInput(getFrameRecipeInput, { secret: SECRET, id: OWN_ID, household: true }).household,
    ).toBe(true);
    expect(() => parseInput(getFrameRecipeInput, { secret: SECRET, id: '../x' })).toThrow(
      HttpsError,
    );
  });
});

describe('a recipe read as leniently as the phone reads it', () => {
  const lean = {
    status: 'published',
    name: ' Pap ',
    servings: 4,
    prepMinutes: 5,
    ingredients: [
      { name: 'Maize meal', quantity: 2, unit: ' cup ' },
      { name: 'Water', quantity: 0, unit: 'l' },
      { name: 'Salt', quantity: 'a pinch' },
      { name: 'Butter', quantity: -1, unit: 'g', note: '  ', group: null },
    ],
    steps: ['Stir.'],
    contexts: ['breakfast', 7, null],
  };

  it('defaults what the phone defaults, and drops a bad amount rather than the recipe', () => {
    expect(frameRecipeDocument.parse(lean)).toEqual({
      status: 'published',
      name: 'Pap',
      summary: '',
      servings: 4,
      prepMinutes: 5,
      cookMinutes: 0,
      difficulty: null,
      prepNote: null,
      photo: null,
      contexts: ['breakfast'],
      ingredients: [
        { name: 'Maize meal', quantity: 2, unit: 'cup', note: null, group: null },
        { name: 'Water', quantity: null, unit: 'l', note: null, group: null },
        { name: 'Salt', quantity: null, unit: null, note: null, group: null },
        { name: 'Butter', quantity: null, unit: 'g', note: null, group: null },
      ],
      steps: ['Stir.'],
    });
  });

  it('shows a line with no usable amount without one, and the recipe still cooks', () => {
    const built = frameRecipeAt(
      { id: 'pap', household: false },
      frameRecipeDocument.parse(lean),
      4,
    );
    expect(built?.ingredients.map(({ amount }) => amount)).toEqual(['2 cups', null, null, null]);
  });

  it('is not a recipe without servings from 1 to 24, a name, steps, or a named line', () => {
    for (const servings of [0, -2, 25, 2.5, '4', undefined]) {
      expect(frameRecipeDocument.safeParse({ ...lean, servings }).success).toBe(false);
      expect(ownRecipeFrameDocument.safeParse({ ...OWN, servings }).success).toBe(false);
    }
    expect(frameRecipeDocument.safeParse({ ...lean, name: ' ' }).success).toBe(false);
    expect(frameRecipeDocument.safeParse({ ...lean, steps: ['Stir.', ''] }).success).toBe(false);
    expect(
      frameRecipeDocument.safeParse({
        ...lean,
        ingredients: [...lean.ingredients, { quantity: 1 }],
      }).success,
    ).toBe(false);
  });

  it('keeps an unknown difficulty and a missing photo from costing the recipe', () => {
    const read = frameRecipeDocument.parse({ ...lean, difficulty: 'heroic', photo: { card: 'x' } });
    expect([read.difficulty, read.photo]).toEqual([null, null]);
  });
});

describe('a recipe planned at the wall', () => {
  it('becomes the meal the app’s addRecipeMeal makes, with the plan’s own lines', () => {
    const recipe = frameRecipeDocument.parse(published('bunny-chow'));
    const want = golden.recipes.find(({ id }) => id === 'bunny-chow');
    const meal = frameRecipeMeal({ id: 'bunny-chow', household: false }, recipe, 'm-sam', 5);
    expect(Object.keys(meal).sort()).toEqual(
      ['addedBy', 'ingredients', 'name', 'nameKey', 'recipeId'].sort(),
    );
    expect(meal).toMatchObject({ addedBy: 'm-sam', recipeId: 'bunny-chow' });
    expect(meal.nameKey).toBe(meal.name.toLowerCase());
    expect(meal.ingredients.map(({ name, amount, unit }) => [name, amount, unit])).toEqual(
      want?.scaled[String(want.startingPeople['5'])]?.mealLines,
    );
  });

  it('an own recipe links by householdRecipeId, and a unit the plan does not use loses its amount', () => {
    const own = ownRecipeFrameDocument.parse(OWN);
    const meal = frameRecipeMeal({ id: OWN_ID, household: true }, own, 'm-pat', 4);
    expect(meal).toEqual({
      name: 'Gran’s bobotie',
      nameKey: 'gran’s bobotie',
      addedBy: 'm-pat',
      householdRecipeId: OWN_ID,
      ingredients: [
        { name: 'Beef mince', amount: 500, unit: 'g' },
        { name: 'Milk', amount: 1, unit: 'cup' },
        { name: 'Bay leaves', amount: 3, unit: null },
        { name: 'Chutney', amount: null, unit: null },
        { name: 'Salt', amount: null, unit: null },
      ],
    });
  });

  it('reaches this week and next on the household’s clock, and no further', () => {
    expect(inPlanReach('2026-11-23', '2026-11-25')).toBe(true);
    expect(inPlanReach('2026-12-06', '2026-11-25')).toBe(true);
    expect(inPlanReach('2026-12-07', '2026-11-25')).toBe(false);
    expect(inPlanReach('2026-11-22', '2026-11-25')).toBe(false);
    expect(inPlanReach('2027-01-03', '2026-12-28')).toBe(true);
  });

  it('fills the slot the app names, keyed by ISO weekday', () => {
    expect(planSlotKey('2026-11-23', 'breakfast')).toBe('1_breakfast');
    expect(planSlotKey('2026-11-29', 'dinner')).toBe('7_dinner');
  });

  it('marks the request once per frame, so a retry writes nothing', () => {
    expect(frameRequestId('f1', 'req-0001')).toBe('frame-f1-req-0001');
    const at = new Date('2026-11-24T00:00:00Z');
    expect(frameRequestDocument('f1', at)).toEqual({
      frameId: 'f1',
      kind: 'planMeal',
      at: FieldValue.serverTimestamp(),
      expiresAt: at,
    });
  });

  it('takes a recipe, or null to clear, with a request id', () => {
    const body = {
      secret: SECRET,
      requestId: 'req-0001',
      id: 'bunny-chow',
      date: '2026-11-24',
      slot: 'dinner',
    };
    expect(parseInput(planFrameMealInput, body)).toEqual({ ...body, household: false, by: null });
    expect(parseInput(planFrameMealInput, { ...body, id: null, by: 'Sam' })).toMatchObject({
      id: null,
      by: 'Sam',
    });
    for (const bad of [
      { ...body, requestId: undefined },
      { ...body, id: undefined },
      { ...body, slot: 'snack' },
      { ...body, date: '2026-02-30' },
      { ...body, requestId: 'short' },
    ]) {
      expect(() => parseInput(planFrameMealInput, bad)).toThrow(HttpsError);
    }
  });
});

describe('who may plan', () => {
  const household: StoredHousehold = {
    timeZone: 'Africa/Johannesburg',
    members: { 'uid-sam': 'admin', 'uid-pat': 'parent', 'uid-thandi': 'helper' },
    access: { 'uid-thandi': ROLE_DEFAULTS.helper },
    kids: { 'tablet-mia': 'm-mia' },
  };
  const members: MemberRecord[] = [
    { id: 'm-sam', displayName: 'Sam', role: 'admin', claimedBy: 'uid-sam' },
    { id: 'm-pat', displayName: 'Pat', role: 'parent', claimedBy: 'uid-pat' },
    { id: 'm-thandi', displayName: 'Thandi', role: 'helper', claimedBy: 'uid-thandi' },
    { id: 'm-mia', displayName: 'Mia', role: 'kid', claimedBy: null },
    { id: 'm-gran', displayName: 'Gran', role: 'parent', claimedBy: null },
  ];

  it('a meals editor who signs in as the profile', () => {
    expect(mealsEditorsOf(household, members)).toEqual(['m-sam', 'm-pat']);
  });

  it('and the family a meal is counted for is its parents and children', () => {
    expect(familySizeOf(members.map(({ role }) => role))).toBe(4);
    expect(familySizeOf(['member', 'carer', 'helper'])).toBe(1);
  });
});

describe('the day and the week a frame shows', () => {
  const sources = (more: Partial<FrameDaySources>): FrameDaySources => ({
    householdName: 'The Parkers',
    frameName: 'Kitchen',
    panels: PANELS,
    screensaver: null,
    today: '2026-11-24',
    localMinute: 9 * 60,
    names: { 'm-sam': 'Sam Parker', 'm-pat': 'Pat', 'm-gone': '' },
    colors: {},
    ...more,
  });
  const meals = {
    slots: {
      '2_dinner': 'recipe-bunny-chow',
      '2_lunch': 'toasties',
      '2_breakfast': `recipe-${OWN_ID}`,
    },
    mealNames: {
      'recipe-bunny-chow': 'Bunny chow',
      toasties: 'Toasties',
      [`recipe-${OWN_ID}`]: 'Oats',
    },
    photos: ['recipe-bunny-chow'],
    recipes: {
      'recipe-bunny-chow': { id: 'bunny-chow', household: false },
      [`recipe-${OWN_ID}`]: { id: OWN_ID, household: true },
    },
  };

  it('names who may plan, by first name, while recipes are shown', () => {
    const day = assembleFrameDay(sources({ planners: ['m-sam', 'm-pat', 'm-gone'] }));
    expect(day.recipes).toEqual({ planners: ['Pat', 'Sam'] });
    expect(assembleFrameDay(sources({}))).not.toHaveProperty('recipes');
    expect(
      assembleFrameDay(sources({ panels: { ...PANELS, meals: false }, planners: ['m-sam'] })),
    ).not.toHaveProperty('recipes');
  });

  it('links a planned meal to its recipe, with or without a photo', () => {
    expect(assembleFrameDay(sources({ meals })).meals).toEqual({
      slots: [
        { slot: 'breakfast', title: 'Oats', recipe: { id: OWN_ID, household: true } },
        { slot: 'lunch', title: 'Toasties' },
        {
          slot: 'dinner',
          title: 'Bunny chow',
          photo: 'recipe-bunny-chow',
          recipe: { id: 'bunny-chow', household: false },
        },
      ],
    });
    const unlinked = { slots: meals.slots, mealNames: meals.mealNames, photos: meals.photos };
    expect(assembleFrameDay(sources({ meals: unlinked })).meals?.slots[2]).toEqual({
      slot: 'dinner',
      title: 'Bunny chow',
      photo: 'recipe-bunny-chow',
    });
  });

  it('and the week does the same', () => {
    const week = assembleFrameMeals({ today: '2026-11-24', week: '2026-11-23', meals });
    expect(week.days[1]?.slots[2]).toEqual({
      slot: 'dinner',
      title: 'Bunny chow',
      photo: 'recipe-bunny-chow',
      recipe: { id: 'bunny-chow', household: false },
    });
  });
});
