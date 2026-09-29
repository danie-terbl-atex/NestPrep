import { HttpsError } from 'firebase-functions/v2/https';
import { Timestamp } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { markChild } from '../../src/family_profiles/set_child_profile';
import {
  type PurchaseVerificationDeps,
  verifyAndLinkPurchase,
} from '../../src/subscriptions/purchase_verification';
import type { VerifyPurchaseInput } from '../../src/subscriptions/schemas';
import type { SubscriptionConfig } from '../../src/subscriptions/subscription_config';
import { CONFIG, IN_A_MONTH, LAST_WEEK, NOW, YEARLY } from '../unit/subscriptions/store_fixtures';
import { adminDb, clearFirestore } from './emulator_harness';
import {
  ScriptedStores,
  entitlementOf,
  givenAChild,
  givenAHousehold,
  givenPremiumUntil,
  purchaseOf,
} from './subscriptions_fixture';

/**
 * A purchase becoming a household's premium, and the free tier's one-child
 * limit, against a real Firestore (subscriptions ADR-0001). The stores are
 * scripted — the adapters have their own tests against recorded answers —
 * so what is proved here is the part only a database can show: the
 * transaction, the link, the entitlement every member reads, the conversion
 * counted once, and the limit refused where the write would have happened.
 */
function deps(
  stores: ScriptedStores,
  config: SubscriptionConfig = CONFIG,
): PurchaseVerificationDeps {
  return { store: adminDb(), config, verifiers: stores, now: (): Date => NOW };
}

function purchase(
  householdId: string,
  overrides: Partial<VerifyPurchaseInput> = {},
): VerifyPurchaseInput {
  return {
    householdId,
    store: 'playStore',
    verificationData: 'token-1',
    trigger: 'additionalChild',
    ...overrides,
  };
}

async function refusal(promise: Promise<unknown>): Promise<string | undefined> {
  try {
    await promise;
  } catch (error) {
    if (error instanceof HttpsError) {
      const details: unknown = error.details;
      return typeof details === 'object' && details !== null && 'reason' in details
        ? String(details.reason)
        : error.code;
    }
    throw error;
  }
  return undefined;
}

async function conversions(): Promise<Record<string, unknown>[]> {
  const found = await adminDb().collection('analyticsConversions').get();
  return found.docs.map((doc) => doc.data());
}

