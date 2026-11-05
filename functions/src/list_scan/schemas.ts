import { z } from 'zod';

/** A shopping list arrives as a photo: the phone sends a JPEG, a screenshot may be a PNG. */
export const LIST_PHOTO_TYPES = ['image/jpeg', 'image/png'] as const;
export type ListPhotoType = (typeof LIST_PHOTO_TYPES)[number];

/** The largest photo read, in bytes — the school letter's limit, for the same reasons. */
export const MAX_LIST_PHOTO_BYTES = 4 * 1024 * 1024;

/**
 * Twice the photo limit in base64: between the two the photo is refused as
 * `listPhotoTooLarge`, which the app can put in words; past it, a bad request.
 */
const MAX_BASE64_LENGTH = Math.ceil(MAX_LIST_PHOTO_BYTES / 3) * 4 * 2;

/** Reading a shopping list, parsed at the edge (ENG-09, BE-03). The photo is never stored. */
export const readShoppingListInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  mimeType: z.enum(LIST_PHOTO_TYPES),
  data: z.string().min(1).max(MAX_BASE64_LENGTH),
});
export type ReadShoppingListInput = z.infer<typeof readShoppingListInput>;
