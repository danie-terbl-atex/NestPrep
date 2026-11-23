import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { aiRuntime } from '../ai/ai_runtime';
import {
  addUsage,
  type GenerativeModel,
  type ModelRequest,
  type ModelUsage,
} from '../ai/generative_model';
import { spendAiCall } from '../ai/run_ai_call';
import {
  DEFAULT_CALL_LIMITS,
  StructuredCallFailure,
  callForJson,
  realClock,
  type CallClock,
  type CallLimits,
  type StructuredReply,
} from '../ai/structured_call';
import { parseInput, requireUid } from '../household/parse_input';
import { checkedListPhoto } from '../list_scan/list_photo';
import { db } from '../shared/firestore';
import { pageLink } from '../shared/page_link';
import {
  draftFromPageRequest,
  draftFromPhotoRequest,
  draftFromPhotosRequest,
  snapPhotoBoxRequest,
} from './draft_recipe_prompt';
import {
  draftFrom,
  snapDraftReply,
  type RecipeDraft,
  type SnapDraftReply,
} from './draft_recipe_reply';
import {
  MAX_PAGE_IMAGES,
  draftRecipeInput,
  type DraftPage,
  type DraftRecipeInput,
  type SnapPhoto,
} from './draft_recipe_schemas';
import { refuseOwnRecipe } from './errors';
import { ownRecipeEditorIn } from './own_recipe_caller';
import { photoBoxOf, photoBoxReply, type PhotoBox } from './recipe_document_reply';

type DraftOrigin = 'link' | 'photo' | 'document';

export type RecipeProposal = RecipeDraft & {
  readonly origin: DraftOrigin;
  readonly sourceUrl: string | null;
  readonly sourceName: string | null;
};

/** Where on the snapped photos the dish is: on a part, or on the one photo sent whole (`part` null). */
export interface SnapDishPhoto {
  readonly photo: number;
  readonly part: number | null;
  readonly box: PhotoBox;
}

export interface DraftRecipeResult {
  readonly isRecipe: boolean;
  readonly recipe: RecipeProposal | null;
  readonly imageUrls: readonly string[];
  readonly photo: SnapDishPhoto | null;
  readonly callsLeft: number;
}

type DraftPictures =
  | { readonly kind: 'none' }
  | { readonly kind: 'whole' }
  | { readonly kind: 'parts'; readonly photos: readonly SnapPhoto[] };

export interface DraftAsked {
  readonly origin: DraftOrigin;
  readonly sourceUrl: string | null;
  readonly sourceName: string | null;
  readonly imageUrls: readonly string[];
  readonly request: ModelRequest;
  readonly pictures: DraftPictures;
}

export interface DraftLimits {
  readonly draft: CallLimits;
  readonly box: CallLimits;
}

export const DRAFT_LIMITS: DraftLimits = {
  draft: DEFAULT_CALL_LIMITS,
  box: { attempts: 1, perAttemptMs: 15_000, budgetMs: 15_000, backoffMs: [] },
};

export interface DraftRead {
  readonly reply: SnapDraftReply;
  readonly photo: SnapDishPhoto | null;
}

export const draftRecipe = onCall(
  { timeoutSeconds: 90, memory: '512MiB' },
  async (request): Promise<DraftRecipeResult> => {
    const uid = requireUid(request.auth);
    const input = parseInput(draftRecipeInput, request.data);
    const store = db();
    const caller = await ownRecipeEditorIn(store, input.householdId, uid);
    const asked = draftAsked(input);

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
      () => readDraft(deps.model, asked),
    );
    const draft = draftFrom(result.value.reply);

    logger.info('recipe drafted', {
      householdId: input.householdId,
      origin: asked.origin,
      images: asked.request.parts.filter(({ kind }) => kind === 'inline').length,
      isRecipe: draft !== null,
      lines: draft?.ingredients.length ?? 0,
      steps: draft?.steps.length ?? 0,
      photo: result.value.photo !== null,
    });
    if (draft === null) {
      return {
        isRecipe: false,
        recipe: null,
        imageUrls: [],
        photo: null,
        callsLeft: result.callsLeft,
      };
    }
    const { origin, sourceUrl, sourceName, imageUrls } = asked;
    return {
      isRecipe: true,
      recipe: { ...draft, origin, sourceUrl, sourceName },
      imageUrls,
      photo: result.value.photo,
      callsLeft: result.callsLeft,
    };
  },
);

