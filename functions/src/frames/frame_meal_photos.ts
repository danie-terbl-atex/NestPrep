import type { DocumentReference, Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { RECIPES } from '../recipes/recipe';
import { parsed } from './frame_documents';

/** A meal's picture is asked for by the household's meal id (`recipe-<recipeId>`), never a path. */

const mealShape = z.object({ name: z.string(), recipeId: z.string().min(1).optional() });

const recipePhotoShape = z.object({
  photo: z
    .object({ card: z.string().min(1).optional(), hero: z.string().min(1).optional() })
    .nullable()
    .catch(null),
});

export interface FrameMealRecords {
  readonly names: Readonly<Record<string, string>>;
  readonly photos: readonly string[];
}

export async function readFrameMeals(
  store: Firestore,
  home: DocumentReference,
  mealIds: readonly string[],
): Promise<FrameMealRecords> {
  const unique = [...new Set(mealIds)].filter((id) => id !== '');
  if (unique.length === 0) return { names: {}, photos: [] };
  const docs = await store.getAll(...unique.map((id) => home.collection('meals').doc(id)));
  const meals = docs.flatMap((doc) => {
    const meal = parsed(mealShape, doc.data());
    return meal === null ? [] : [{ id: doc.id, ...meal }];
  });
  const recipeIds = [...new Set(meals.flatMap(({ recipeId }) => recipeId ?? []))];
  const pictured = new Set(
    recipeIds.length === 0
      ? []
      : (await store.getAll(...recipeIds.map((id) => store.collection(RECIPES).doc(id))))
          .filter((doc) => recipePhotoPath(doc.data()) !== null)
          .map((doc) => doc.id),
  );
  return {
    names: Object.fromEntries(meals.map(({ id, name }) => [id, name])),
    photos: meals.flatMap(({ id, recipeId }) =>
      recipeId !== undefined && pictured.has(recipeId) ? [id] : [],
    ),
  };
}

export async function mealPhotoPath(
  store: Firestore,
  home: DocumentReference,
  mealId: string,
): Promise<string | null> {
  const meal = parsed(mealShape, (await home.collection('meals').doc(mealId).get()).data());
  if (meal?.recipeId === undefined) return null;
  const recipe = await store.collection(RECIPES).doc(meal.recipeId).get();
  return recipePhotoPath(recipe.data());
}

function recipePhotoPath(data: unknown): string | null {
  const photo = parsed(recipePhotoShape, data)?.photo;
  return photo?.card ?? photo?.hero ?? null;
}
