import { z } from 'zod';

/** The most grocery items one push carries (the Checkers build contract). */
export const MAX_ITEMS_PER_PUSH = 200;

/** The most packs of one item a push asks for, as for Pick n Pay and Woolworths. */
export const MAX_PACKS_PER_ITEM = 24;

/**
 * The Add to Checkers inputs, parsed at the edge and never cast (ENG-09,
 * BE-03). The mobile number is only shape-checked here; `mobile_number.ts`
 * decides whether it is a South African mobile, so that refusal has its own
 * reason. `checkersLinkStatus` and `checkersUnlink` take no body.
 */
export const checkersRequestOtpInput = z.object({
  mobile: z.string().trim().min(1).max(32),
});
export type CheckersRequestOtpInput = z.infer<typeof checkersRequestOtpInput>;

export const checkersVerifyOtpInput = z.object({
  code: z
    .string()
    .trim()
    .regex(/^[0-9]{4,6}$/),
});
export type CheckersVerifyOtpInput = z.infer<typeof checkersVerifyOtpInput>;

/** A repeated item id is pushed once; packs are the member's ask, bounded. */
export const checkersPushToCartInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  itemIds: z
    .array(z.string().trim().min(1).max(128))
    .min(1)
    .max(MAX_ITEMS_PER_PUSH)
    .transform((ids) => [...new Set(ids)]),
  quantities: z
    .record(z.string().trim().min(1).max(128), z.number().int().min(1).max(MAX_PACKS_PER_ITEM))
    .optional(),
});
export type CheckersPushToCartInput = z.infer<typeof checkersPushToCartInput>;

export const MAX_RANKED_PRODUCTS = 8;

export const RANKED_SHOPS = ['checkers', 'pickNPay', 'woolworths'] as const;

export const rankProductMatchesInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  retailer: z.enum(RANKED_SHOPS).default('checkers'),
  item: z.string().trim().min(1).max(120),
  products: z
    .array(
      z.object({
        productId: z.string().trim().min(1).max(64),
        name: z.string().trim().min(1).max(160),
        brand: z.string().trim().max(60).nullable(),
        priceCents: z.number().int().min(0).max(500_000),
      }),
    )
    .min(1)
    .max(MAX_RANKED_PRODUCTS),
});
export type RankProductMatchesInput = z.infer<typeof rankProductMatchesInput>;
