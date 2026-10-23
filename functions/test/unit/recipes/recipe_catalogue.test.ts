import { existsSync, readdirSync } from 'node:fs';

import { describe, expect, it } from 'vitest';

import { allergensMentionedIn } from '../../../src/plan_week/allergen_words';
import { ALLERGENS } from '../../../src/plan_week/food_safety';
import { LUNCH_SLOTS } from '../../../src/plan_week/week_documents';
import {
  CATALOGUE_PHOTOS_DIR,
  readCatalogueRecipes,
} from '../../../src/recipes/catalogue_recipe_files';
import type { Recipe } from '../../../src/recipes/recipe';
import { recipeCatalogue } from '../../../src/recipes/recipe_catalogue';
import { readRecipePhotos } from '../../../src/recipes/recipe_photo_files';
import { MUFFIN } from './recipe_fixture';

/**
 * Recipes ADR-0001 and ADR-0003, over everything NestPrep publishes — the
 * lunch box's recipes in source and every meal recipe authors wrote under
 * `catalogue/recipes/`: a recipe carries the allergen codes its words name,
 * is placed in every context it names, and has its photo, or it is never
 * published.
 */

const recipes = [...recipeCatalogue().values()];
const written = readCatalogueRecipes();
const NO_MEAL_RECIPES =
  written.length === 0
    ? ' (skipped: catalogue/recipes/ holds no recipes yet — nothing to check)'
    : '';

/** Every allergen code the recipe's words name (ADR-0003 §8). */
function mentionedBy(recipe: Recipe): Set<string> {
  const texts = [
    recipe.name,
    recipe.summary,
    recipe.about ?? '',
    ...recipe.ingredients.flatMap(({ name, note }) => [name, note ?? '']),
  ];
  return new Set(texts.flatMap((text) => allergensMentionedIn(text)));
}

describe('the recipe catalogue', () => {
  it('holds lunch recipes for a main, a snack and a treat at least', () => {
    const slots = new Set(recipes.map((recipe) => recipe.placement.lunchBox));
    for (const slot of ['main', 'snack', 'treat']) expect(slots).toContain(slot);
  });

  it('places every lunch-box recipe in a real compartment', () => {
    for (const recipe of recipes.filter(({ contexts }) => contexts.includes('lunchBox'))) {
      expect(LUNCH_SLOTS, recipe.id).toContain(recipe.placement.lunchBox);
    }
  });

  it('declares every allergen its name, summary, about or any ingredient line mentions', () => {
    for (const recipe of recipes) {
      const missing = [...mentionedBy(recipe)].filter(
        (code) => !(recipe.allergens as readonly string[]).includes(code),
      );
      expect(missing, `${recipe.id} mentions but does not declare`).toEqual([]);
    }
  });

  it('would catch a recipe that hides an allergen in a note, or in what it says about itself', () => {
    const inANote = {
      ...MUFFIN,
      ingredients: [{ name: 'Sauce', quantity: null, unit: null, note: 'with cream', group: null }],
    };
    expect(mentionedBy(inANote)).toContain('milk');
    expect(mentionedBy({ ...MUFFIN, about: 'Grandma topped it with almonds.' })).toContain(
      'treeNut',
    );
    expect(mentionedBy({ ...MUFFIN, name: 'Butternut and nutmeg soup' })).not.toContain('milk');
  });

  it('lists allergen codes in the family-profiles order, so an unchanged recipe compares equal', () => {
    for (const recipe of recipes) {
      expect(recipe.allergens, recipe.id).toEqual(
        ALLERGENS.filter((code) => recipe.allergens.includes(code)),
      );
    }
  });

  it('refuses two recipes with one id, across the lunch box and the written catalogue', () => {
    expect(() => recipeCatalogue([MUFFIN, MUFFIN])).toThrow(/used twice/);
    expect(recipeCatalogue([MUFFIN]).get('test-muffin')?.name).toBe('Test muffin');
  });
});

describe(`the meal recipes authors wrote${NO_MEAL_RECIPES}`, () => {
  it.skipIf(written.length === 0)('are offered for meals, never the packed lunch box', () => {
    for (const recipe of written) expect(recipe.contexts, recipe.id).not.toContain('lunchBox');
  });

  it.skipIf(written.length === 0)('each carry one to four tags', () => {
    for (const recipe of written) {
      expect(recipe.tags.length, recipe.id).toBeGreaterThanOrEqual(1);
    }
  });

  it.skipIf(written.length === 0)('each have a photo, in both sizes, as a JPEG', () => {
    for (const recipe of written) {
      expect(recipe.photo, `${recipe.id} has no photo`).not.toBeNull();
      expect(() => readRecipePhotos(recipe.id), recipe.id).not.toThrow();
    }
  });

  it.skipIf(written.length === 0)('leave no photo folder without its recipe', () => {
    const ids = new Set(written.map(({ id }) => id));
    const folders = existsSync(CATALOGUE_PHOTOS_DIR)
      ? readdirSync(CATALOGUE_PHOTOS_DIR).filter((name) => !name.startsWith('.'))
      : [];
    expect(folders.filter((folder) => !ids.has(folder))).toEqual([]);
  });
});
