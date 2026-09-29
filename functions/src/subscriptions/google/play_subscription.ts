import { z } from 'zod';

import type { PurchaseState, PurchaseStatus } from '../purchase_state';

/**
 * Google's `SubscriptionPurchaseV2` — what `purchases.subscriptionsv2.get`
 * answers — with only the fields NestPrep reads (`ENG-09`). NestPrep sells
 * one base plan per subscription product, so the first line item is the
 * subscription.
 */
export const playSubscription = z.object({
  subscriptionState: z.string(),
  acknowledgementState: z.string().optional(),
  linkedPurchaseToken: z.string().optional(),
  testPurchase: z.looseObject({}).optional(),
  lineItems: z
    .array(
      z.object({
        productId: z.string().min(1),
        expiryTime: z.string().optional(),
        autoRenewingPlan: z.object({ autoRenewEnabled: z.boolean().optional() }).optional(),
      }),
    )
    .min(1),
});
export type PlaySubscription = z.infer<typeof playSubscription>;

const STATUS_BY_STATE: Readonly<Record<string, PurchaseStatus>> = {
  SUBSCRIPTION_STATE_ACTIVE: 'active',
  SUBSCRIPTION_STATE_CANCELED: 'cancelled',
  SUBSCRIPTION_STATE_IN_GRACE_PERIOD: 'inGracePeriod',
  SUBSCRIPTION_STATE_ON_HOLD: 'onHold',
  SUBSCRIPTION_STATE_PAUSED: 'paused',
  SUBSCRIPTION_STATE_PENDING: 'pending',
  SUBSCRIPTION_STATE_EXPIRED: 'expired',
  SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED: 'expired',
};

/**
 * One subscription as NestPrep understands it. A state Google adds later
 * reads as expired: giving premium for a state nobody has read about is the
 * direction that cannot be taken back.
 */
export function playState(subscription: PlaySubscription): PurchaseState {
  const line = subscription.lineItems[0];
  const expiry = line?.expiryTime === undefined ? null : new Date(line.expiryTime);
  const status = STATUS_BY_STATE[subscription.subscriptionState] ?? 'expired';
  const autoRenew = line?.autoRenewingPlan?.autoRenewEnabled;
  return {
    status,
    accessUntil: expiry !== null && !Number.isNaN(expiry.getTime()) ? expiry : null,
    willRenew: autoRenew ?? (status === 'active' ? true : null),
    productId: line?.productId ?? '',
    isTest: subscription.testPurchase !== undefined,
  };
}

export function needsAcknowledging(subscription: PlaySubscription): boolean {
  return subscription.acknowledgementState === 'ACKNOWLEDGEMENT_STATE_PENDING';
}
