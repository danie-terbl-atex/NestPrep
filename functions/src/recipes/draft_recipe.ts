import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { aiRuntime } from '../ai/ai_runtime';
import type { ModelRequest } from '../ai/generative_model';
import { runAiCall } from '../ai/run_ai_call';
import { parseInput, requireUid } from '../household/parse_input';
import { checkedListPhoto } from '../list_scan/list_photo';
import { db } from '../shared/firestore';
import { pageLink } from '../shared/page_link';
import {
  draftFromPageRequest,
  draftFromPhotoRequest,
  draftFromPhotosRequest,
} from './draft_recipe_prompt';
import { draftFrom, draftReply, type RecipeDraft } from './draft_recipe_reply';
import {
  MAX_PAGE_IMAGES,
  draftRecipeInput,
  type DraftPage,
  type DraftRecipeInput,
  type SnapPhoto,
} from './draft_recipe_schemas';
import { refuseOwnRecipe } from './errors';
import { ownRecipeEditorIn } from './own_recipe_caller';

type DraftOrigin = 'link' | 'photo' | 'document';

export type RecipeProposal = RecipeDraft & {
  readonly origin: DraftOrigin;
  readonly sourceUrl: string | null;
  readonly sourceName: string | null;
};

export interface DraftRecipeResult {
  readonly isRecipe: boolean;
  readonly recipe: RecipeProposal | null;
  readonly imageUrls: readonly string[];
  readonly callsLeft: number;
}

interface DraftAsked {
  readonly origin: DraftOrigin;
  readonly sourceUrl: string | null;
  readonly sourceName: string | null;
  readonly imageUrls: readonly string[];
  readonly request: ModelRequest;
}

export const draftRecipe = onCall(
  { timeoutSeconds: 60, memory: '512MiB' },
  async (request): Promise<DraftRecipeResult> => {
    const uid = requireUid(request.auth);
    const input = parseInput(draftRecipeInput, request.data);
    const store = db();
    const caller = await ownRecipeEditorIn(store, input.householdId, uid);
    const asked = draftAsked(input);

    const result = await runAiCall(await aiRuntime(store), {
      feature: 'recipeImport',
      householdId: input.householdId,
      timeZone: caller.timeZone,
      uid,
      request: asked.request,
      schema: draftReply,
    });
    const draft = draftFrom(result.value);

    logger.info('recipe drafted', {
      householdId: input.householdId,
      origin: asked.origin,
      images: asked.request.parts.filter(({ kind }) => kind === 'inline').length,
      isRecipe: draft !== null,
      lines: draft?.ingredients.length ?? 0,
      steps: draft?.steps.length ?? 0,
    });
    if (draft === null) {
      return { isRecipe: false, recipe: null, imageUrls: [], callsLeft: result.callsLeft };
    }
    const { origin, sourceUrl, sourceName, imageUrls } = asked;
    return {
      isRecipe: true,
      recipe: { ...draft, origin, sourceUrl, sourceName },
      imageUrls,
      callsLeft: result.callsLeft,
    };
  },
);

export function draftAsked(input: DraftRecipeInput): DraftAsked {
  if ('page' in input) return pageAsked(input.page);
  if ('photos' in input) return photoAsked(draftFromPhotosRequest(input.photos.map(checkedSnap)));
  const { mimeType, data } = input.photo;
  return photoAsked(draftFromPhotoRequest(mimeType, checkedListPhoto(mimeType, data)));
}

function photoAsked(request: ModelRequest): DraftAsked {
  return { origin: 'photo', sourceUrl: null, sourceName: null, imageUrls: [], request };
}

function checkedSnap(photo: SnapPhoto): SnapPhoto {
  return { parts: photo.parts.map((part) => checkedListPhoto('image/jpeg', part)) };
}

function pageAsked(page: DraftPage): DraftAsked {
  const sourceUrl = pageLink(page.url);
  if (sourceUrl === null) throw refuseOwnRecipe('sourceLinkNotPublic');
  return {
    origin: 'link',
    sourceUrl,
    sourceName: siteNameOf(sourceUrl),
    imageUrls: publicImages(page.imageUrls),
    request: draftFromPageRequest(page),
  };
}

function siteNameOf(url: string): string {
  return new URL(url).hostname.replace(/^www\./, '');
}

function publicImages(urls: readonly string[]): string[] {
  const links = urls.flatMap((url) => pageLink(url) ?? []);
  return [...new Set(links)].slice(0, MAX_PAGE_IMAGES);
}
