import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';
import { z } from 'zod';

import { CATALOGUE_DIR } from '../../../src/recipes/catalogue_recipe_files';
import type { Recipe } from '../../../src/recipes/recipe';
import { recipeCatalogue } from '../../../src/recipes/recipe_catalogue';

/**
 * Recipes ADR-0006: a recipe's `kcalPerServing` is the total of its
 * worksheet in `catalogue/nutrition/<id>.json` — one line per ingredient line,
 * in order, each with the grams and reference it was estimated from — over
 * its servings, to the nearest 10. A recipe whose lines change without its
 * worksheet fails here, so the number never drifts from the recipe.
 */

const NUTRITION_DIR = resolve(CATALOGUE_DIR, 'nutrition');
const recipes = [...recipeCatalogue().values()];

const grams = z.number().min(0);
const worksheetShape = z
  .object({
    id: z.string(),
    servings: z.number().int().positive(),
    lines: z.array(
      z.object({
        ingredient: z.string(),
        amount: z.string(),
        grams,
        kcal: z.number().int().min(0),
        proteinG: grams,
        fatG: grams,
        netCarbsG: grams,
        reference: z.string(),
      }),
    ),
    totalKcal: z.number().int().positive(),
    kcalPerServing: z.number().int().positive(),
    perServing: z.object({ proteinG: grams, fatG: grams, netCarbsG: grams }),
    notes: z.string(),
  })
  .strict();
type Worksheet = z.infer<typeof worksheetShape>;

function worksheet(recipe: Recipe): Worksheet {
  return worksheetShape.parse(
    JSON.parse(readFileSync(resolve(NUTRITION_DIR, `${recipe.id}.json`), 'utf8')),
  );
}

const nearestTen = (value: number): number => Math.round(value / 10) * 10;

describe('every recipe’s energy', () => {
  it('has a worksheet, and no worksheet is for a recipe that is not there', () => {
    const ids = new Set(recipes.map(({ id }) => id));
    for (const id of ids) expect(existsSync(resolve(NUTRITION_DIR, `${id}.json`)), id).toBe(true);
    const sheets = readdirSync(NUTRITION_DIR).filter((file) => file.endsWith('.json'));
    for (const file of sheets) expect(ids.has(file.replace(/\.json$/, '')), file).toBe(true);
  });

  it('estimates every ingredient line, in the recipe’s order', () => {
    for (const recipe of recipes) {
      const sheet = worksheet(recipe);
      expect(sheet.id, recipe.id).toBe(recipe.id);
      expect(sheet.servings, recipe.id).toBe(recipe.servings);
      expect(
        sheet.lines.map(({ ingredient }) => ingredient),
        recipe.id,
      ).toEqual(recipe.ingredients.map(({ name }) => name));
    }
  });

  it('is the worksheet’s total over the servings, to the nearest 10', () => {
    for (const recipe of recipes) {
      const sheet = worksheet(recipe);
      const total = sheet.lines.reduce((sum, { kcal }) => sum + kcal, 0);
      expect(sheet.totalKcal, recipe.id).toBe(total);
      expect(sheet.kcalPerServing, recipe.id).toBe(nearestTen(total / recipe.servings));
      expect(recipe.kcalPerServing, recipe.id).toBe(sheet.kcalPerServing);
    }
  });

  it('cites a reference for every line that has energy', () => {
    for (const recipe of recipes) {
      for (const line of worksheet(recipe).lines) {
        if (line.kcal > 0)
          expect(line.reference.trim(), `${recipe.id}: ${line.ingredient}`).not.toBe('');
      }
    }
  });
});

describe('a diet tag that needs the numbers', () => {
  it('holds banting to 25 g net carbs a serving, and keto to 10 g with most energy from fat', () => {
    for (const recipe of recipes) {
      const { perServing, kcalPerServing } = worksheet(recipe);
      if (recipe.dietTags.includes('banting')) {
        expect(perServing.netCarbsG, recipe.id).toBeLessThanOrEqual(25);
      }
      if (recipe.dietTags.includes('keto')) {
        expect(perServing.netCarbsG, recipe.id).toBeLessThanOrEqual(10);
        expect((9 * perServing.fatG) / kcalPerServing, recipe.id).toBeGreaterThanOrEqual(0.6);
      }
    }
  });
});
