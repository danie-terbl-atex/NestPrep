import type { Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { recordPremiumConversion } from '../product_analytics/conversion_ledger';
import { settleReferralAfter } from '../referrals/referral_settlement';
import { billingCallerIn } from './billing_caller';
import type { Entitlement } from './entitlement';
import { refuseSubscription } from './errors';
import { cohortOf, planOfProduct } from './offer';
import { recordPurchase } from './purchase_ledger';
import { grantsPremiumAt } from './purchase_state';
import type { VerifyPurchaseInput } from './schemas';
import type { StoreVerifiers } from './store_verifiers';
import type { SubscriptionConfig } from './subscription_config';
import { purchaseKey } from './subscription_documents';
import { PurchaseRejected, StoreUnreachable, type VerifiedPurchase } from './verified_purchase';

/**
 * A purchase or a restore, from what the phone handed over to a household
 * with premium (subscriptions ADR-0001). The body of `verifyPurchase`, apart
 * from its transport, so every refusal is tested without HTTP (BE-01, BE-14).
 *
 * In order: the caller is family in the household; premium is on sale; the
 * store vouches for the purchase and it is one of our products; it is
 * recorded and linked in one transaction; and, for a purchase rather than a
 * restore, the conversion is counted once against what opened the paywall.
 */
export interface PurchaseVerificationDeps {
  readonly store: Firestore;
  readonly config: SubscriptionConfig;
  readonly verifiers: StoreVerifiers;
  readonly now: () => Date;
}

export interface VerificationResult {
  readonly isPremium: boolean;
  /** ISO-8601, or null when the purchase gives no premium now. */
  readonly premiumUntil: string | null;
}

export async function verifyAndLinkPurchase(
  deps: PurchaseVerificationDeps,
  uid: string,
  input: VerifyPurchaseInput,
): Promise<VerificationResult> {
  const caller = await billingCallerIn(deps.store, input.householdId, uid);
  if (!caller.isFamily) throw refuseSubscription('onlyFamilyCanBuy');
  if (deps.config.products === null) throw refuseSubscription('premiumUnavailable');

  const purchase = await verified(deps.verifiers, input);
  const plan = planOfProduct(deps.config, purchase.state.productId);
  if (plan === null) throw refuseSubscription('purchaseNotValid');

  const now = deps.now();
  const outcome = await recordPurchase(
    deps.store,
    {
      purchase,
      plan,
      link: {
        householdId: input.householdId,
        uid,
        memberId: caller.memberId,
        cohort: cohortOf(input.householdId, deps.config.isPricingTestOn),
      },
    },
    now,
  );
  const isNewSale = input.trigger !== null && grantsPremiumAt(purchase.state, now);
  if (isNewSale) {
    // Keyed by the store's own id, so a retried verification, a second
    // phone or a restore later never counts the same purchase twice.
    await recordPremiumConversion(deps.store, {
      householdId: input.householdId,
      conversionId: `${purchase.store}.${purchaseKey(purchase.store, purchase.storeRef)}`,
      trigger: input.trigger ?? 'direct',
      convertedAt: now,
    });
  }
  if (isNewSale && outcome.isFirstSighting) {
    // A first sale qualifies a household that joined through a referral —
    // never a restore, never a subscription seen before (subscriptions ADR-0002).
    await settleReferralAfter(deps.store, input.householdId, { kind: 'purchased' }, now);
  }
  logger.info('purchase verified', {
    householdId: input.householdId,
    store: purchase.store,
    status: purchase.state.status,
    isFirstSighting: outcome.isFirstSighting,
  });
  return resultOf(outcome.entitlement, now);
}

async function verified(
  verifiers: StoreVerifiers,
  input: VerifyPurchaseInput,
): Promise<VerifiedPurchase> {
  try {
    return await verifiers.verifyFromDevice(input.store, input.verificationData);
  } catch (error) {
    if (error instanceof PurchaseRejected) {
      logger.warn('purchase rejected', { store: input.store, why: error.why });
      throw refuseSubscription('purchaseNotValid');
    }
    if (error instanceof StoreUnreachable) {
      logger.warn('store unreachable', { store: input.store, why: error.why });
      throw refuseSubscription('storeUnreachable');
    }
    throw error;
  }
}

function resultOf(entitlement: Entitlement | null, now: Date): VerificationResult {
  const until = entitlement?.premiumUntil ?? null;
  const isPremium = until !== null && until.getTime() > now.getTime();
  return { isPremium, premiumUntil: isPremium ? until.toISOString() : null };
}
