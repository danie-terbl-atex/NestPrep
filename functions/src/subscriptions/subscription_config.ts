import { defineSecret, defineString } from 'firebase-functions/params';

import { configured } from '../shared/configured_value';
import type { Plan } from './purchase_state';

/**
 * Subscriptions' configuration, by name (BE-16, ENG-18; subscriptions
 * ADR-0001). None of it has a value in the repo or the vault: the store
 * products, the Play access and the App Store key are Daniel's to create.
 * Until the product ids are set, premium says **isn't available yet** rather
 * than failing.
 *
 * - `SUBSCRIPTIONS_MONTHLY_PRODUCT_ID`, `SUBSCRIPTIONS_YEARLY_PRODUCT_ID` —
 *   the product id of each plan, the same string in both stores.
 * - `SUBSCRIPTIONS_PRICING_TEST` — `on` splits households into two cohorts
 *   for the monthly-versus-yearly test; anything else puts everybody in `a`.
 * - `SUBSCRIPTIONS_TEST_MONTHLY_PRODUCT_ID`, `SUBSCRIPTIONS_TEST_YEARLY_PRODUCT_ID`
 *   — optional: cohort `b`'s own products, when the test is of a price point
 *   too. Empty means cohort `b` is offered cohort `a`'s products.
 * - `SUBSCRIPTIONS_ANDROID_PACKAGE`, `SUBSCRIPTIONS_IOS_BUNDLE_ID` — the app's
 *   identifiers, defaulted to the app's own.
 * - `SUBSCRIPTIONS_APPLE_APP_ID` — the numeric Apple ID of the app, which a
 *   production signed transaction carries and is checked against.
 * - `SUBSCRIPTIONS_APPLE_ISSUER_ID`, `SUBSCRIPTIONS_APPLE_KEY_ID` and the secret
 *   `SUBSCRIPTIONS_APPLE_PRIVATE_KEY` — the App Store Server API key. Optional:
 *   without it a signed transaction is still verified, but renewal status is
 *   learned from notifications rather than asked for.
 */
export const monthlyProductId = defineString('SUBSCRIPTIONS_MONTHLY_PRODUCT_ID', { default: '' });
export const yearlyProductId = defineString('SUBSCRIPTIONS_YEARLY_PRODUCT_ID', { default: '' });
export const pricingTest = defineString('SUBSCRIPTIONS_PRICING_TEST', { default: 'off' });
export const testMonthlyProductId = defineString('SUBSCRIPTIONS_TEST_MONTHLY_PRODUCT_ID', {
  default: '',
});
export const testYearlyProductId = defineString('SUBSCRIPTIONS_TEST_YEARLY_PRODUCT_ID', {
  default: '',
});
export const androidPackage = defineString('SUBSCRIPTIONS_ANDROID_PACKAGE', {
  default: 'io.nullstate.nestprep',
});
export const iosBundleId = defineString('SUBSCRIPTIONS_IOS_BUNDLE_ID', {
  default: 'io.nullstate.nestprep',
});
export const appleAppId = defineString('SUBSCRIPTIONS_APPLE_APP_ID', { default: '' });
export const appleIssuerId = defineString('SUBSCRIPTIONS_APPLE_ISSUER_ID', { default: '' });
export const appleKeyId = defineString('SUBSCRIPTIONS_APPLE_KEY_ID', { default: '' });
export const applePrivateKey = defineSecret('SUBSCRIPTIONS_APPLE_PRIVATE_KEY');

/** What the Functions that may ask Apple's API for a status are bound to. */
export const STORE_SECRETS = [applePrivateKey];

export type Cohort = 'a' | 'b';

export type PlanProducts = Readonly<Record<Plan, string>>;

export interface AppleApiKey {
  readonly issuerId: string;
  readonly keyId: string;
  readonly privateKey: string;
}

export interface SubscriptionConfig {
  /** Null until both product ids are set: premium is not on sale. */
  readonly products: Readonly<Record<Cohort, PlanProducts>> | null;
  readonly isPricingTestOn: boolean;
  readonly androidPackage: string;
  readonly iosBundleId: string;
  readonly appleAppId: number | null;
  readonly appleApiKey: AppleApiKey | null;
}

/**
 * The configuration as this instance sees it. [withSecrets] is false in a
 * Function not bound to the Apple key; it can still say what is on sale.
 */
export function subscriptionConfig(withSecrets: boolean): SubscriptionConfig {
  return readSubscriptionConfig({
    monthly: monthlyProductId.value(),
    yearly: yearlyProductId.value(),
    pricingTest: pricingTest.value(),
    testMonthly: testMonthlyProductId.value(),
    testYearly: testYearlyProductId.value(),
    androidPackage: androidPackage.value(),
    iosBundleId: iosBundleId.value(),
    appleAppId: appleAppId.value(),
    appleIssuerId: appleIssuerId.value(),
    appleKeyId: appleKeyId.value(),
    applePrivateKey: withSecrets ? applePrivateKey.value() : '',
  });
}

/** The raw values, as strings, before anything is decided about them. */
export type RawSubscriptionConfig = Readonly<Record<string, string>>;

/** Pure, so every combination of set and unset is a unit test. */
export function readSubscriptionConfig(raw: RawSubscriptionConfig): SubscriptionConfig {
  const value = (name: string): string | null => configured(raw[name] ?? '');
  const monthly = value('monthly');
  const yearly = value('yearly');
  const cohortA = monthly !== null && yearly !== null ? { monthly, yearly } : null;
  const cohortB = {
    monthly: value('testMonthly') ?? monthly ?? '',
    yearly: value('testYearly') ?? yearly ?? '',
  };
  const issuerId = value('appleIssuerId');
  const keyId = value('appleKeyId');
  const privateKey = value('applePrivateKey');
  const appId = Number(value('appleAppId') ?? 'NaN');
  return {
    products: cohortA === null ? null : { a: cohortA, b: cohortB },
    isPricingTestOn: value('pricingTest') === 'on',
    androidPackage: value('androidPackage') ?? '',
    iosBundleId: value('iosBundleId') ?? '',
    appleAppId: Number.isSafeInteger(appId) && appId > 0 ? appId : null,
    appleApiKey:
      issuerId !== null && keyId !== null && privateKey !== null
        ? { issuerId, keyId, privateKey }
        : null,
  };
}
