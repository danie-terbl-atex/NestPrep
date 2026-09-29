import { onCall } from 'firebase-functions/v2/https';

import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { billingCallerIn } from './billing_caller';
import { offerFor } from './offer';
import { subscriptionOfferInput } from './schemas';
import { subscriptionConfig } from './subscription_config';

/**
 * What premium this household is offered: whether it is on sale at all, the
 * two store products, which one to show first, and the pricing-test cohort
 * (subscriptions ADR-0001). The prices are not here — the phone asks its own
 * store for them, in the family's own currency, so nothing in NestPrep ever
 * writes a price down (`ENG-20`).
 *
 * Answered to anybody in the household, so a helper who reaches a premium
 * feature is told what it is; buying is refused to them in `verifyPurchase`.
 */
export const getSubscriptionOffer = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(subscriptionOfferInput, request.data);
  const caller = await billingCallerIn(db(), input.householdId, uid);
  const offer = offerFor(subscriptionConfig(false), input.householdId);
  return { ...offer, canBuy: caller.isFamily };
});
