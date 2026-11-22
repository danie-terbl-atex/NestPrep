import { z } from 'zod';

import { LIST_PHOTO_TYPES, MAX_BASE64_LENGTH } from '../list_scan/schemas';
import { PAGE_LINK_MAX } from '../shared/page_link';
import { MAX_REQUEST_BASE64 } from './recipe_document_schemas';

export const MAX_PAGE_CHARS = 60_000;
export const MAX_PAGE_IMAGES = 6;
export const MAX_SNAP_PHOTOS = 8;
export const MAX_SNAP_PARTS = 40;
/** Forty parts of this size still fit a callable's request. */
export const MAX_SNAP_PART_BYTES = 160 * 1024;
const MAX_SNAP_PART_BASE64 = Math.ceil(MAX_SNAP_PART_BYTES / 3) * 4;
const MAX_JSON_LD_BLOCKS = 10;
const MAX_TITLE_CHARS = 300;

const householdId = z.string().trim().min(1).max(64);

const page = z
  .object({
    url: z.string().max(PAGE_LINK_MAX),
    title: z.string().max(MAX_TITLE_CHARS).nullable(),
    jsonLd: z.array(z.string().min(1).max(MAX_PAGE_CHARS)).max(MAX_JSON_LD_BLOCKS),
    text: z.string().max(MAX_PAGE_CHARS),
    imageUrls: z.array(z.string().max(PAGE_LINK_MAX)).max(MAX_PAGE_IMAGES),
  })
  .refine((value) => pageChars(value) <= MAX_PAGE_CHARS, { message: 'too much of the page' })
  .refine((value) => value.jsonLd.length > 0 || value.text.trim() !== '', {
    message: 'nothing was read from the page',
  });
export type DraftPage = z.infer<typeof page>;

function pageChars(value: {
  readonly title: string | null;
  readonly jsonLd: readonly string[];
  readonly text: string;
}): number {
  return (
    (value.title?.length ?? 0) +
    value.text.length +
    value.jsonLd.reduce((total, block) => total + block.length, 0)
  );
}

const photo = z.object({
  mimeType: z.enum(LIST_PHOTO_TYPES),
  data: z.string().min(1).max(MAX_BASE64_LENGTH),
});

const snapPhoto = z.object({
  parts: z.array(z.string().min(1).max(MAX_SNAP_PART_BASE64)).min(1).max(MAX_SNAP_PARTS),
});
export type SnapPhoto = z.infer<typeof snapPhoto>;

const photos = z
  .array(snapPhoto)
  .min(1)
  .max(MAX_SNAP_PHOTOS)
  .refine((value) => partsOf(value).length <= MAX_SNAP_PARTS, { message: 'too many parts' })
  .refine(
    (value) => partsOf(value).reduce((total, part) => total + part.length, 0) <= MAX_REQUEST_BASE64,
    { message: 'too much of the photos' },
  );

function partsOf(value: readonly SnapPhoto[]): string[] {
  return value.flatMap(({ parts }) => parts);
}

/**
 * `photo` is one picture whole, which Vertex reads finely when it is alone: every snap from a
 * build up to 1.0.0+24, and one ordinary photo since. `photos` is anything more, cut into parts
 * (recipes ADR-0010).
 */
export const draftRecipeInput = z.union([
  z.object({ householdId, page }),
  z.object({ householdId, photos }),
  z.object({ householdId, photo }),
]);
export type DraftRecipeInput = z.infer<typeof draftRecipeInput>;
