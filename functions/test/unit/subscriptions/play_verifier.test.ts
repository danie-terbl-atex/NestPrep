import { describe, expect, it } from 'vitest';

import type { AccessTokenSource } from '../../../src/subscriptions/google/play_access_token';
import {
  ANDROID_PUBLISHER_API,
  PlayVerifier,
} from '../../../src/subscriptions/google/play_verifier';
import { PurchaseRejected, StoreUnreachable } from '../../../src/subscriptions/verified_purchase';
import { ScriptedHttp, json } from '../calendar_sync/fakes';
import { BUNDLE_ID, IN_A_MONTH, MONTHLY, playSubscriptionV2 } from './store_fixtures';

/**
 * Google Play's answers, read the way NestPrep reads them (subscriptions
 * ADR-0001). Every state Google documents lands on NestPrep's vocabulary,
 * and only an answer from Google — never the phone's word — makes a
 * purchase real.
 */
const tokens: AccessTokenSource = { token: () => Promise.resolve('play-access-token') };

function verifier(http: ScriptedHttp): PlayVerifier {
  return new PlayVerifier(BUNDLE_ID, http, tokens);
}

describe('PlayVerifier', () => {
  it('asks the Play Developer API with the service account’s token', async () => {
    const http = new ScriptedHttp(() => json(200, playSubscriptionV2('SUBSCRIPTION_STATE_ACTIVE')));
    const purchase = await verifier(http).verify('token-abc');

    expect(http.requests[0]?.url).toBe(
      `${ANDROID_PUBLISHER_API}/${BUNDLE_ID}/purchases/subscriptionsv2/tokens/token-abc`,
    );
    expect(http.requests[0]?.request.headers?.['Authorization']).toBe('Bearer play-access-token');
    expect(purchase).toEqual({
      store: 'playStore',
      storeRef: 'token-abc',
      replaces: null,
      state: {
        status: 'active',
        accessUntil: IN_A_MONTH,
        willRenew: true,
        productId: MONTHLY,
        isTest: false,
      },
    });
  });

  it.each([
    ['SUBSCRIPTION_STATE_ACTIVE', 'active'],
    ['SUBSCRIPTION_STATE_CANCELED', 'cancelled'],
    ['SUBSCRIPTION_STATE_IN_GRACE_PERIOD', 'inGracePeriod'],
    ['SUBSCRIPTION_STATE_ON_HOLD', 'onHold'],
    ['SUBSCRIPTION_STATE_PAUSED', 'paused'],
    ['SUBSCRIPTION_STATE_PENDING', 'pending'],
    ['SUBSCRIPTION_STATE_EXPIRED', 'expired'],
    ['SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED', 'expired'],
    // A state Google adds later gives nothing until somebody has read about it.
    ['SUBSCRIPTION_STATE_SOMETHING_NEW', 'expired'],
  ])('reads %s as %s', async (state, status) => {
    const http = new ScriptedHttp(() => json(200, playSubscriptionV2(state)));
    expect((await verifier(http).verify('t')).state.status).toBe(status);
  });

  it('marks a licence tester’s purchase as a test', async () => {
    const http = new ScriptedHttp(() =>
      json(200, playSubscriptionV2('SUBSCRIPTION_STATE_ACTIVE', { testPurchase: {} })),
    );
    expect((await verifier(http).verify('t')).state.isTest).toBe(true);
  });

  it('names the token an upgrade or resubscribe replaces', async () => {
    const http = new ScriptedHttp(() =>
      json(200, playSubscriptionV2('SUBSCRIPTION_STATE_ACTIVE', { linkedPurchaseToken: 'old' })),
    );
    expect((await verifier(http).verify('new')).replaces).toBe('old');
  });

  it('acknowledges a purchase Google is still waiting on, so it is not refunded in three days', async () => {
    const http = new ScriptedHttp((url) =>
      url.endsWith(':acknowledge')
        ? json(200, {})
        : json(
            200,
            playSubscriptionV2('SUBSCRIPTION_STATE_ACTIVE', {
              acknowledgementState: 'ACKNOWLEDGEMENT_STATE_PENDING',
            }),
          ),
    );
    await verifier(http).verify('token-abc');
    expect(http.requests.map((request) => request.request.method)).toEqual(['GET', 'POST']);
    expect(http.requests[1]?.url).toBe(
      `${ANDROID_PUBLISHER_API}/${BUNDLE_ID}/purchases/subscriptions/${MONTHLY}/tokens/token-abc:acknowledge`,
    );
  });

  it('does not acknowledge twice what is already acknowledged', async () => {
    const http = new ScriptedHttp(() => json(200, playSubscriptionV2('SUBSCRIPTION_STATE_ACTIVE')));
    await verifier(http).verify('t');
    expect(http.requests).toHaveLength(1);
  });

  it('keeps a verified purchase when the acknowledgement itself fails', async () => {
    const http = new ScriptedHttp((url) =>
      url.endsWith(':acknowledge')
        ? json(503, {})
        : json(
            200,
            playSubscriptionV2('SUBSCRIPTION_STATE_ACTIVE', {
              acknowledgementState: 'ACKNOWLEDGEMENT_STATE_PENDING',
            }),
          ),
    );
    expect((await verifier(http).verify('t')).state.status).toBe('active');
  });

  it('rejects a token Google does not know', async () => {
    for (const status of [400, 404, 410]) {
      const http = new ScriptedHttp(() => json(status, { error: { code: status } }));
      await expect(verifier(http).verify('made-up')).rejects.toBeInstanceOf(PurchaseRejected);
    }
  });

  it('says the store could not be asked when Google refuses our account or fails', async () => {
    for (const status of [401, 403, 500]) {
      const http = new ScriptedHttp(() => json(status, {}));
      await expect(verifier(http).verify('t')).rejects.toBeInstanceOf(StoreUnreachable);
    }
    const noToken: AccessTokenSource = {
      token: () => Promise.reject(new StoreUnreachable('no credentials')),
    };
    const http = new ScriptedHttp(() => json(200, {}));
    await expect(new PlayVerifier(BUNDLE_ID, http, noToken).verify('t')).rejects.toBeInstanceOf(
      StoreUnreachable,
    );
    expect(http.requests).toHaveLength(0);
  });
});
