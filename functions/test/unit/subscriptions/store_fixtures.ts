import { X509Certificate, sign } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import type { SubscriptionConfig } from '../../../src/subscriptions/subscription_config';

/**
 * Recorded store answers for the subscriptions tests (subscriptions
 * ADR-0001): a signing chain shaped exactly like Apple's — a root, an
 * intermediate carrying Apple's intermediate marker and a leaf carrying the
 * receipt-signing marker — but made for these tests and trusted by nothing
 * else, and Google's `SubscriptionPurchaseV2` in each state the Play
 * Developer API documents. The certificates are in `test/fixtures/apple/`;
 * their key signs nothing outside this folder.
 */
const FIXTURES = resolve(import.meta.dirname, '../../fixtures/apple');

function pem(name: string): string {
  return readFileSync(resolve(FIXTURES, name), 'utf8');
}

function der(name: string): string {
  return new X509Certificate(pem(name)).raw.toString('base64');
}

export const TEST_ROOT = new X509Certificate(pem('root.pem')).raw;
/**
 * The test leaf's private key. It also stands in for an App Store Connect API
 * key: both are PKCS#8 P-256 keys, which is all the API's bearer token needs.
 */
export const TEST_PRIVATE_KEY = pem('leaf-test-only.p8');

export type Chain = 'apple-shaped' | 'unmarked-leaf';

/** Signs [payload] the way the App Store does: ES256, with the chain in `x5c`. */
export function appleSigned(
  payload: unknown,
  options: { chain?: Chain; alg?: string } = {},
): string {
  const leaf = options.chain === 'unmarked-leaf' ? 'unmarked-leaf.pem' : 'leaf.pem';
  const header = {
    alg: options.alg ?? 'ES256',
    x5c: [der(leaf), der('intermediate.pem'), der('root.pem')],
  };
  const unsigned = `${encode(header)}.${encode(payload)}`;
  const signature = sign('sha256', Buffer.from(unsigned), {
    key: TEST_PRIVATE_KEY,
    dsaEncoding: 'ieee-p1363',
  });
  return `${unsigned}.${signature.toString('base64url')}`;
}

function encode(value: unknown): string {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

export const BUNDLE_ID = 'io.nullstate.nestprep';
export const MONTHLY = 'nestprep_premium_monthly';
export const YEARLY = 'nestprep_premium_yearly';

/** Premium on sale, cohort `a` only, Apple's API not configured. */
export const CONFIG: SubscriptionConfig = {
  products: {
    a: { monthly: MONTHLY, yearly: YEARLY },
    b: { monthly: MONTHLY, yearly: YEARLY },
  },
  isPricingTestOn: false,
  androidPackage: BUNDLE_ID,
  iosBundleId: BUNDLE_ID,
  appleAppId: 1234567890,
  appleApiKey: null,
};

// The fixture certificates were issued on the afternoon of 2026-09-29 and are
// good for nineteen years, so the tests' clock stands a week after that.
export const NOW = new Date('2026-10-05T10:00:00Z');
export const IN_A_MONTH = new Date('2026-11-05T10:00:00Z');
export const LAST_WEEK = new Date('2026-09-28T10:00:00Z');

/** An App Store transaction's payload, as Apple signs it. */
export function appleTransaction(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    transactionId: '2000000123456789',
    originalTransactionId: '2000000100000001',
    bundleId: BUNDLE_ID,
    productId: MONTHLY,
    purchaseDate: LAST_WEEK.getTime(),
    expiresDate: IN_A_MONTH.getTime(),
    type: 'Auto-Renewable Subscription',
    environment: 'Sandbox',
    signedDate: NOW.getTime(),
    ...overrides,
  };
}

export function appleRenewal(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    originalTransactionId: '2000000100000001',
    autoRenewProductId: MONTHLY,
    autoRenewStatus: 1,
    environment: 'Sandbox',
    signedDate: NOW.getTime(),
    ...overrides,
  };
}

/** A Server Notification v2's payload, as Apple signs it. */
export function appleNotification(
  type: string,
  data: Record<string, unknown>,
  subtype?: string,
): Record<string, unknown> {
  return {
    notificationType: type,
    ...(subtype === undefined ? {} : { subtype }),
    notificationUUID: 'b2d4c3a0-0000-4000-8000-000000000001',
    version: '2.0',
    signedDate: NOW.getTime(),
    data: { bundleId: BUNDLE_ID, environment: 'Sandbox', appAppleId: 1234567890, ...data },
  };
}

/** Google's `SubscriptionPurchaseV2`, in the shape the Play Developer API answers. */
export function playSubscriptionV2(
  state: string,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    kind: 'androidpublisher#subscriptionPurchaseV2',
    regionCode: 'ZA',
    startTime: LAST_WEEK.toISOString(),
    subscriptionState: state,
    latestOrderId: 'GPA.3345-1234-5678-90123',
    acknowledgementState: 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED',
    lineItems: [
      {
        productId: MONTHLY,
        expiryTime: IN_A_MONTH.toISOString(),
        autoRenewingPlan: { autoRenewEnabled: state === 'SUBSCRIPTION_STATE_ACTIVE' },
        offerDetails: { basePlanId: 'monthly' },
      },
    ],
    ...overrides,
  };
}
