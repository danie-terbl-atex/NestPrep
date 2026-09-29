import type { Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import type { AppleNotificationOutcome } from './apple/apple_verifier';
import { planOfProduct } from './offer';
import { recordPurchase } from './purchase_ledger';
import type { StoreVerifiers } from './store_verifiers';
import type { SubscriptionConfig } from './subscription_config';
import { PurchaseRejected, type VerifiedPurchase } from './verified_purchase';

/**
 * What the two stores tell NestPrep on their own — renewals, cancellations,
 * grace periods, holds, refunds — applied to the purchases on record
 * (subscriptions ADR-0001). The bodies of `appStoreNotifications` and
 * `playBillingNotifications`, apart from their transport (BE-01).
 *
 * A notification never links a purchase to a household: only a parent's
 * verified call does that. One about a subscription nobody has verified yet
 * is recorded unlinked, so the verification that follows finds it.
 */
export interface NotificationDeps {
  readonly store: Firestore;
  readonly config: SubscriptionConfig;
  readonly verifiers: StoreVerifiers;
  readonly now: () => Date;
}

/** What an App Store notification's HTTP answer should be. */
export type NotificationAnswer = 'accepted' | 'rejected';

/**
 * [outcome] is the verifier's reading of the signed payload, or a rejection
 * when it did not verify — Apple is told 400 then, and a forger learns
 * nothing more.
 */
export async function applyAppStoreNotification(
  deps: NotificationDeps,
  outcome: () => AppleNotificationOutcome,
): Promise<NotificationAnswer> {
  let read: AppleNotificationOutcome;
  try {
    read = outcome();
  } catch (error) {
    if (!(error instanceof PurchaseRejected)) throw error;
    logger.warn('app store notification rejected', { why: error.why });
    return 'rejected';
  }
  if (read.kind === 'ignored') {
    logger.info('app store notification ignored', { type: read.type });
    return 'accepted';
  }
  await applyToRecord(deps, read.purchase);
  logger.info('app store notification applied', { type: read.type });
  return 'accepted';
}

const playMessage = z.object({
  packageName: z.string(),
  subscriptionNotification: z
    .object({ notificationType: z.number().int(), purchaseToken: z.string().min(1) })
    .optional(),
  voidedPurchaseNotification: z
    .object({ purchaseToken: z.string().min(1), productType: z.number().int() })
    .optional(),
  testNotification: z.looseObject({}).optional(),
});

/** Google's voided-purchase product type for a subscription. */
const VOIDED_SUBSCRIPTION = 1;

/**
 * A Real-time Developer Notification. Google's carries only a token, so the
 * subscription is asked for again; a voided purchase — a refund, a
 * chargeback — takes premium away whatever the subscription says.
 */
export async function applyPlayNotification(
  deps: NotificationDeps,
  message: unknown,
): Promise<void> {
  const parsed = playMessage.safeParse(message);
  if (!parsed.success || parsed.data.packageName !== deps.config.androidPackage) {
    logger.warn('play notification not for this app');
    return;
  }
  const { subscriptionNotification, voidedPurchaseNotification } = parsed.data;
  const token =
    subscriptionNotification?.purchaseToken ??
    (voidedPurchaseNotification?.productType === VOIDED_SUBSCRIPTION
      ? voidedPurchaseNotification.purchaseToken
      : null);
  if (token === null) {
    logger.info('play notification ignored', {
      isTest: parsed.data.testNotification !== undefined,
    });
    return;
  }
  let purchase: VerifiedPurchase | null;
  try {
    purchase = await deps.verifiers.refresh('playStore', token, false);
  } catch (error) {
    if (!(error instanceof PurchaseRejected)) throw error;
    logger.warn('play notification for a token google does not know', { why: error.why });
    return;
  }
  if (purchase === null) return;
  const isVoided = voidedPurchaseNotification !== undefined;
  await applyToRecord(deps, isVoided ? revoked(purchase) : purchase);
  logger.info('play notification applied', {
    type: subscriptionNotification?.notificationType ?? 'voided',
  });
}

/** Records the store's word on a purchase of ours; one for another product is ignored. */
export async function applyToRecord(
  deps: NotificationDeps,
  purchase: VerifiedPurchase,
): Promise<void> {
  const plan = planOfProduct(deps.config, purchase.state.productId);
  if (plan === null) {
    logger.warn('store notification for a product that is not on sale', { store: purchase.store });
    return;
  }
  await recordPurchase(deps.store, { purchase, plan }, deps.now());
}

function revoked(purchase: VerifiedPurchase): VerifiedPurchase {
  return {
    ...purchase,
    state: { ...purchase.state, status: 'revoked', accessUntil: null, willRenew: false },
  };
}