describe('verifyAndLinkPurchase', () => {
  beforeEach(clearFirestore);

  it('gives the whole household premium until the store’s date, managed by the buyer', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    const stores = new ScriptedStores({ 'token-1': purchaseOf('playStore', 'token-1') });

    const result = await verifyAndLinkPurchase(deps(stores), home.parent, purchase(home.id));

    expect(result.isPremium).toBe(true);
    const entitlement = await entitlementOf(home.id);
    expect(entitlement).toMatchObject({
      status: 'active',
      plan: 'monthly',
      store: 'playStore',
      managedByMemberId: 'm-mia',
    });
    expect((entitlement['premiumUntil'] as Timestamp).toMillis()).toBeGreaterThan(
      IN_A_MONTH.getTime(),
    );
  });

  it('counts the conversion once, against what opened the paywall — never for a restore', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    const stores = new ScriptedStores({ 'token-1': purchaseOf('playStore', 'token-1') });

    await verifyAndLinkPurchase(deps(stores), home.admin, purchase(home.id));
    await verifyAndLinkPurchase(deps(stores), home.admin, purchase(home.id));
    await verifyAndLinkPurchase(deps(stores), home.admin, purchase(home.id, { trigger: null }));

    const counted = await conversions();
    expect(counted).toHaveLength(1);
    expect(counted[0]).toMatchObject({ householdId: home.id, trigger: 'additionalChild' });
  });

  it('refuses a helper, who may see the offer but is not asked to pay', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    const stores = new ScriptedStores({ 'token-1': purchaseOf('playStore', 'token-1') });
    expect(await refusal(verifyAndLinkPurchase(deps(stores), home.helper, purchase(home.id)))).toBe(
      'onlyFamilyCanBuy',
    );
    expect(stores.asked).toEqual([]);
  });

  it('refuses somebody outside the household before the store is asked', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    const stores = new ScriptedStores({});
    expect(
      await refusal(verifyAndLinkPurchase(deps(stores), 'uid-stranger', purchase(home.id))),
    ).toBe('notAMember');
    expect(stores.asked).toEqual([]);
  });

  it('says premium is not on sale yet when no product is configured', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    const unconfigured = { ...CONFIG, products: null };
    expect(
      await refusal(
        verifyAndLinkPurchase(
          deps(new ScriptedStores({}), unconfigured),
          home.admin,
          purchase(home.id),
        ),
      ),
    ).toBe('premiumUnavailable');
  });

  it('refuses a receipt the store does not vouch for, or for somebody else’s product', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    const stores = new ScriptedStores({
      forged: 'rejected',
      other: purchaseOf('playStore', 'other', { productId: 'com.other.premium' }),
    });
    for (const data of ['forged', 'other']) {
      expect(
        await refusal(
          verifyAndLinkPurchase(
            deps(stores),
            home.admin,
            purchase(home.id, { verificationData: data }),
          ),
        ),
      ).toBe('purchaseNotValid');
    }
    expect(await entitlementOf(home.id)).toEqual({});
  });

  it('says the store could not be asked, so the phone keeps the purchase and tries again', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    const stores = new ScriptedStores({ 'token-1': 'unreachable' });
    expect(await refusal(verifyAndLinkPurchase(deps(stores), home.admin, purchase(home.id)))).toBe(
      'storeUnreachable',
    );
  });

  it('refuses one store account unlocking a second household', async () => {
    const first = await givenAHousehold({ admin: 'uid-sam' });
    const second = await givenAHousehold({ admin: 'uid-olivia' });
    const stores = new ScriptedStores({ 'token-1': purchaseOf('playStore', 'token-1') });
    await verifyAndLinkPurchase(deps(stores), first.admin, purchase(first.id));

    expect(
      await refusal(verifyAndLinkPurchase(deps(stores), second.admin, purchase(second.id))),
    ).toBe('purchaseInUseElsewhere');
    expect(await entitlementOf(second.id)).toEqual({});
  });

  it('lets the buyer take their subscription to a new household, and the old one loses it', async () => {
    const first = await givenAHousehold({ admin: 'uid-sam' });
    const second = await givenAHousehold({ admin: 'uid-sam-new', parent: 'uid-sam' });
    const stores = new ScriptedStores({ 'token-1': purchaseOf('playStore', 'token-1') });
    await verifyAndLinkPurchase(deps(stores), 'uid-sam', purchase(first.id));

    await verifyAndLinkPurchase(deps(stores), 'uid-sam', purchase(second.id, { trigger: null }));

    expect((await entitlementOf(first.id))['premiumUntil']).toBeNull();
    expect((await entitlementOf(second.id))['premiumUntil']).toBeInstanceOf(Timestamp);
  });

  it('stops counting a subscription an upgrade replaced', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    const stores = new ScriptedStores({
      monthly: purchaseOf('playStore', 'monthly', { accessUntil: IN_A_MONTH }),
      yearly: purchaseOf('playStore', 'yearly', { productId: YEARLY }, 'monthly'),
    });
    await verifyAndLinkPurchase(
      deps(stores),
      home.admin,
      purchase(home.id, { verificationData: 'monthly' }),
    );
    await verifyAndLinkPurchase(
      deps(stores),
      home.admin,
      purchase(home.id, { verificationData: 'yearly' }),
    );

    expect(await entitlementOf(home.id)).toMatchObject({ plan: 'yearly' });
    const replaced = await adminDb()
      .collection('storePurchases')
      .where('storeRef', '==', 'monthly')
      .get();
    expect(replaced.docs[0]?.get('supersededBy')).toEqual(expect.any(String));
  });
});

