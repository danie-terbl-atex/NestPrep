import { z } from 'zod';

import { DIFFICULTIES } from '../recipes/recipe';
import { stepTimers } from './frame_recipe_timers';

export const FRAME_RECIPE_STATUSES = ['published', 'retired'] as const;
export const FRAME_AMOUNT_MAX = 24;
export const FRAME_AMOUNT_PATTERN = /^[0-9A-Za-z ./]*$/;

const RECIPE_ID = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const RECIPE_LINES_MAX = 30;
const PEOPLE_MAX = 24;

const frameAmount = z.string().trim().min(1).max(FRAME_AMOUNT_MAX).regex(FRAME_AMOUNT_PATTERN);

export const frameRecipeShareInput = z.object({
  id: z.string().max(60).regex(RECIPE_ID),
  people: z.number().int().min(1).max(PEOPLE_MAX),
  amounts: z.array(frameAmount.nullable()).max(RECIPE_LINES_MAX),
});
export type FrameRecipeShareInput = z.infer<typeof frameRecipeShareInput>;

export const frameRecipeDocument = z.object({
  status: z.enum(FRAME_RECIPE_STATUSES),
  name: z.string(),
  summary: z.string(),
  servings: z.number().int(),
  prepMinutes: z.number().int(),
  cookMinutes: z.number().int(),
  difficulty: z.enum(DIFFICULTIES),
  prepNote: z.string().nullable(),
  ingredients: z.array(
    z.object({
      name: z.string(),
      quantity: z.number().nullable(),
      note: z.string().nullable(),
      group: z.string().nullable(),
    }),
  ),
  steps: z.array(z.string()),
  photo: z.object({ hero: z.string().min(1) }).nullable(),
});
export type FrameRecipeDocument = z.infer<typeof frameRecipeDocument>;

const frameStepTimer = z.object({
  start: z.number().int().min(0),
  end: z.number().int().min(0),
  seconds: z.number().int(),
  upToSeconds: z.number().int().nullable(),
});

export const frameRecipe = z.object({
  recipeId: z.string(),
  name: z.string(),
  summary: z.string(),
  people: z.number().int(),
  servings: z.number().int(),
  prepMinutes: z.number().int(),
  cookMinutes: z.number().int(),
  difficulty: z.enum(DIFFICULTIES),
  photo: z.boolean(),
  prepNote: z.string().nullable(),
  ingredients: z.array(
    z.object({
      group: z.string().nullable(),
      amount: z.string().nullable(),
      name: z.string(),
      note: z.string().nullable(),
    }),
  ),
  steps: z.array(z.object({ text: z.string(), timers: z.array(frameStepTimer) })),
});
export type FrameRecipe = z.infer<typeof frameRecipe>;

export function buildFrameRecipe(
  recipe: FrameRecipeDocument,
  share: FrameRecipeShareInput,
): FrameRecipe | null {
  const { ingredients } = recipe;
  const { amounts } = share;
  if (amounts.length !== ingredients.length) return null;
  if (ingredients.some(({ quantity }, line) => (quantity === null) !== (amounts[line] === null))) {
    return null;
  }
  return {
    recipeId: share.id,
    name: recipe.name,
    summary: recipe.summary,
    people: share.people,
    servings: recipe.servings,
    prepMinutes: recipe.prepMinutes,
    cookMinutes: recipe.cookMinutes,
    difficulty: recipe.difficulty,
    photo: frameRecipePhotoPath(recipe) !== null,
    prepNote: recipe.prepNote,
    ingredients: ingredients.map(({ group, name, note }, line) => ({
      group,
      amount: amounts[line] ?? null,
      name,
      note,
    })),
    steps: recipe.steps.map((text) => ({ text, timers: stepTimers(text) })),
  };
}

export function frameRecipePhotoPath(recipe: FrameRecipeDocument): string | null {
  return recipe.photo?.hero ?? null;
}
