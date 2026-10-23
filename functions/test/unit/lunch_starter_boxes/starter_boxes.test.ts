import { describe, expect, it } from 'vitest';

import { catalogueSource } from '../../../src/catalogue/publish_catalogue';
import { SEED_FOODS } from '../../../src/lunch_photos/seed_foods';
import {
  LUNCH_STARTER_BOXES,
  MAX_STARTER_BOXES,
  starterBoxSource,
  type StarterBoxSource,
} from '../../../src/lunch_starter_boxes/starter_box';
import {
  starterBoxDocument,
  type StarterBoxDocument,
} from '../../../src/lunch_starter_boxes/starter_box_document';
import { STARTER_BOXES } from '../../../src/lunch_starter_boxes/starter_boxes';
import { LUNCH_SLOTS } from '../../../src/plan_week/week_documents';
import { recipeCatalogue } from '../../../src/recipes/recipe_catalogue';
import { catalogueAllergens } from '../../../src/recipes/recipe_document';

/**
 * Lunch-box ADR-0018: a starter box names recipes and starter foods by id, and
 * what it shows — each compartment's name and allergen codes — is copied from
 * them, never typed twice. A box that names nothing real is never published.
 */

const recipes = recipeCatalogue();
const sources = { recipes, seedFoods: SEED_FOODS };
const published = STARTER_BOXES.map((box) => ({
  box,
  document: starterBoxDocument(starterBoxSource.parse(box), sources),
}));

function picksOf(
  document: StarterBoxDocument,
): [string, NonNullable<StarterBoxDocument['picks']['main']>][] {
  return LUNCH_SLOTS.flatMap((slot) => {
    const pick = document.picks[slot];
    return pick === undefined ? [] : [[slot, pick]];
  });
}

describe('the starter boxes', () => {
  it('are a handful, each with its own id and place in the list', () => {
    expect(STARTER_BOXES.length).toBeGreaterThanOrEqual(4);
    expect(STARTER_BOXES.length).toBeLessThanOrEqual(MAX_STARTER_BOXES);
    expect(new Set(STARTER_BOXES.map((box) => box.id)).size).toBe(STARTER_BOXES.length);
    expect(new Set(STARTER_BOXES.map((box) => box.order)).size).toBe(STARTER_BOXES.length);
  });

  it('every one resolves, and publishes beside the recipes', () => {
    const { entries } = catalogueSource();
    expect(entries[LUNCH_STARTER_BOXES]?.map((entry) => entry.id)).toEqual(
      STARTER_BOXES.map((box) => box.id),
    );
    expect(entries.recipes?.length).toBe(recipes.size);
  });

  it('copy each compartment’s name and allergen codes from the recipe or starter food it names', () => {
    for (const { box, document } of published) {
      for (const [slot, pick] of picksOf(document)) {
        const label = `${box.id}.${slot}`;
        if (pick.kind === 'recipe') {
          const recipe = recipes.get(pick.recipeId);
          expect(recipe, label).toBeDefined();
          if (recipe === undefined) continue;
          expect(recipe.placement.lunchBox, label).toBe(slot);
          expect(pick.name, label).toBe(recipe.name);
          expect(pick.allergens, label).toEqual(catalogueAllergens(recipe.allergens));
        } else {
          const food = SEED_FOODS[pick.seedKey];
          expect(food?.slot, label).toBe(slot);
          expect(pick.name, label).toBe(food?.name);
          expect(pick.allergens, label).toEqual(food?.allergens);
        }
      }
    }
  });

  it('all have a treat, for Fill the week to pack on a Friday', () => {
    for (const { box } of published) expect(box.picks.treat, box.id).toBeDefined();
  });

  it('include one a child with a nut or egg allergy can keep whole', () => {
    const friendly = published.filter(({ document }) =>
      picksOf(document).every(([, pick]) =>
        pick.allergens.every((code) => !['peanut', 'treeNut', 'egg'].includes(code)),
      ),
    );
    expect(friendly.map(({ box }) => box.id)).toContain('nut-egg-dairy-free');
  });

  it('need not fill every compartment', () => {
    const partial = published.find(({ box }) => box.id === 'dip-and-crunch');
    expect(Object.keys(partial?.document.picks ?? {}).sort()).toEqual([
      'fruit',
      'main',
      'snack',
      'treat',
    ]);
  });

  describe('a box that names nothing real is refused', () => {
    const box: StarterBoxSource = {
      id: 'test-box',
      name: 'Test box',
      blurb: 'For the tests.',
      order: 99,
      picks: { treat: { kind: 'recipe', recipeId: 'banana-oat-bites' } },
    };

    it('resolves a good one', () => {
      expect(starterBoxDocument(box, sources).picks.treat?.name).toBe('Banana oat bites');
    });

    it('refuses a recipe that does not exist', () => {
      const missing = { ...box, picks: { treat: { kind: 'recipe', recipeId: 'nope' } } } as const;
      expect(() => starterBoxDocument(missing, sources)).toThrow(/no recipe nope/);
    });

    it('refuses a recipe or a starter food placed in another compartment', () => {
      const wrongRecipe = {
        ...box,
        picks: { main: { kind: 'recipe', recipeId: 'banana-oat-bites' } },
      } as const;
      expect(() => starterBoxDocument(wrongRecipe, sources)).toThrow(/not placed in main/);
      const wrongFood = {
        ...box,
        picks: { treat: { kind: 'quickPick', seedKey: 'apple' } },
      } as const;
      expect(() => starterBoxDocument(wrongFood, sources)).toThrow(/apple is a fruit/);
    });

    it('refuses a starter food the catalogue does not have', () => {
      const unknown = { ...box, picks: { fruit: { kind: 'quickPick', seedKey: 'kiwi' } } } as const;
      expect(() => starterBoxDocument(unknown, sources)).toThrow(/no starter food kiwi/);
    });

    it('refuses a box with no compartments, or a compartment that is not one', () => {
      expect(starterBoxSource.safeParse({ ...box, picks: {} }).success).toBe(false);
      expect(
        starterBoxSource.safeParse({
          ...box,
          picks: { dessert: { kind: 'quickPick', seedKey: 'jelly' } },
        }).success,
      ).toBe(false);
    });
  });
});