describe('markChild — the free tier’s one child', () => {
  beforeEach(clearFirestore);

  // Every mark carries a parent's consent unless a test says otherwise
  // (accounts ADR-0005).
  const mark = (
    householdId: string,
    uid: string,
    memberId: string,
    isChild = true,
  ): Promise<void> =>
    markChild(
      adminDb(),
      uid,
      { householdId, memberId, isChild, guardianConsent: { version: 1 } },
      NOW,
    );

  it('lets a free household mark its first child', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    await mark(home.id, home.admin, 'm-emma');
    const profile = await adminDb().doc(`households/${home.id}/familyProfiles/m-emma`).get();
    expect(profile.get('isChild')).toBe(true);
  });

  it('refuses a second child on the free tier, naming the feature for the paywall', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    await givenAChild(home.id, 'm-emma');
    expect(await refusal(mark(home.id, home.admin, 'm-leo'))).toBe('premiumRequired');
    const profile = await adminDb().doc(`households/${home.id}/familyProfiles/m-leo`).get();
    expect(profile.exists).toBe(false);
  });

  it('lets a premium household mark as many children as it has', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    await givenAChild(home.id, 'm-emma');
    await givenPremiumUntil(home.id, IN_A_MONTH);
    await mark(home.id, home.admin, 'm-leo');
  });

  it('refuses a household whose premium has lapsed — and keeps both children it already has', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    await givenAChild(home.id, 'm-emma');
    await givenAChild(home.id, 'm-leo');
    await givenPremiumUntil(home.id, LAST_WEEK);

    expect(await refusal(mark(home.id, home.admin, 'm-sam'))).toBe('premiumRequired');
    const children = await adminDb()
      .collection(`households/${home.id}/familyProfiles`)
      .where('isChild', '==', true)
      .get();
    expect(children.size).toBe(2);
  });

  it('marking the same child again is not a second child', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    await givenAChild(home.id, 'm-emma');
    await mark(home.id, home.admin, 'm-emma');
  });

  it('always lets a child be unmarked, which is how a free household makes room', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    await givenAChild(home.id, 'm-emma');
    await mark(home.id, home.admin, 'm-emma', false);
    await mark(home.id, home.admin, 'm-leo');
  });

  it('refuses a parent who is not an admin marking somebody else, as the profile rules do', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    expect(await refusal(mark(home.id, home.parent, 'm-emma'))).toBe('notAnAdmin');
  });

  it('records the parent’s consent on the child, as the caller’s own profile', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    await markChild(
      adminDb(),
      home.admin,
      { householdId: home.id, memberId: 'm-emma', isChild: true, guardianConsent: { version: 3 } },
      NOW,
    );
    const consent = (await adminDb().doc(`households/${home.id}/members/m-emma`).get()).get(
      'guardianConsent',
    ) as Record<string, unknown>;
    expect(consent['byMemberId']).toBe('m-sam');
    expect(consent['version']).toBe(3);
    expect(consent['at']).toBeInstanceOf(Timestamp);
  });

  it('refuses a child with no consent on record and none given, writing nothing', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    const without = markChild(
      adminDb(),
      home.admin,
      { householdId: home.id, memberId: 'm-emma', isChild: true },
      NOW,
    );
    expect(await refusal(without)).toBe('guardianConsentRequired');
    const profile = await adminDb().doc(`households/${home.id}/familyProfiles/m-emma`).get();
    expect(profile.exists).toBe(false);
  });

  it('needs no new consent where one is on record, and never replaces it', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    const emma = adminDb().doc(`households/${home.id}/members/m-emma`);
    const onRecord = { byMemberId: 'm-mia', version: 1, at: Timestamp.fromDate(NOW) };
    await emma.update({ guardianConsent: onRecord });

    await markChild(
      adminDb(),
      home.admin,
      { householdId: home.id, memberId: 'm-emma', isChild: true },
      NOW,
    );
    await mark(home.id, home.admin, 'm-emma');
    expect((await emma.get()).get('guardianConsent')).toEqual(onRecord);
  });

  it('unmarking asks for no consent', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    await givenAChild(home.id, 'm-emma');
    await markChild(
      adminDb(),
      home.admin,
      { householdId: home.id, memberId: 'm-emma', isChild: false },
      NOW,
    );
  });

  it('refuses a member who is not there, and somebody outside the household', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    expect(await refusal(mark(home.id, home.admin, 'm-nobody'))).toBe('memberNotFound');
    expect(await refusal(mark(home.id, 'uid-stranger', 'm-emma'))).toBe('notAMember');
  });
});
