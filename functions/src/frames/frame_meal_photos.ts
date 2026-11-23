import type { DocumentReference, Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { HOUSEHOLD_RECIPES } from '../recipes/household_recipe';
import { OWN_RECIPE_ID } from '../recipes/own_recipe';
import { RECIPES } from '../recipes/recipe';
import type { FrameRecipeLink } from './frame_day';
import { parsed } from './frame_documents';

/** A meal's picture is asked for by the household's meal id (`recipe-<recipeId>`), never a path. */

const mealShape = z.object({
  name: z.string(),
  recipeId: z.string().min(1).optional(),
  householdRecipeId: z.string().min(1).optional(),
});
type Meal = z.infer<typeof mealShape>;

const recipePhotoShape = z.object({
  photo: z
    .object({ card: z.string().min(1).optional(), hero: z.string().min(1).optional() })
    .nullable()
    .catch(null),
});

export interface FrameMealRecords {
  readonly names: Readonly<Record<string, string>>;
  readonly photos: readonly string[];
  readonly recipes: Readonly<Record<string, FrameRecipeLink>>;
}

export async function readFrameMeals(
  store: Firestore,
  home: DocumentReference,
  mealIds: readonly string[],
): Promise<FrameMealRecords> {
  const unique = [...new Set(mealIds)].filter((id) => id !== '');
  if (unique.length === 0) return { names: {}, photos: [], recipes: {} };
  const docs = await store.getAll(...unique.map((id) => home.collection('meals').doc(id)));
  const meals = docs.flatMap((doc) => {
    const meal = parsed(mealShape, doc.data());
    return meal === null ? [] : [{ id: doc.id, ...meal }];
  });
  const recipeRefs = meals.flatMap((meal) => recipeRefOf(store, home, meal) ?? []);
  const pictured = new Set(
    recipeRefs.length === 0
      ? []
      : (await store.getAll(...recipeRefs))
          .filter((doc) => recipePhotoPath(doc.data()) !== null)
          .map((doc) => doc.ref.path),
  );
  return {
    names: Object.fromEntries(meals.map(({ id, name }) => [id, name])),
    photos: meals.flatMap((meal) => {
      const path = recipeRefOf(store, home, meal)?.path;
      return path !== undefined && pictured.has(path) ? [meal.id] : [];
    }),
    recipes: Object.fromEntries(
      meals.flatMap((meal) => {
        const link = recipeLinkOf(meal);
        return link === null ? [] : [[meal.id, link] as const];
      }),
    ),
  };
}

function recipeLinkOf(meal: Meal): FrameRecipeLink | null {
  if (meal.recipeId !== undefined) return { id: meal.recipeId, household: false };
  if (meal.householdRecipeId === undefined || !OWN_RECIPE_ID.test(meal.householdRecipeId)) {
    return null;
  }
  return { id: meal.householdRecipeId, household: true };
}

function recipeRefOf(
  store: Firestore,
  home: DocumentReference,
  meal: Meal,
): DocumentReference | null {
  if (meal.recipeId !== undefined) return store.collection(RECIPES).doc(meal.recipeId);
  if (meal.householdRecipeId === undefined) return null;
  return home.collection(HOUSEHOLD_RECIPES).doc(meal.householdRecipeId);
}

export async function mealPhotoPath(
  store: Firestore,
  home: DocumentReference,
  mealId: string,
): Promise<string | null> {
  const meal = parsed(mealShape, (await home.collection('meals').doc(mealId).get()).data());
  const recipe = meal === null ? null : recipeRefOf(store, home, meal);
  return recipe === null ? null : recipePhotoPath((await recipe.get()).data());
}

export function recipePhotoPath(data: unknown): string | null {
  const photo = parsed(recipePhotoShape, data)?.photo;
  return photo?.card ?? photo?.hero ?? null;
}
