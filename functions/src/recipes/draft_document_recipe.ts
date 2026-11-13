import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { aiRuntime } from '../ai/ai_runtime';
import { addUsage, type GenerativeModel, type ModelUsage } from '../ai/generative_model';
import { spendAiCall } from '../ai/run_ai_call';
import {
  StructuredCallFailure,
  callForJson,
  realClock,
  type CallClock,
  type CallLimits,
  type StructuredReply,
} from '../ai/structured_call';
import { parseInput, requireUid } from '../household/parse_input';
import type { RecipeProposal } from './draft_recipe';
import { draftFrom } from './draft_recipe_reply';
import { OWN_RECIPE_LIMITS } from './own_recipe';
import { ownRecipeEditorIn } from './own_recipe_caller';
import { documentDraftRequest, photoBoxRequest } from './recipe_document_prompt';
import {
  documentDraftReply,
  photoBoxOf,
  photoBoxReply,
  type DocumentDraftReply,
  type DocumentPhoto,
  type PhotoBox,
} from './recipe_document_reply';
import {
  checkedPageImage,
  draftDocumentRecipeInput,
  type ReadPage,
} from './recipe_document_schemas';
import { db } from '../shared/firestore';

export interface DraftDocumentRecipeResult {
  readonly isRecipe: boolean;
  readonly recipe: RecipeProposal | null;
  readonly photo: DocumentPhoto | null;
  readonly callsLeft: number;
}

export interface DocumentDraftLimits {
  readonly draft: CallLimits;
  readonly box: CallLimits;
}

export const DOCUMENT_DRAFT_LIMITS: DocumentDraftLimits = {
  draft: { attempts: 2, perAttemptMs: 40_000, budgetMs: 60_000, backoffMs: [1_500] },
  box: { attempts: 1, perAttemptMs: 20_000, budgetMs: 20_000, backoffMs: [] },
};

export interface DocumentDraft {
  readonly reply: DocumentDraftReply;
  readonly photo: DocumentPhoto | null;
}

/**
 * Drafts one recipe of a PDF from pictures of its pages (recipes ADR-0009): one household call,
 * two model requests. The first reads the halves and picks a photo on a whole page; the second
 * boxes that photo tightly, alone at high resolution. Nothing is stored.
 */
export const draftDocumentRecipe = onCall(
  { timeoutSeconds: 120, memory: '512MiB' },
  async (request): Promise<DraftDocumentRecipeResult> => {
    const uid = requireUid(request.auth);
    const input = parseInput(draftDocumentRecipeInput, request.data);
    const store = db();
    const caller = await ownRecipeEditorIn(store, input.householdId, uid);
    const pages = input.pages.map(checkedPage);

    const deps = await aiRuntime(store);
    const result = await spendAiCall(
      deps,
      {
        feature: 'recipeImport',
        householdId: input.householdId,
        timeZone: caller.timeZone,
        uid,
      },
      deps.model.name,
      () => draftWithPhoto(deps.model, input.recipeName, pages),
    );
    const draft = draftFrom(result.value.reply);

    logger.info('document recipe drafted', {
      householdId: input.householdId,
      pages: pages.length,
      isRecipe: draft !== null,
      lines: draft?.ingredients.length ?? 0,
      steps: draft?.steps.length ?? 0,
      photo: result.value.photo !== null,
    });
    if (draft === null) {
      return { isRecipe: false, recipe: null, photo: null, callsLeft: result.callsLeft };
    }
    return {
      isRecipe: true,
      recipe: {
        ...draft,
        origin: 'document',
        sourceUrl: null,
        sourceName: Array.from(input.documentName).slice(0, OWN_RECIPE_LIMITS.sourceName).join(''),
      },
      photo: result.value.photo,
      callsLeft: result.callsLeft,
    };
  },
);

function checkedPage(page: ReadPage): ReadPage {
  return {
    number: page.number,
    top: checkedPageImage(page.top),
    bottom: checkedPageImage(page.bottom),
    whole: page.whole === null ? null : checkedPageImage(page.whole),
  };
}

export async function draftWithPhoto(
  model: GenerativeModel,
  recipeName: string,
  pages: readonly ReadPage[],
  limits: DocumentDraftLimits = DOCUMENT_DRAFT_LIMITS,
  clock: CallClock = realClock,
): Promise<StructuredReply<DocumentDraft>> {
  const drafted = await callForJson(
    model,
    documentDraftRequest(recipeName, pages),
    documentDraftReply,
    limits.draft,
    clock,
  );
  const reply = drafted.value;
  const chosen = pages.find(({ number }) => number === reply.photo?.page);
  const rough = photoBoxOf(reply.photo?.box);
  if (chosen?.whole == null || rough === null || !reply.isRecipe) {
    return { ...drafted, value: { reply, photo: null } };
  }
  const tight = await tightBox(model, recipeName, chosen.whole, limits.box, clock);
  return {
    ...drafted,
    value: { reply, photo: { page: chosen.number, box: tight.box ?? rough } },
    usage: addUsage(drafted.usage, tight.usage),
  };
}

async function tightBox(
  model: GenerativeModel,
  recipeName: string,
  whole: string,
  limits: CallLimits,
  clock: CallClock,
): Promise<{ readonly box: PhotoBox | null; readonly usage: ModelUsage }> {
  try {
    const boxed = await callForJson(
      model,
      photoBoxRequest(recipeName, whole),
      photoBoxReply,
      limits,
      clock,
    );
    return { box: photoBoxOf(boxed.value.box), usage: boxed.usage };
  } catch (error) {
    // The recipe is read; a box the model could not give only means the looser one is kept.
    if (!(error instanceof StructuredCallFailure)) throw error;
    return { box: null, usage: error.usage };
  }
}
