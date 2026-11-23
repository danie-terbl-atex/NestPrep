import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import { readCatalogueRecipes } from '../../../src/recipes/catalogue_recipe_files';
import { recipeMealLines } from '../../../src/recipes/recipe_meal_lines';
import { amountText, recipeScale, startingPeopleFor } from '../../../src/recipes/recipe_scale';
import { frameRecipeDocument, ownRecipeFrameDocument } from '../../../src/frames/frame_recipe';

/**
 * The phone's scaler is the contract (photo-frames ADR-0024). After a change to
 * it, write the golden again from `app/` with
 * `flutter test tool/recipe_scale_golden_test.dart`.
 */

interface Golden {
  readonly people: number[];
  readonly familySizes: number[];
  readonly recipes: {
    readonly id: string;
    readonly household?: boolean;
    readonly document?: unknown;
    readonly startingPeople: Record<string, number>;
    readonly scaled: Record<
      string,
      {
        readonly amounts: (string | null)[];
        readonly mealLines: [string, number | null, string | null][];
      }
    >;
  }[];
}

const golden = JSON.parse(
  readFileSync(resolve(__dirname, '../../fixtures/recipe_scale_golden.json'), 'utf8'),
) as Golden;
const synthetic = golden.recipes.flatMap(({ id, household, document }) => {
  if (document === undefined) return [];
  const recipe =
    household === true
      ? ownRecipeFrameDocument.parse(document)
      : frameRecipeDocument.parse(document);
  return [{ ...recipe, id }];
});
const catalogue = readCatalogueRecipes();

describe('the server scaler, against the phone', () => {
  it('has a golden for every catalogue recipe', () => {
    expect(
      golden.recipes.filter(({ document }) => document === undefined).map(({ id }) => id),
    ).toEqual(catalogue.map(({ id }) => id));
    expect(synthetic.length).toBeGreaterThan(0);
  });

  for (const recipe of [...catalogue, ...synthetic]) {
    const expected = golden.recipes.find(({ id }) => id === recipe.id);

    it(`${recipe.id} starts at the people the phone starts at`, () => {
      for (const size of golden.familySizes) {
        expect(startingPeopleFor(recipe.contexts, recipe.servings, size)).toBe(
          expected?.startingPeople[String(size)],
        );
      }
    });

    it(`${recipe.id} reads and plans the same at every scale`, () => {
      for (const people of golden.people) {
        const scale = recipeScale(people, recipe.servings);
        const want = expected?.scaled[String(people)];
        expect(recipe.ingredients.map((line) => amountText(line, scale))).toEqual(want?.amounts);
        expect(
          recipeMealLines(recipe.ingredients, scale).map(({ name, amount, unit }) => [
            name,
            amount,
            unit,
          ]),
        ).toEqual(want?.mealLines);
      }
    });
  }
});
