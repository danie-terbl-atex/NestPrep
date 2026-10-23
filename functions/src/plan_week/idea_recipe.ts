import { z } from 'zod';

import { allergensMentionedIn } from './allergen_words';
import { ALLERGENS, type Allergen } from './food_safety';

/**
 * The dish a `main` idea is (lunch-box ADR-0021 §1): drafted in the same
 * model call as the idea, bounded here because Vertex refuses `maxItems`
 * (functions `CLAUDE.md`). A recipe that breaks a bound is dropped and its
 * idea stays a product idea — never half a recipe.
 */

/** The meal-planning unit codes (`IngredientUnit.code` in the app). */
export const INGREDIENT_UNITS = [
  'g',
  'kg',
  'ml',
  'l',
  'pack',
  'tin',
  'loaf',
  'bunch',
  'bottle',
  'tsp',
  'tbsp',
  'cup',
] as const;
export type IngredientUnit = (typeof INGREDIENT_UNITS)[number];

export const RECIPE_LIMITS = {
  name: 60,
  summary: 160,
  minIngredients: 2,
  maxIngredients: 8,
  ingredientName: 60,
  searchTerm: 40,
  maxQuantity: 1000,
  maxSteps: 6,
  step: 160,
  maxPrepMinutes: 90,
  prepNote: 140,
} as const;

const text = (max: number): z.ZodString => z.string().trim().min(1).max(max);

const recipeIngredient = z.object({
  name: text(RECIPE_LIMITS.ingredientName),
  quantity: z.number().positive().max(RECIPE_LIMITS.maxQuantity).nullable().optional(),
  unit: z.enum(INGREDIENT_UNITS).nullable().optional(),
  searchTerm: text(RECIPE_LIMITS.searchTerm),
});

const replyRecipe = z.object({
  name: text(RECIPE_LIMITS.name),
  summary: z.string().trim().max(RECIPE_LIMITS.summary).optional().default(''),
  ingredients: z
    .array(recipeIngredient)
    .min(RECIPE_LIMITS.minIngredients)
    .max(RECIPE_LIMITS.maxIngredients),
  steps: z.array(text(RECIPE_LIMITS.step)).min(1).max(RECIPE_LIMITS.maxSteps),
  prepMinutes: z.number().int().min(1).max(RECIPE_LIMITS.maxPrepMinutes),
  prepAhead: z.boolean().optional().default(false),
  prepNote: z.string().trim().max(RECIPE_LIMITS.prepNote).nullable().optional(),
});

export interface IdeaRecipeIngredient {
  readonly name: string;
  readonly quantity: number | null;
  readonly unit: IngredientUnit | null;
  readonly searchTerm: string;
}

/** A drafted dish as the phone gets it, with the codes its words name. */
export interface IdeaRecipe {
  readonly name: string;
  readonly summary: string;
  readonly ingredients: readonly IdeaRecipeIngredient[];
  readonly steps: readonly string[];
  readonly prepMinutes: number;
  readonly prepAhead: boolean;
  readonly prepNote: string | null;
  /** Derived here from every word of the dish, never the model's (BE-03). */
  readonly allergens: readonly Allergen[];
}

/** The recipe in [value], or null when there is none or it breaks a bound. */
export function ideaRecipeFrom(value: unknown): IdeaRecipe | null {
  const parsed = replyRecipe.safeParse(value);
  if (!parsed.success) return null;
  const recipe = parsed.data;
  const ingredients = recipe.ingredients.map((line) => ({
    name: line.name,
    quantity: line.quantity ?? null,
    unit: line.unit ?? null,
    searchTerm: line.searchTerm,
  }));
  const prepNote = recipe.prepNote === undefined || recipe.prepNote === '' ? null : recipe.prepNote;
  const draft = {
    name: recipe.name,
    summary: recipe.summary,
    ingredients,
    steps: recipe.steps,
    prepMinutes: recipe.prepMinutes,
    prepAhead: recipe.prepAhead,
    prepNote,
  };
  return { ...draft, allergens: allergensOfRecipe(draft) };
}

/** What a recipe's words are read from: its name, and each ingredient's name, note and search words. */
export interface RecipeWordsSource {
  readonly name: string;
  readonly ingredients: readonly {
    readonly name: string;
    readonly note?: string | null | undefined;
    readonly searchTerm?: string | null | undefined;
  }[];
}

/**
 * Every word a child's rules are read against: the dish and every
 * ingredient — its search words too, because they are what is bought
 * (lunch-box ADR-0023 §1).
 */
export function recipeWords(recipe: RecipeWordsSource): string {
  return [
    recipe.name,
    ...recipe.ingredients.flatMap((line) => [line.name, line.note ?? '', line.searchTerm ?? '']),
  ].join(' ');
}

/**
 * The allergen codes a recipe's words name — its name, summary and every
 * ingredient's name, note and search words — in family-profiles order
 * (recipes ADR-0001 §5, ADR-0002 §4, lunch-box ADR-0023 §1).
 */
export function allergensOfRecipe(
  recipe: RecipeWordsSource & { readonly summary: string },
): Allergen[] {
  const found = new Set(allergensMentionedIn(`${recipeWords(recipe)} ${recipe.summary}`));
  return ALLERGENS.filter((code) => found.has(code));
}
