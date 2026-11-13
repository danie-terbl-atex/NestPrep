import { z } from 'zod';

import { refuseOwnRecipe } from './errors';

export const MAX_DOCUMENT_PAGES = 50;
export const MAX_RECIPE_PAGES = 12;
export const MAX_PHOTO_CHOICES = 8;
export const MAX_PAGE_IMAGE_BYTES = 400 * 1024;
const MAX_PAGE_IMAGE_BASE64 = Math.ceil(MAX_PAGE_IMAGE_BYTES / 3) * 4;
/** Under what a callable request may carry, with room for the rest of the body. */
export const MAX_REQUEST_BASE64 = 9_000_000;

const householdId = z.string().trim().min(1).max(64);
const documentName = z.string().trim().min(1).max(120);
const pageNumber = z.number().int().min(1).max(MAX_DOCUMENT_PAGES);
const pageImage = z.string().min(1).max(MAX_PAGE_IMAGE_BASE64);

function hasUniqueNumbers(pages: readonly { readonly number: number }[]): boolean {
  return new Set(pages.map(({ number }) => number)).size === pages.length;
}

function base64Length(images: readonly (string | null)[]): number {
  return images.reduce((total, image) => total + (image?.length ?? 0), 0);
}

const documentPage = z.object({ number: pageNumber, data: pageImage });
export type DocumentPage = z.infer<typeof documentPage>;

export const scanRecipeDocumentInput = z.object({
  householdId,
  documentName,
  pages: z
    .array(documentPage)
    .min(1)
    .max(MAX_DOCUMENT_PAGES)
    .refine(hasUniqueNumbers, { message: 'a page is sent twice' })
    .refine((pages) => base64Length(pages.map(({ data }) => data)) <= MAX_REQUEST_BASE64, {
      message: 'too much of the document',
    }),
});
export type ScanRecipeDocumentInput = z.infer<typeof scanRecipeDocumentInput>;

const readPage = z.object({
  number: pageNumber,
  top: pageImage,
  bottom: pageImage,
  whole: pageImage.nullable(),
});
export type ReadPage = z.infer<typeof readPage>;

export const draftDocumentRecipeInput = z.object({
  householdId,
  documentName,
  recipeName: z.string().trim().min(1).max(120),
  pages: z
    .array(readPage)
    .min(1)
    .max(MAX_RECIPE_PAGES)
    .refine(hasUniqueNumbers, { message: 'a page is sent twice' })
    .refine((pages) => pages.filter(({ whole }) => whole !== null).length <= MAX_PHOTO_CHOICES, {
      message: 'too many photo choices',
    })
    .refine(
      (pages) =>
        base64Length(pages.flatMap(({ top, bottom, whole }) => [top, bottom, whole])) <=
        MAX_REQUEST_BASE64,
      { message: 'too much of the document' },
    ),
});
export type DraftDocumentRecipeInput = z.infer<typeof draftDocumentRecipeInput>;

const BASE64 = /^[A-Za-z0-9+/]+={0,2}$/;
const JPEG = [0xff, 0xd8, 0xff];

/** A page picture is a JPEG the phone made; anything else is refused before a token is spent. */
export function checkedPageImage(data: string): string {
  if (!BASE64.test(data) || data.length % 4 !== 0) throw refuseOwnRecipe('documentPageUnreadable');
  const head = Buffer.from(data.slice(0, 8), 'base64');
  if (!JPEG.every((byte, index) => head[index] === byte)) {
    throw refuseOwnRecipe('documentPageUnreadable');
  }
  return data;
}
