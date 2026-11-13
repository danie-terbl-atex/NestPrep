import { FieldValue, type Firestore, type Transaction } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { normalisedName } from '../home_care/restock_decision';
import { householdRef } from '../household/documents';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { pageLink } from '../shared/page_link';
import { objectStore, type ObjectStore } from '../shared/storage';
import { refuseOwnRecipe } from './errors';
import { HOUSEHOLD_RECIPES } from './household_recipe';
import {
  MAX_OWN_RECIPES,
  OWN_SOURCE,
  allergensOfOwnRecipe,
  ownRecipeContent,
  ownRecipePhoto,
  recipePhotoPrefix,
  saveHouseholdRecipeInput,
  type OwnRecipePhotoInput,
  type SaveHouseholdRecipeInput,
} from './own_recipe';
import { ownRecipeEditorIn } from './own_recipe_caller';

export interface SaveHouseholdRecipeResult {
  readonly id: string;
  readonly allergens: readonly string[];
  readonly created: boolean;
}

const TIDY_LOOKUP = 100;

export const saveHouseholdRecipe = onCall(
  { timeoutSeconds: 30, memory: '256MiB' },
  async (request): Promise<SaveHouseholdRecipeResult> => {
    const uid = requireUid(request.auth);
    const parsed = parseInput(saveHouseholdRecipeInput, request.data);
    const store = db();
    const { memberId } = await ownRecipeEditorIn(store, parsed.householdId, uid);
    const input = withPublicLinks(parsed);
    const objects = objectStore();
    const kept = photoPaths(input);
    await requireEveryPhoto(objects, kept);

    const created = await store.runTransaction((transaction) =>
      writeRecipe(store, transaction, input, memberId),
    );
    await tidyPhotos(objects, input, kept);

    logger.info('household recipe saved', {
      householdId: input.householdId,
      created,
      lines: input.ingredients.length,
      steps: input.steps.length,
      photos: kept.length / 2,
    });
    return { id: input.recipeId, allergens: allergensOfOwnRecipe(input), created };
  },
);

function withPublicLinks(input: SaveHouseholdRecipeInput): SaveHouseholdRecipeInput {
  return {
    ...input,
    sourceUrl: publicLink(input.sourceUrl),
    photo: input.photo === null ? null : withPublicLink(input.photo),
    gallery: input.gallery.map(withPublicLink),
  };
}

function withPublicLink(photo: OwnRecipePhotoInput): OwnRecipePhotoInput {
  return { ...photo, sourceUrl: publicLink(photo.sourceUrl) };
}

function publicLink(raw: string | null): string | null {
  if (raw === null) return null;
  const link = pageLink(raw);
  if (link === null) throw refuseOwnRecipe('sourceLinkNotPublic');
  return link;
}

function photoPaths(input: SaveHouseholdRecipeInput): string[] {
  const photos = [...(input.photo === null ? [] : [input.photo]), ...input.gallery];
  return photos.flatMap((photo) => {
    const { card, hero } = ownRecipePhoto(input.householdId, input.recipeId, photo);
    return [card, hero];
  });
}

async function requireEveryPhoto(objects: ObjectStore, paths: readonly string[]): Promise<void> {
  const found = await Promise.all(paths.map((path) => objects.exists(path)));
  if (found.includes(false)) throw refuseOwnRecipe('recipePhotoMissing');
}

async function writeRecipe(
  store: Firestore,
  transaction: Transaction,
  input: SaveHouseholdRecipeInput,
  memberId: string,
): Promise<boolean> {
  const home = householdRef(store, input.householdId);
  const recipes = home.collection(HOUSEHOLD_RECIPES);
  const ref = recipes.doc(input.recipeId);
  const mealRef = home.collection('meals').doc(`recipe-${input.recipeId}`);
  const [existing, meal] = await Promise.all([transaction.get(ref), transaction.get(mealRef)]);
  if (existing.exists && existing.get('source') !== OWN_SOURCE) {
    throw refuseOwnRecipe('notOwnRecipe');
  }
  if (!existing.exists) {
    // Inside the transaction, so two members adding the 300th at once can't both get through.
    const held = await transaction.get(recipes.where('source', '==', OWN_SOURCE).count());
    if (held.data().count >= MAX_OWN_RECIPES) throw refuseOwnRecipe('recipeLimitReached');
  }
  const content = { ...ownRecipeContent(input), updatedAt: FieldValue.serverTimestamp() };
  if (existing.exists) {
    transaction.update(ref, content);
  } else {
    transaction.create(ref, {
      ...content,
      addedBy: memberId,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  if (meal.exists && meal.get('householdRecipeId') === input.recipeId) {
    transaction.update(mealRef, { name: input.name, nameKey: normalisedName(input.name) });
  }
  return !existing.exists;
}

async function tidyPhotos(
  objects: ObjectStore,
  input: SaveHouseholdRecipeInput,
  kept: readonly string[],
): Promise<void> {
  try {
    const stored = await objects.list(
      recipePhotoPrefix(input.householdId, input.recipeId),
      TIDY_LOOKUP,
    );
    const stray = stored.map(({ name }) => name).filter((name) => !kept.includes(name));
    if (stray.length > 0) await objects.deleteObjects(stray);
  } catch (error) {
    // The recipe is saved, so this costs only stray files, which the next save removes.
    logger.warn('household recipe photos not tidied', {
      householdId: input.householdId,
      error: error instanceof Error ? error.name : 'unknown',
    });
  }
}
