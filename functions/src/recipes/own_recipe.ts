import { z } from 'zod';

import { allergensMentionedIn } from '../plan_week/allergen_words';
import { ALLERGENS, type Allergen } from '../plan_week/food_safety';
import { INGREDIENT_UNITS, allergensOfRecipe } from '../plan_week/idea_recipe';
import { PAGE_LINK_MAX } from '../shared/page_link';
import { COURSES } from './recipe';

export const OWN_SOURCE = 'own';
export const OWN_RECIPE_ID = /^own-[0-9a-f]{20}$/;
export const RECIPE_PHOTO_ID = /^[A-Za-z0-9_-]{8,64}$/;
export const MAX_OWN_RECIPES = 300;

export const OWN_RECIPE_LIMITS = {
  name: 60,
  summary: 200,
  ingredients: 30,
  ingredientName: 60,
  ingredientNote: 80,
  ingredientGroup: 40,
  quantity: 10_000,
  steps: 20,
  step: 400,
  notes: 2000,
  servings: 24,
  minutes: 1440,
  sourceName: 80,
  credit: 120,
  gallery: 5,
} as const;

export const OWN_RECIPE_CONTEXTS = ['breakfast', 'lunch', 'dinner'] as const;
export const OWN_RECIPE_ORIGINS = ['typed', 'link', 'photo', 'document'] as const;

const text = (max: number): z.ZodString => z.string().trim().min(1).max(max);
const optionalText = (max: number): z.ZodType<string | null, string | null> =>
  z
    .string()
    .trim()
    .max(max)
    .nullable()
    .transform((value) => (value === '' ? null : value));
const link = z.string().max(PAGE_LINK_MAX).nullable();
const minutes = z.number().int().min(0).max(OWN_RECIPE_LIMITS.minutes);

const photoInput = z.object({
  photoId: z.string().regex(RECIPE_PHOTO_ID),
  credit: optionalText(OWN_RECIPE_LIMITS.credit),
  sourceUrl: link,
});
export type OwnRecipePhotoInput = z.infer<typeof photoInput>;

const course = z.enum(COURSES);

export const saveHouseholdRecipeInput = z
  .object({
    householdId: z.string().trim().min(1).max(64),
    recipeId: z.string().regex(OWN_RECIPE_ID),
    name: text(OWN_RECIPE_LIMITS.name),
    summary: z.string().trim().max(OWN_RECIPE_LIMITS.summary),
    contexts: z.array(z.enum(OWN_RECIPE_CONTEXTS)).min(1).max(OWN_RECIPE_CONTEXTS.length),
    placement: z.object({ breakfast: course, lunch: course, dinner: course }).partial().strict(),
    ingredients: z
      .array(
        z.object({
          name: text(OWN_RECIPE_LIMITS.ingredientName),
          quantity: z.number().positive().max(OWN_RECIPE_LIMITS.quantity).nullable(),
          unit: z.enum(INGREDIENT_UNITS).nullable(),
          note: optionalText(OWN_RECIPE_LIMITS.ingredientNote),
          group: optionalText(OWN_RECIPE_LIMITS.ingredientGroup),
        }),
      )
      .min(1)
      .max(OWN_RECIPE_LIMITS.ingredients),
    steps: z.array(text(OWN_RECIPE_LIMITS.step)).min(1).max(OWN_RECIPE_LIMITS.steps),
    servings: z.number().int().min(1).max(OWN_RECIPE_LIMITS.servings),
    prepMinutes: minutes,
    cookMinutes: minutes,
    notes: optionalText(OWN_RECIPE_LIMITS.notes),
    origin: z.enum(OWN_RECIPE_ORIGINS),
    sourceUrl: link,
    sourceName: optionalText(OWN_RECIPE_LIMITS.sourceName),
    alsoContains: z.array(z.enum(ALLERGENS)).max(ALLERGENS.length),
    photo: photoInput.nullable(),
    gallery: z.array(photoInput).max(OWN_RECIPE_LIMITS.gallery),
  })
  .refine(
    ({ contexts, placement }) =>
      new Set(contexts).size === contexts.length &&
      Object.keys(placement).sort().join() === [...contexts].sort().join(),
    { message: 'placement must name exactly the recipe’s contexts', path: ['placement'] },
  )
  .refine(({ photo, gallery }) => photo !== null || gallery.length === 0, {
    message: 'a gallery needs a cover',
    path: ['gallery'],
  })
  .refine(
    ({ photo, gallery }) => {
      const ids = [...(photo === null ? [] : [photo]), ...gallery].map(({ photoId }) => photoId);
      return new Set(ids).size === ids.length;
    },
    { message: 'a photo is named twice', path: ['gallery'] },
  );
export type SaveHouseholdRecipeInput = z.infer<typeof saveHouseholdRecipeInput>;

export const deleteHouseholdRecipeInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  recipeId: z.string().regex(OWN_RECIPE_ID),
});

export function allergensOfOwnRecipe(
  recipe: Pick<
    SaveHouseholdRecipeInput,
    'name' | 'summary' | 'notes' | 'steps' | 'ingredients' | 'alsoContains'
  >,
): Allergen[] {
  const elsewhere = [
    recipe.notes ?? '',
    ...recipe.steps,
    ...recipe.ingredients.map(({ group }) => group ?? ''),
  ].join(' ');
  const named = new Set<Allergen>([
    ...allergensOfRecipe(recipe),
    ...allergensMentionedIn(elsewhere),
    ...recipe.alsoContains,
  ]);
  return ALLERGENS.filter((code) => named.has(code));
}

export function recipePhotoPrefix(householdId: string, recipeId: string): string {
  return `households/${householdId}/recipePhotos/${recipeId}/`;
}

export interface OwnRecipePhotoDocument {
  readonly card: string;
  readonly hero: string;
  readonly credit: string | null;
  readonly sourceUrl: string | null;
}

// Built here from a shape-checked id, because a frame streams any stored path.
export function ownRecipePhoto(
  householdId: string,
  recipeId: string,
  photo: OwnRecipePhotoInput,
): OwnRecipePhotoDocument {
  const prefix = recipePhotoPrefix(householdId, recipeId);
  return {
    card: `${prefix}${photo.photoId}-card.jpg`,
    hero: `${prefix}${photo.photoId}-hero.jpg`,
    credit: photo.credit,
    sourceUrl: photo.sourceUrl,
  };
}

export function ownRecipeContent(input: SaveHouseholdRecipeInput): Record<string, unknown> {
  const stored = (photo: OwnRecipePhotoInput): OwnRecipePhotoDocument =>
    ownRecipePhoto(input.householdId, input.recipeId, photo);
  return {
    name: input.name,
    summary: input.summary,
    source: OWN_SOURCE,
    contexts: input.contexts,
    placement: input.placement,
    allergens: allergensOfOwnRecipe(input),
    alsoContains: input.alsoContains,
    dietTags: [],
    kcalPerServing: null,
    ingredients: input.ingredients.map(({ name, quantity, unit, note, group }) => ({
      name,
      quantity,
      unit,
      note,
      group,
    })),
    steps: input.steps,
    servings: input.servings,
    prepMinutes: input.prepMinutes,
    cookMinutes: input.cookMinutes,
    notes: input.notes,
    origin: input.origin,
    sourceUrl: input.sourceUrl,
    sourceName: input.sourceName,
    photo: input.photo === null ? null : stored(input.photo),
    gallery: input.gallery.map(stored),
  };
}
