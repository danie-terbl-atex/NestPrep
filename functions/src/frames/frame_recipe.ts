import { z } from 'zod';

import { OWN_SOURCE } from '../recipes/own_recipe';
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
  household: z.literal(true).optional(),
});
export type FrameRecipeShareInput = z.infer<typeof frameRecipeShareInput>;

const text = z.string().trim().min(1);
const textOrNull = z
  .unknown()
  .optional()
  .transform((value) => {
    const trimmed = typeof value === 'string' ? value.trim() : '';
    return trimmed === '' ? null : trimmed;
  });
const positiveOrNull = z
  .unknown()
  .optional()
  .transform((value) =>
    typeof value === 'number' && Number.isFinite(value) && value > 0 ? value : null,
  );

const frameRecipeFields = {
  name: text,
  summary: textOrNull.transform((summary) => summary ?? ''),
  servings: z.number().int().min(1).max(PEOPLE_MAX),
  prepMinutes: z.number().int().min(0),
  cookMinutes: z
    .unknown()
    .optional()
    .transform((minutes) =>
      Number.isInteger(minutes) && Number(minutes) > 0 ? Number(minutes) : 0,
    ),
  ingredients: z.array(
    z.object({
      name: text,
      quantity: positiveOrNull,
      unit: textOrNull,
      note: textOrNull,
      group: textOrNull,
    }),
  ),
  steps: z.array(text),
  photo: z
    .object({ hero: z.string().min(1) })
    .nullable()
    .catch(null),
  contexts: z
    .array(z.unknown())
    .catch([])
    .transform((contexts) => contexts.filter((context) => typeof context === 'string')),
};

export const frameRecipeDocument = z.object({
  status: z.enum(FRAME_RECIPE_STATUSES),
  ...frameRecipeFields,
  difficulty: z.enum(DIFFICULTIES).nullable().catch(null),
  prepNote: textOrNull,
});
export type FrameRecipeDocument = z.infer<typeof frameRecipeDocument>;

export type FrameRecipeSource = Omit<FrameRecipeDocument, 'status'>;

export const ownRecipeFrameDocument = z
  .object({ source: z.literal(OWN_SOURCE), ...frameRecipeFields })
  .transform((recipe): FrameRecipeSource => ({ ...recipe, difficulty: null, prepNote: null }));

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
  difficulty: z.enum(DIFFICULTIES).nullable(),
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
  recipe: FrameRecipeSource,
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

export function frameRecipePhotoPath(recipe: FrameRecipeSource): string | null {
  return recipe.photo?.hero ?? null;
}
