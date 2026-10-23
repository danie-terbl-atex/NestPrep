import { hash } from 'node:crypto';

import { z } from 'zod';

import { ALLERGENS, type Allergen } from '../plan_week/food_safety';
import { INGREDIENT_UNITS, RECIPE_LIMITS, allergensOfRecipe } from '../plan_week/idea_recipe';

/**
 * A household's own recipe (recipes ADR-0002): at
 * `households/{householdId}/recipes/{recipeId}`, the catalogue's shape plus
 * who added it, written once by `saveLunchRecipes` and never changed. Its id
 * is its content, so saving it twice writes it once.
 */

export const HOUSEHOLD_RECIPES = 'recipes';
export const AI_SOURCE = 'ai';
/** A week's dishes saved by one *Use it*: a child's mains, and a few children. */
export const MAX_RECIPES_PER_SAVE = 6;

const text = (max: number): z.ZodString => z.string().trim().min(1).max(max);

/** One recipe as the phone sends it back from the ideas step (lunch-box ADR-0021 §5). */
export const householdRecipeInput = z.object({
  name: text(RECIPE_LIMITS.name),
  summary: z.string().trim().max(RECIPE_LIMITS.summary),
  ingredients: z
    .array(
      z.object({
        name: text(RECIPE_LIMITS.ingredientName),
        quantity: z.number().positive().max(RECIPE_LIMITS.maxQuantity).nullable(),
        unit: z.enum(INGREDIENT_UNITS).nullable(),
        /** What the phone searched the store with — read for codes, never stored (lunch-box ADR-0023). */
        searchTerm: z.string().trim().max(RECIPE_LIMITS.searchTerm).optional(),
      }),
    )
    .min(1)
    .max(RECIPE_LIMITS.maxIngredients),
  steps: z.array(text(RECIPE_LIMITS.step)).min(1).max(RECIPE_LIMITS.maxSteps),
  prepMinutes: z.number().int().min(1).max(RECIPE_LIMITS.maxPrepMinutes),
  prepAhead: z.boolean(),
  prepNote: z.string().trim().max(RECIPE_LIMITS.prepNote).nullable(),
  /** Codes the store's labels of the chosen products add — never fewer than the words name. */
  alsoContains: z.array(z.enum(ALLERGENS)).max(ALLERGENS.length).optional().default([]),
});
export type HouseholdRecipeInput = z.infer<typeof householdRecipeInput>;

export const saveLunchRecipesInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  recipes: z.array(householdRecipeInput).min(1).max(MAX_RECIPES_PER_SAVE),
});

/** What is stored, before `createdAt`; the content the id is made from comes first. */
export interface HouseholdRecipeContent {
  readonly name: string;
  readonly summary: string;
  readonly source: typeof AI_SOURCE;
  readonly contexts: readonly ['lunchBox'];
  readonly placement: { readonly lunchBox: 'main' };
  readonly allergens: readonly Allergen[];
  readonly dietTags: readonly string[];
  readonly ingredients: readonly {
    readonly name: string;
    readonly quantity: number | null;
    readonly unit: string | null;
    readonly note: null;
  }[];
  readonly steps: readonly string[];
  readonly servings: 1;
  readonly prepMinutes: number;
  readonly prepAhead: boolean;
  readonly prepNote: string | null;
}

/**
 * The stored recipe for [input]: one box's worth (`servings: 1`), a lunch
 * main, and allergen codes derived here from every word of it plus whatever
 * the store's labels add (ADR-0002 §4) — in family-profiles order.
 */
export function householdRecipeContent(input: HouseholdRecipeInput): HouseholdRecipeContent {
  const named = new Set<Allergen>([...allergensOfRecipe(input), ...input.alsoContains]);
  return {
    name: input.name,
    summary: input.summary,
    source: AI_SOURCE,
    contexts: ['lunchBox'],
    placement: { lunchBox: 'main' },
    allergens: ALLERGENS.filter((code) => named.has(code)),
    dietTags: [],
    ingredients: input.ingredients.map((line) => ({
      name: line.name,
      quantity: line.quantity,
      unit: line.unit,
      note: null,
    })),
    steps: input.steps,
    servings: 1,
    prepMinutes: input.prepMinutes,
    prepAhead: input.prepAhead,
    prepNote: input.prepNote === null || input.prepNote === '' ? null : input.prepNote,
  };
}

/** `ai-` and 20 hex digits of the content's SHA-256: the same recipe, the same id. */
export function householdRecipeId(content: HouseholdRecipeContent): string {
  return `ai-${hash('sha256', JSON.stringify(content)).slice(0, 20)}`;
}
