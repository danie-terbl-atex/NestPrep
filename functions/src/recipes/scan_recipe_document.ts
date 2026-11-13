import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { aiRuntime } from '../ai/ai_runtime';
import { runAiCall } from '../ai/run_ai_call';
import type { CallLimits } from '../ai/structured_call';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { ownRecipeEditorIn } from './own_recipe_caller';
import { scanRequest } from './recipe_document_prompt';
import { foundRecipesFrom, scanReply, type FoundRecipe } from './recipe_document_reply';
import { checkedPageImage, scanRecipeDocumentInput } from './recipe_document_schemas';

export interface ScanRecipeDocumentResult {
  readonly recipes: readonly FoundRecipe[];
  readonly callsLeft: number;
}

/** Fifty pages take a model longer than a page does; the callable allows two minutes. */
export const SCAN_CALL_LIMITS: CallLimits = {
  attempts: 2,
  perAttemptMs: 50_000,
  budgetMs: 70_000,
  backoffMs: [2_000],
};

/**
 * Lists the recipes in a PDF from pictures of its pages, which the phone made and sends once
 * (recipes ADR-0009). Nothing is stored: the pictures go to the model and are dropped.
 */
export const scanRecipeDocument = onCall(
  { timeoutSeconds: 120, memory: '512MiB' },
  async (request): Promise<ScanRecipeDocumentResult> => {
    const uid = requireUid(request.auth);
    const input = parseInput(scanRecipeDocumentInput, request.data);
    const store = db();
    const caller = await ownRecipeEditorIn(store, input.householdId, uid);
    const pages = input.pages.map((page) => ({ ...page, data: checkedPageImage(page.data) }));

    const result = await runAiCall(
      { ...(await aiRuntime(store)), limits: SCAN_CALL_LIMITS },
      {
        feature: 'recipeDocument',
        householdId: input.householdId,
        timeZone: caller.timeZone,
        uid,
        request: scanRequest(pages),
        schema: scanReply,
      },
    );
    const recipes = foundRecipesFrom(result.value, new Set(pages.map(({ number }) => number)));

    logger.info('recipe document scanned', {
      householdId: input.householdId,
      pages: pages.length,
      recipes: recipes.length,
    });
    return { recipes, callsLeft: result.callsLeft };
  },
);
