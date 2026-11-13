import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { householdRef } from '../household/documents';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { objectStore } from '../shared/storage';
import { refuseOwnRecipe } from './errors';
import { HOUSEHOLD_RECIPES } from './household_recipe';
import { OWN_SOURCE, deleteHouseholdRecipeInput, recipePhotoPrefix } from './own_recipe';
import { ownRecipeCallerIn } from './own_recipe_caller';

export interface DeleteHouseholdRecipeResult {
  readonly deleted: true;
}

export const deleteHouseholdRecipe = onCall(
  { timeoutSeconds: 30, memory: '256MiB' },
  async (request): Promise<DeleteHouseholdRecipeResult> => {
    const uid = requireUid(request.auth);
    const { householdId, recipeId } = parseInput(deleteHouseholdRecipeInput, request.data);
    const store = db();
    // No flag or premium: a lapsed household can still remove what it added.
    await ownRecipeCallerIn(store, householdId, uid);

    const home = householdRef(store, householdId);
    const ref = home.collection(HOUSEHOLD_RECIPES).doc(recipeId);
    const mealRef = home.collection('meals').doc(`recipe-${recipeId}`);
    await store.runTransaction(async (transaction) => {
      const [recipe, meal] = await Promise.all([transaction.get(ref), transaction.get(mealRef)]);
      if (recipe.exists && recipe.get('source') !== OWN_SOURCE) {
        throw refuseOwnRecipe('notOwnRecipe');
      }
      if (meal.exists && meal.get('householdRecipeId') === recipeId) {
        transaction.update(mealRef, { householdRecipeId: FieldValue.delete() });
      }
      if (recipe.exists) transaction.delete(ref);
    });
    await objectStore().deletePrefix(recipePhotoPrefix(householdId, recipeId));

    logger.info('household recipe deleted', { householdId });
    return { deleted: true };
  },
);
