import { z } from 'zod';

import { CONVERSION_TRIGGERS } from '../product_analytics/conversion_ledger';
import { BILLING_STORES } from './purchase_state';

/**
 * Every subscriptions callable's input, parsed at the edge and never cast
 * (ENG-09, BE-03). Nothing the server can derive is here: who the caller is,
 * which plan a product is, what the store says about it. Not even the product
 * id — the store's answer names it, and a phone's word for it is not needed.
 */
const id = z.string().trim().min(1).max(64);

export const subscriptionOfferInput = z.object({ householdId: id });

export const verifyPurchaseInput = z.object({
  householdId: id,
  store: z.enum(BILLING_STORES),
  /**
   * What the store handed the phone: a Google purchase token, or Apple's
   * signed transaction (a JWS of a few kilobytes).
   */
  verificationData: z.string().trim().min(1).max(60_000),
  /**
   * What opened the paywall, for a purchase; null for a restore, which is
   * never counted as a conversion (product-analytics ADR-0001).
   */
  trigger: z.enum(CONVERSION_TRIGGERS).nullable(),
});
export type VerifyPurchaseInput = z.infer<typeof verifyPurchaseInput>;

export const setChildProfileInput = z.object({
  householdId: id,
  memberId: id,
  isChild: z.boolean(),
  // A parent's consent, given as they marked the child, against the privacy
  // policy's version (accounts ADR-0005). Who gave it is the caller.
  guardianConsent: z
    .object({ version: z.number().int().min(1).max(1000) })
    .strict()
    .optional(),
});
export type SetChildProfileInput = z.infer<typeof setChildProfileInput>;
