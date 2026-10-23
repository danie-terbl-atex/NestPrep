import { z } from 'zod';

/** The most grocery items one push carries, as for Checkers. */
export const MAX_PNP_ITEMS_PER_PUSH = 200;

/** The most packs of one item a push asks for (add-to-pnp ADR-0004). */
export const MAX_PACKS_PER_ITEM = 24;

/**
 * The Add to Pick n Pay inputs, parsed at the edge and never cast (ENG-09,
 * BE-03). `pnpLinkStatus`, `pnpStartLink` and `pnpUnlink` take no body.
 */
export const pnpCompleteLinkInput = z.object({
  code: z.string().trim().min(1).max(2048),
  state: z.string().trim().min(1).max(256),
});
export type PnpCompleteLinkInput = z.infer<typeof pnpCompleteLinkInput>;

/** A repeated item id is pushed once; packs are the member's ask, bounded. */
export const pnpPushToCartInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  itemIds: z
    .array(z.string().trim().min(1).max(128))
    .min(1)
    .max(MAX_PNP_ITEMS_PER_PUSH)
    .transform((ids) => [...new Set(ids)]),
  quantities: z
    .record(z.string().trim().min(1).max(128), z.number().int().min(1).max(MAX_PACKS_PER_ITEM))
    .optional(),
});
export type PnpPushToCartInput = z.infer<typeof pnpPushToCartInput>;
