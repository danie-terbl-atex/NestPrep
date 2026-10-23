import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { tierFrom } from '../ai/usage_rules';
import { householdRef } from '../household/documents';
import { refuse } from '../household/errors';
import { parseInput, requireUid } from '../household/parse_input';
import { refusePlanWeek } from '../plan_week/errors';
import { planCallerIn } from '../plan_week/plan_caller';
import { db } from '../shared/firestore';
import { readFlag } from '../shared/feature_flags';
import { premiumRequired } from '../subscriptions/errors';
import { entitlementRef } from '../subscriptions/subscription_documents';
import {
  HOUSEHOLD_RECIPES,
  householdRecipeContent,
  householdRecipeId,
  saveLunchRecipesInput,
  type HouseholdRecipeInput,
} from './household_recipe';

export interface SavedRecipe {
  readonly id: string;
  /** The codes the recipe carries — a lunch item linked to it must carry at least these. */
  readonly allergens: readonly string[];
}

export interface SaveLunchRecipesResult {
  /** In the order they were sent. */
  readonly recipes: readonly SavedRecipe[];
}

/**
 * Saves the dishes a parent is using from *Plan my week* as household
 * recipes (recipes ADR-0002, lunch-box ADR-0021 §5) and answers each one's id
 * and allergen codes, before the phone writes the lunch items that link to
 * them. Only this writes household recipes: their codes come from the word
 * lists here, which Security Rules cannot run.
 *
 * Who may: `lunch` at edit, premium, `planMyWeek` on — *Plan my week*'s own
 * door. No model is asked and nothing is charged. A recipe that exists is
 * left as it is, so a retried *Use it* writes nothing twice (BE-06).
 */
export const saveLunchRecipes = onCall(
  { timeoutSeconds: 30, memory: '256MiB' },
  async (request): Promise<SaveLunchRecipesResult> => {
    const uid = requireUid(request.auth);
    const input = parseInput(saveLunchRecipesInput, request.data);
    const store = db();
    const memberId = await openRecipeSaving(store, input.householdId, uid);

    const recipes = input.recipes.map((recipe) => recipeToSave(recipe));
    const created = await store.runTransaction(async (transaction) => {
      const refs = recipes.map(({ id }) =>
        householdRef(store, input.householdId).collection(HOUSEHOLD_RECIPES).doc(id),
      );
      const snapshots = await Promise.all(refs.map((ref) => transaction.get(ref)));
      let written = 0;
      const seen = new Set<string>();
      snapshots.forEach((snapshot, index) => {
        const recipe = recipes[index];
        if (snapshot.exists || recipe === undefined || seen.has(recipe.id)) return;
        seen.add(recipe.id);
        transaction.create(snapshot.ref, {
          ...recipe.content,
          addedBy: memberId,
          createdAt: FieldValue.serverTimestamp(),
        });
        written += 1;
      });
      return written;
    });

    // Counts only: never a dish, an ingredient or anybody's name (ENG-22).
    logger.info('lunch recipes saved', {
      householdId: input.householdId,
      sent: recipes.length,
      created,
    });
    return {
      recipes: recipes.map(({ id, content }) => ({ id, allergens: content.allergens })),
    };
  },
);

function recipeToSave(recipe: HouseholdRecipeInput): {
  id: string;
  content: ReturnType<typeof householdRecipeContent>;
} {
  const content = householdRecipeContent(recipe);
  return { id: householdRecipeId(content), content };
}

/** *Plan my week*'s door without the week: the switch, the grant, premium. */
async function openRecipeSaving(
  store: Firestore,
  householdId: string,
  uid: string,
): Promise<string> {
  if (!(await readFlag(store, 'planMyWeek'))) throw refusePlanWeek('planWeekOff');
  const caller = await planCallerIn(store, householdId, uid);
  if (caller.memberId === null) throw refuse('notAMember');
  const entitlement = await entitlementRef(store, householdId).get();
  if (tierFrom(entitlement.data(), new Date()) !== 'premium') throw premiumRequired('aiPlanning');
  return caller.memberId;
}
