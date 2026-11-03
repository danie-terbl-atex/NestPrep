import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

import type { ConversionTrigger } from '../product_analytics/conversion_ledger';

/**
 * Every way a subscriptions call can refuse (subscriptions ADR-0001).
 *
 * Same contract as the household and calendar refusals (BE-04): each carries
 * a `reason` the client maps to a sentence, and
 * `app/test/features/subscriptions/data/subscription_refusal_contract_test.dart`
 * reads this block. Membership refusals keep the household's names, because
 * that is what they are about. None of these messages reaches a person.
 */
export const SUBSCRIPTION_REFUSALS = {
  notAMember: ['permission-denied', 'You are not in this household.'],
  notAnAdmin: ['permission-denied', 'Only an admin can do that.'],
  householdNotFound: ['not-found', 'That household no longer exists.'],
  memberNotFound: ['not-found', 'That member no longer exists.'],
  // Buying is a family decision: a kid, helper or carer is not asked to pay.
  onlyFamilyCanBuy: ['permission-denied', 'Only a parent can buy premium.'],
  // The free tier's limit, reached. `feature` in the details says which.
  premiumRequired: ['failed-precondition', 'That needs premium.'],
  // No product ids configured, or not this store: nothing is on sale yet.
  premiumUnavailable: ['failed-precondition', 'Premium is not on sale yet.'],
  // The store's own server could not be asked. Worth trying again.
  storeUnreachable: ['unavailable', 'The store could not be reached.'],
  // A receipt that does not verify, or is not for one of our products.
  purchaseNotValid: ['invalid-argument', 'That purchase could not be verified.'],
  // The store subscription is already another household's premium.
  purchaseInUseElsewhere: ['already-exists', 'That subscription belongs to another household.'],
  // A child marked with no parent's consent on record and none given now
  // (accounts ADR-0005).
  guardianConsentRequired: ['failed-precondition', 'A parent has to consent first.'],
  voucherNotFound: ['not-found', 'That Premium is no longer waiting.'],
  notYourVoucher: ['permission-denied', 'That Premium was sent to a different email.'],
  voucherClaimed: ['already-exists', 'That Premium has already been added to a household.'],
  voucherVoid: ['failed-precondition', 'That Premium was cancelled.'],
  testVoucher: ['permission-denied', 'That Premium is from a test order.'],
  codeUsedUp: ['resource-exhausted', 'That code has been fully used.'],
  codeAlreadyUsed: ['already-exists', 'That code has already been used.'],
  codeNotEligible: ['failed-precondition', 'That code is for households new to Premium.'],
  codeYearlyLimit: [
    'failed-precondition',
    'This household has used a Premium code in the last year.',
  ],
  codeExpired: ['failed-precondition', 'That code has ended.'],
  codePaused: ['failed-precondition', "That code isn't available right now."],
  emailCodeWrong: ['invalid-argument', "That code doesn't match."],
  emailCodeExpired: ['deadline-exceeded', 'That code has expired.'],
  emailCodeTooManyTries: ['resource-exhausted', 'Too many tries. Ask for a new code.'],
  emailAlreadyVerified: ['already-exists', 'That email is already on your account.'],
  tooManyCodes: ['resource-exhausted', 'Too many codes sent. Try again later.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type SubscriptionRefusal = keyof typeof SUBSCRIPTION_REFUSALS;

/** The one place a subscriptions refusal becomes the error the client receives. */
export function refuseSubscription(
  reason: SubscriptionRefusal,
  details: Readonly<Record<string, string>> = {},
): HttpsError {
  const [code, message] = SUBSCRIPTION_REFUSALS[reason];
  return new HttpsError(code, message, { ...details, reason });
}

/**
 * The free tier's refusal, naming the premium feature that was reached for so
 * the paywall can open on it — and so a purchase that follows is counted
 * against it (product-analytics ADR-0001).
 */
export function premiumRequired(feature: ConversionTrigger): HttpsError {
  const [code, message] = SUBSCRIPTION_REFUSALS.premiumRequired;
  return new HttpsError(code, message, { reason: 'premiumRequired', feature });
}
