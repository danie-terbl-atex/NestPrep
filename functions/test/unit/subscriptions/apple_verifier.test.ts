import { describe, expect, it } from 'vitest';

import { AppStoreServerApi } from '../../../src/subscriptions/apple/app_store_server_api';
import { AppleVerifier } from '../../../src/subscriptions/apple/apple_verifier';
import type { SubscriptionConfig } from '../../../src/subscriptions/subscription_config';
import { PurchaseRejected } from '../../../src/subscriptions/verified_purchase';
import { ScriptedHttp, json } from '../calendar_sync/fakes';
import {
  CONFIG,
  IN_A_MONTH,
  NOW,
  TEST_PRIVATE_KEY,
  TEST_ROOT,
  YEARLY,
  appleNotification,
  appleRenewal,
  appleSigned,
  appleTransaction,
} from './store_fixtures';

/**
 * What the App Store says, read the way NestPrep reads it (subscriptions
 * ADR-0001): a transaction from the phone, a v2 notification, and — with a
 * key — the latest status from Apple's API.
 */
const KEY = {
  issuerId: '57246542-96fe-1a63-e053-0824d011072a',
  keyId: 'TESTKEY123',
  privateKey: TEST_PRIVATE_KEY,
};

function verifier(config: SubscriptionConfig = CONFIG): AppleVerifier {
  return new AppleVerifier({ config, roots: [TEST_ROOT], api: null, now: () => NOW });
}

async function rejection(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (error) {
    if (error instanceof PurchaseRejected) return error.why;
    throw error;
  }
  return 'accepted';
}

describe('a transaction handed over by the phone', () => {
  it('is an active subscription until its expiry, keyed by the original transaction id', async () => {
    const purchase = await verifier().verifyClientTransaction(appleSigned(appleTransaction()));
    expect(purchase.store).toBe('appStore');
    expect(purchase.storeRef).toBe('2000000100000001');
    expect(purchase.state).toMatchObject({
      status: 'active',
      accessUntil: IN_A_MONTH,
      productId: 'nestprep_premium_monthly',
      isTest: true,
      // Without the API a single transaction does not say whether it renews.
      willRenew: null,
    });
  });

  it('is expired once its expiry has passed', async () => {
    const lapsed = appleTransaction({ expiresDate: NOW.getTime() - 1000 });
    const purchase = await verifier().verifyClientTransaction(appleSigned(lapsed));
    expect(purchase.state.status).toBe('expired');
  });

  it('is revoked when Apple refunded it, whatever its expiry', async () => {
    const refunded = appleTransaction({ revocationDate: NOW.getTime() - 1000 });
    const purchase = await verifier().verifyClientTransaction(appleSigned(refunded));
    expect(purchase.state).toMatchObject({ status: 'revoked', accessUntil: null });
  });

  it('is refused when it is for another app', async () => {
    const other = appleSigned(appleTransaction({ bundleId: 'com.somebody.else' }));
    expect(await rejection(verifier().verifyClientTransaction(other))).toBe('another app');
  });

  it('is refused when it is not signed along Apple’s chain', async () => {
    const unmarked = appleSigned(appleTransaction(), { chain: 'unmarked-leaf' });
    expect(await rejection(verifier().verifyClientTransaction(unmarked))).toBe(
      'not an App Store signing certificate',
    );
  });

  it('asks Apple’s API for the latest status when a key is configured', async () => {
    const http = new ScriptedHttp(() =>
      json(200, {
        environment: 'Sandbox',
        bundleId: CONFIG.iosBundleId,
        data: [
          {
            subscriptionGroupIdentifier: '21000001',
            lastTransactions: [
              {
                originalTransactionId: '2000000100000001',
                status: 1,
                signedTransactionInfo: appleSigned(appleTransaction({ productId: YEARLY })),
                signedRenewalInfo: appleSigned(appleRenewal({ autoRenewStatus: 0 })),
              },
            ],
          },
        ],
      }),
    );
    const purchase = await verifierWithKey(http).verifyClientTransaction(
      appleSigned(appleTransaction()),
    );
    // The upgrade and the switched-off renewal are the API's news, not the phone's.
    expect(purchase.state).toMatchObject({
      status: 'cancelled',
      willRenew: false,
      productId: YEARLY,
    });
    expect(http.requests[0]?.url).toBe(
      'https://api.storekit-sandbox.itunes.apple.com/inApps/v1/subscriptions/2000000100000001',
    );
  });
});

describe('a v2 notification', () => {
  const signedData = (status: number, renewal = appleRenewal()): Record<string, unknown> => ({
    signedTransactionInfo: appleSigned(appleTransaction()),
    signedRenewalInfo: appleSigned(renewal),
    status,
  });

  it('DID_RENEW keeps it active until the new expiry', () => {
    const outcome = verifier().verifyNotification(
      appleSigned(appleNotification('DID_RENEW', signedData(1))),
    );
    expect(outcome.kind === 'purchase' && outcome.purchase.state.status).toBe('active');
  });

  it('DID_FAIL_TO_RENEW with a grace period keeps premium until the grace period ends', () => {
    const graceEnds = NOW.getTime() + 6 * 24 * 60 * 60 * 1000;
    const outcome = verifier().verifyNotification(
      appleSigned(
        appleNotification(
          'DID_FAIL_TO_RENEW',
          signedData(4, appleRenewal({ gracePeriodExpiresDate: graceEnds })),
          'GRACE_PERIOD',
        ),
      ),
    );
    expect(outcome.kind === 'purchase' && outcome.purchase.state).toMatchObject({
      status: 'inGracePeriod',
      accessUntil: new Date(graceEnds),
    });
  });

  it('EXPIRED and billing retry give nothing', () => {
    for (const [status, expected] of [
      [2, 'expired'],
      [3, 'onHold'],
    ] as const) {
      const outcome = verifier().verifyNotification(
        appleSigned(appleNotification('EXPIRED', signedData(status))),
      );
      expect(outcome.kind === 'purchase' && outcome.purchase.state.status).toBe(expected);
    }
  });

  it('REFUND takes premium back even when the status still says active', () => {
    const outcome = verifier().verifyNotification(
      appleSigned(appleNotification('REFUND', signedData(1))),
    );
    expect(outcome.kind === 'purchase' && outcome.purchase.state.status).toBe('revoked');
  });

  it('TEST carries no transaction and changes nothing', () => {
    const outcome = verifier().verifyNotification(appleSigned(appleNotification('TEST', {})));
    expect(outcome).toEqual({ kind: 'ignored', type: 'TEST' });
  });

  it('is refused when a production notification names another Apple app id', () => {
    const production = appleNotification('DID_RENEW', {
      ...signedData(1),
      environment: 'Production',
      appAppleId: 42,
    });
    expect(() => verifier().verifyNotification(appleSigned(production))).toThrow(PurchaseRejected);
  });
});

function verifierWithKey(http: ScriptedHttp): AppleVerifier {
  return new AppleVerifier({
    config: { ...CONFIG, appleApiKey: KEY },
    roots: [TEST_ROOT],
    api: new AppStoreServerApi(KEY, CONFIG.iosBundleId, http, () => NOW),
    now: () => NOW,
  });
}