/**
 * The draft, and for a snap the dish's photo (recipes ADR-0011). Among several pictures the model
 * picks the right one but places it badly, so a part is boxed again alone; a photo sent whole was
 * read alone already.
 */
export async function readDraft(
  model: GenerativeModel,
  asked: DraftAsked,
  limits: DraftLimits = DRAFT_LIMITS,
  clock: CallClock = realClock,
): Promise<StructuredReply<DraftRead>> {
  const drafted = await callForJson(model, asked.request, snapDraftReply, limits.draft, clock);
  const reply = drafted.value;
  const pick = reply.isRecipe ? pickOf(reply.photo, asked.pictures) : null;
  if (pick === null || asked.pictures.kind !== 'parts') {
    return { ...drafted, value: { reply, photo: pick } };
  }
  const part = asked.pictures.photos[pick.photo - 1]?.parts[(pick.part ?? 1) - 1] ?? '';
  const tight = await tightBox(model, reply.name?.trim() ?? '', part, limits.box, clock);
  return {
    ...drafted,
    value: { reply, photo: tight.box === null ? null : { ...pick, box: tight.box } },
    usage: addUsage(drafted.usage, tight.usage),
  };
}

function pickOf(raw: SnapDraftReply['photo'], pictures: DraftPictures): SnapDishPhoto | null {
  if (raw == null) return null;
  switch (pictures.kind) {
    case 'none':
      return null;
    case 'whole': {
      const box = photoBoxOf(raw.box);
      return raw.photo === 1 && box !== null ? { photo: 1, part: null, box } : null;
    }
    case 'parts': {
      const parts = pictures.photos[raw.photo - 1]?.parts.length ?? 0;
      const isPart = Number.isInteger(raw.part) && raw.part >= 1 && raw.part <= parts;
      return Number.isInteger(raw.photo) && isPart
        ? { photo: raw.photo, part: raw.part, box: [0, 0, 1000, 1000] }
        : null;
    }
  }
}

async function tightBox(
  model: GenerativeModel,
  recipeName: string,
  part: string,
  limits: CallLimits,
  clock: CallClock,
): Promise<{ readonly box: PhotoBox | null; readonly usage: ModelUsage }> {
  try {
    const boxed = await callForJson(
      model,
      snapPhotoBoxRequest(recipeName, part),
      photoBoxReply,
      limits,
      clock,
    );
    return { box: photoBoxOf(boxed.value.box), usage: boxed.usage };
  } catch (error) {
    // The recipe is read; a photo the model could not box is only a recipe without one.
    if (!(error instanceof StructuredCallFailure)) throw error;
    return { box: null, usage: error.usage };
  }
}

export function draftAsked(input: DraftRecipeInput): DraftAsked {
  if ('page' in input) return pageAsked(input.page);
  if ('photos' in input) {
    const photos = input.photos.map(checkedSnap);
    return photoAsked(draftFromPhotosRequest(photos), { kind: 'parts', photos });
  }
  const { mimeType, data } = input.photo;
  return photoAsked(draftFromPhotoRequest(mimeType, checkedListPhoto(mimeType, data)), {
    kind: 'whole',
  });
}

function photoAsked(request: ModelRequest, pictures: DraftPictures): DraftAsked {
  return { origin: 'photo', sourceUrl: null, sourceName: null, imageUrls: [], request, pictures };
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
    pictures: { kind: 'none' },
  };
}

function siteNameOf(url: string): string {
  return new URL(url).hostname.replace(/^www\./, '');
}

function publicImages(urls: readonly string[]): string[] {
  const links = urls.flatMap((url) => pageLink(url) ?? []);
  return [...new Set(links)].slice(0, MAX_PAGE_IMAGES);
}
