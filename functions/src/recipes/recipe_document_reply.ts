import { z } from 'zod';

import { draftReply } from './draft_recipe_reply';
import { OWN_RECIPE_LIMITS } from './own_recipe';
import { MAX_RECIPE_PAGES } from './recipe_document_schemas';

export const MAX_FOUND_RECIPES = 40;
const SUMMARY_LIMIT = 200;
/** Half a percent of the page: anything smaller is a stray box, not a photo. */
const MIN_PHOTO_AREA = 5_000;

const pageList = z.array(z.number()).nullish();

export const scanReply = z.object({
  recipes: z
    .array(
      z.object({
        name: z.string().nullish(),
        summary: z.string().nullish(),
        pages: pageList,
        usesPages: pageList,
      }),
    )
    .nullish(),
});
export type ScanReply = z.infer<typeof scanReply>;

export interface FoundRecipe {
  readonly name: string;
  readonly summary: string;
  readonly pages: readonly number[];
  readonly usesPages: readonly number[];
}

const photoReply = z.object({ page: z.number(), box: z.array(z.number()) }).nullish();

export const documentDraftReply = draftReply.extend({ photo: photoReply });
export type DocumentDraftReply = z.infer<typeof documentDraftReply>;

export const photoBoxReply = z.object({ box: z.array(z.number()).nullish() });

export type PhotoBox = readonly [number, number, number, number];

export interface DocumentPhoto {
  readonly page: number;
  readonly box: PhotoBox;
}

function clipped(value: string | null | undefined, max: number): string | null {
  const trimmed = value?.trim() ?? '';
  if (trimmed === '') return null;
  return Array.from(trimmed).slice(0, max).join('').trim();
}

function pagesIn(
  numbers: readonly number[] | null | undefined,
  sent: ReadonlySet<number>,
): number[] {
  return [...new Set((numbers ?? []).filter((page) => sent.has(page)))].sort((a, b) => a - b);
}

/**
 * Only pages the phone sent, each once; the recipe's own pages before the ones it builds on,
 * at most [MAX_RECIPE_PAGES] together, because a recipe is drafted from what is kept here.
 */
export function foundRecipesFrom(reply: ScanReply, sent: ReadonlySet<number>): FoundRecipe[] {
  return (reply.recipes ?? []).slice(0, MAX_FOUND_RECIPES).flatMap((recipe) => {
    const name = clipped(recipe.name, OWN_RECIPE_LIMITS.name);
    const own = pagesIn(recipe.pages, sent).slice(0, MAX_RECIPE_PAGES);
    if (name === null || own.length === 0) return [];
    const uses = pagesIn(recipe.usesPages, sent)
      .filter((page) => !own.includes(page))
      .slice(0, MAX_RECIPE_PAGES - own.length);
    return [
      {
        name,
        summary: clipped(recipe.summary, SUMMARY_LIMIT) ?? '',
        pages: own,
        usesPages: uses,
      },
    ];
  });
}

/** `[ymin, xmin, ymax, xmax]` on 0–1000, the way Gemini gives a box; null for anything else. */
export function photoBoxOf(raw: readonly number[] | null | undefined): PhotoBox | null {
  if (raw?.length !== 4) return null;
  const [top = 0, left = 0, bottom = 0, right = 0] = raw.map((edge) =>
    Math.min(1000, Math.max(0, Math.round(edge))),
  );
  if (bottom <= top || right <= left) return null;
  if ((bottom - top) * (right - left) < MIN_PHOTO_AREA) return null;
  return [top, left, bottom, right];
}
