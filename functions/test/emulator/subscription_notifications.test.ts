import { Timestamp } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { verifyAndLinkPurchase } from '../../src/subscriptions/purchase_verification';
import { runReconcile } from '../../src/subscriptions/reconcile';
import {
  type NotificationDeps,
  applyAppStoreNotification,
  applyPlayNotification,
} from '../../src/subscriptions/store_notifications';
import { PurchaseRejected } from '../../src/subscriptions/verified_purchase';
import {
  BUNDLE_ID,
  CONFIG,
  IN_A_MONTH,
  LAST_WEEK,
  NOW,
} from '../unit/subscriptions/store_fixtures';
import { adminDb, clearFirestore } from './emulator_harness';
import {
  type Household,
  ScriptedStores,
  entitlementOf,
  givenAHousehold,
  purchaseOf,
} from './subscriptions_fixture';

/**
 * What the stores say on their own — renewals, lapses, refunds — reaching
 * the household's entitlement (subscriptions ADR-0001), and the daily
 * reconcile catching what a lost notification would have missed.
 */
function deps(stores: ScriptedStores): NotificationDeps {
  return { store: adminDb(), config: CONFIG, verifiers: stores, now: (): Date => NOW };
}

async function linkedHousehold(
  storeRef: string,
  store: 'appStore' | 'playStore' = 'playStore',
): Promise<Household> {
  const home = await givenAHousehold({ admin: 'uid-sam' });
  const stores = new ScriptedStores({ [storeRef]: purchaseOf(store, storeRef) });
  await verifyAndLinkPurchase(deps(stores), home.admin, {
    householdId: home.id,
    store,
    verificationData: storeRef,
    trigger: 'direct',
  });
  return home;
}

function playMessage(body: Record<string, unknown>): Record<string, unknown> {
  return {
    version: '1.0',
    packageName: BUNDLE_ID,
    eventTimeMillis: String(NOW.getTime()),
    ...body,
  };
}

describe('App Store notifications', () => {
  beforeEach(clearFirestore);

  it('EXPIRED takes premium away from the household the purchase belongs to', async () => {
    const home = await linkedHousehold('2000000100000001', 'appStore');
    const expired = purchaseOf('appStore', '2000000100000001', {
      status: 'expired',
      accessUntil: LAST_WEEK,
      willRenew: false,
    });

    const answer = await applyAppStoreNotification(deps(new ScriptedStores({})), () => ({
      kind: 'purchase',
      type: 'EXPIRED',
      purchase: expired,
    }));

    expect(answer).toBe('accepted');
    expect(await entitlementOf(home.id)).toMatchObject({ premiumUntil: null, status: 'expired' });
  });

  it('a payload that does not verify is a 400 and changes nothing', async () => {
    const home = await linkedHousehold('2000000100000001', 'appStore');
    const answer = await applyAppStoreNotification(deps(new ScriptedStores({})), () => {
      throw new PurchaseRejected('bad signature');
    });
    expect(answer).toBe('rejected');
    expect((await entitlementOf(home.id))['premiumUntil']).toBeInstanceOf(Timestamp);
  });

  it('one about a purchase nobody has verified is kept unlinked, and gives nobody premium', async () => {
    await applyAppStoreNotification(deps(new ScriptedStores({})), () => ({
      kind: 'purchase',
      type: 'SUBSCRIBED',
      purchase: purchaseOf('appStore', 'unseen'),
    }));
    const kept = await adminDb()
      .collection('storePurchases')
      .where('storeRef', '==', 'unseen')
      .get();
    expect(kept.docs[0]?.get('householdId')).toBeNull();
    expect((await adminDb().collectionGroup('entitlement').get()).size).toBe(0);
  });
});

describe('Play Real-time Developer Notifications', () => {
  beforeEach(clearFirestore);

  it('asks Google again for the token, and records what it says now', async () => {
    const home = await linkedHousehold('token-1');
    const stores = new ScriptedStores({
      'token-1': purchaseOf('playStore', 'token-1', { status: 'onHold', accessUntil: LAST_WEEK }),
    });
    await applyPlayNotification(
      deps(stores),
      playMessage({
        subscriptionNotification: { version: '1.0', notificationType: 5, purchaseToken: 'token-1' },
      }),
    );
    expect(stores.asked).toEqual(['token-1']);
    expect(await entitlementOf(home.id)).toMatchObject({ premiumUntil: null, status: 'onHold' });
  });

  it('a refund takes premium back even while Google still says active', async () => {
    const home = await linkedHousehold('token-1');
    const stores = new ScriptedStores({ 'token-1': purchaseOf('playStore', 'token-1') });
    await applyPlayNotification(
      deps(stores),
      playMessage({
        voidedPurchaseNotification: { purchaseToken: 'token-1', orderId: 'GPA.1', productType: 1 },
      }),
    );
    expect(await entitlementOf(home.id)).toMatchObject({ premiumUntil: null, status: 'revoked' });
  });

  it('ignores a message for another app and a test message, asking nobody', async () => {
    const stores = new ScriptedStores({});
    await applyPlayNotification(deps(stores), { ...playMessage({}), packageName: 'com.other' });
    await applyPlayNotification(
      deps(stores),
      playMessage({ testNotification: { version: '1.0' } }),
    );
    await applyPlayNotification(deps(stores), null);
    expect(stores.asked).toEqual([]);
  });
});

describe('the daily reconcile', () => {
  beforeEach(clearFirestore);

  it('renews a subscription whose renewal notification never came', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    const endingToday = purchaseOf('playStore', 'token-1', {
      accessUntil: new Date(NOW.getTime() + 60 * 60 * 1000),
    });
    await verifyAndLinkPurchase(deps(new ScriptedStores({ 'token-1': endingToday })), home.admin, {
      householdId: home.id,
      store: 'playStore',
      verificationData: 'token-1',
      trigger: null,
    });

    const renewed = purchaseOf('playStore', 'token-1', { accessUntil: IN_A_MONTH });
    const summary = await runReconcile(deps(new ScriptedStores({ 'token-1': renewed })));

    expect(summary).toEqual({ checked: 1, refreshed: 1, failed: 0 });
    const until = (await entitlementOf(home.id))['premiumUntil'] as Timestamp;
    expect(until.toMillis()).toBeGreaterThan(IN_A_MONTH.getTime());
  });

  it('leaves a subscription alone when the store cannot be asked, and says so', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    await verifyAndLinkPurchase(
      deps(
        new ScriptedStores({
          'token-1': purchaseOf('playStore', 'token-1', {
            accessUntil: new Date(NOW.getTime() + 1000),
          }),
        }),
      ),
      home.admin,
      { householdId: home.id, store: 'playStore', verificationData: 'token-1', trigger: null },
    );
    const summary = await runReconcile(deps(new ScriptedStores({ 'token-1': 'unreachable' })));
    expect(summary).toEqual({ checked: 1, refreshed: 0, failed: 1 });
  });

  it('does not ask about subscriptions far from their end', async () => {
    await linkedHousehold('token-1');
    const stores = new ScriptedStores({});
    expect(await runReconcile(deps(stores))).toEqual({ checked: 0, refreshed: 0, failed: 0 });
    expect(stores.asked).toEqual([]);
  });
});
