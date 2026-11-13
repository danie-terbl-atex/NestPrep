import { z } from 'zod';

import { LIST_PHOTO_TYPES, MAX_BASE64_LENGTH } from '../list_scan/schemas';
import { PAGE_LINK_MAX } from '../shared/page_link';

export const MAX_PAGE_CHARS = 60_000;
export const MAX_PAGE_IMAGES = 6;
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

export const draftRecipeInput = z.union([
  z.object({ householdId, page }),
  z.object({ householdId, photo }),
]);
export type DraftRecipeInput = z.infer<typeof draftRecipeInput>;
