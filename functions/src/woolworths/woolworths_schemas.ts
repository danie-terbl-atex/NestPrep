import { z } from 'zod';

export const MAX_WOOLWORTHS_ITEMS_PER_PUSH = 200;
export const MAX_PACKS_PER_ITEM = 24;

export const woolworthsCompleteLinkInput = z.object({
  refreshToken: z.string().trim().min(1).max(8192),
});
export type WoolworthsCompleteLinkInput = z.infer<typeof woolworthsCompleteLinkInput>;

export const woolworthsPushToCartInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  itemIds: z
    .array(z.string().trim().min(1).max(128))
    .min(1)
    .max(MAX_WOOLWORTHS_ITEMS_PER_PUSH)
    .transform((ids) => [...new Set(ids)]),
  quantities: z
    .record(z.string().trim().min(1).max(128), z.number().int().min(1).max(MAX_PACKS_PER_ITEM))
    .optional(),
});
export type WoolworthsPushToCartInput = z.infer<typeof woolworthsPushToCartInput>;
