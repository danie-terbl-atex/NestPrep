import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import { rollupWeek } from '../../src/product_analytics/weekly_rollup';
import {
  type VerificationResult,
  verifyAndLinkPurchase,
} from '../../src/subscriptions/purchase_verification';
import type { VerifyPurchaseInput } from '../../src/subscriptions/schemas';
import { CONFIG } from '../unit/subscriptions/store_fixtures';
import { adminDb, callAs, clearFirestore, closeAdmin, signUp } from './emulator_harness';
import {
  ADMIN_NAME,
  HOUSEHOLD_NAME,
  expectRefusal,
  ledger,
  thisWeek,
} from './product_analytics_fixture';
import {
  DAY_MS,
  aFamily,
  codeOf,
  grantsOf,
  instant,
  read,
  redeem,
  setReferrals,
  type Family,
} from './referrals_fixture';
import { ScriptedStores, purchaseOf } from './subscriptions_fixture';

/**
 * Conversion by the feature that opened the paywall, and referrals, in the
 * weekly totals (product-analytics ADR-0002, subscriptions ADR-0002): the
 * paywall opening over HTTP, the purchase verified against a scripted store
 * on a real Firestore, and the rollup counting what they left.
 */

afterAll(closeAdmin);

const PAID_UNTIL = new Date(Date.now() + 30 * DAY_MS);

async function buys(
  family: Family,
  token: string,
  trigger: VerifyPurchaseInput['trigger'],
): Promise<VerificationResult> {
  const stores = new ScriptedStores({
    [token]: purchaseOf('playStore', token, { accessUntil: PAID_UNTIL }),
  });
  return verifyAndLinkPurchase(
    { store: adminDb(), config: CONFIG, verifiers: stores, now: () => new Date() },
    family.admin.uid,
    { householdId: family.householdId, store: 'playStore', verificationData: token, trigger },
  );
}

async function conversions(): Promise<Record<string, unknown>[]> {
  return (await adminDb().collection('analyticsConversions').get()).docs.map((doc) => doc.data());
}

describe('recordPaywallOpened', () => {
  beforeEach(clearFirestore);

  it('counts the household once per trigger this week, and remembers the last one', async () => {
    const family = await aFamily();
    const body = { householdId: family.householdId, trigger: 'prepList' };
    await callAs(family.admin, 'recordPaywallOpened', body);
    await callAs(family.admin, 'recordPaywallOpened', body);
    await callAs(family.admin, 'recordPaywallOpened', { ...body, trigger: 'additionalChild' });

    const week = await ledger(`analyticsHouseholdWeeks/${thisWeek()}_${family.householdId}`);
    expect(week?.['paywallTriggers']).toEqual(['prepList', 'additionalChild']);
    const cohort = await ledger(`analyticsHouseholds/${family.householdId}`);
    expect(cohort?.['lastPaywallTrigger']).toBe('additionalChild');
    expect(cohort?.['cohortWeek']).toBe(thisWeek());
  });

  it('refuses a stranger and a trigger outside the list, and writes nothing', async () => {
    const family = await aFamily();
    const stranger = await signUp();
    await expectRefusal(
      callAs(stranger, 'recordPaywallOpened', {
        householdId: family.householdId,
        trigger: 'direct',
      }),
      'notAMember',
    );
    await expectRefusal(
      callAs(family.admin, 'recordPaywallOpened', {
        householdId: family.householdId,
        trigger: 'a note about Mia',
      }),
      'badRequest',
    );
    expect(
      await ledger(`analyticsHouseholdWeeks/${thisWeek()}_${family.householdId}`),
    ).toBeUndefined();
  });
});

describe('a conversion', () => {
  beforeEach(clearFirestore);

  it('is attributed to the last paywall the household opened, not the phone"s word', async () => {
    const family = await aFamily();
    await callAs(family.admin, 'recordPaywallOpened', {
      householdId: family.householdId,
      trigger: 'lunchLearning',
    });

    await buys(family, 'token-1', 'direct');

    const [conversion] = await conversions();
    expect(conversion?.['trigger']).toBe('lunchLearning');
    expect(conversion?.['attribution']).toBe('lastPaywall');
  });

  it('keeps the purchase"s own trigger when no opening was recorded', async () => {
    const family = await aFamily();
    await buys(family, 'token-1', 'additionalChild');
    const [conversion] = await conversions();
    expect(conversion?.['trigger']).toBe('additionalChild');
    expect(conversion?.['attribution']).toBe('purchase');
  });

  it('qualifies a referred household on its first sale — and a restore never does', async () => {
    await setReferrals(true);
    const sharer = await aFamily();
    const restorer = await aFamily();
    await redeem(restorer, await codeOf(sharer));
    await buys(restorer, 'token-restore', null);
    expect((await read(`referrals/${restorer.householdId}`))['status']).toBe('pending');

    const buyer = await aFamily();
    await redeem(buyer, await codeOf(sharer));
    await buys(buyer, 'token-buy', 'direct');

    const referral = await read(`referrals/${buyer.householdId}`);
    expect(referral['status']).toBe('qualified');
    expect(referral['qualifiedBy']).toBe('premiumPurchase');
    // The buyer is paying, so its month waits after the paid time.
    const entitlement = await read(`households/${buyer.householdId}/entitlement/current`);
    expect(entitlement['referralDaysWaiting']).toBe(30);
    const storeUntil = instant(entitlement['storeUntil']);
    expect(instant(entitlement['premiumUntil'])).toEqual(
      storeUntil === null ? null : new Date(storeUntil.getTime() + 30 * DAY_MS),
    );
    expect(await grantsOf(sharer.householdId)).toHaveLength(1);
  });

  it('never erases a month already given when the store speaks again', async () => {
    await setReferrals(true);
    const sharer = await aFamily();
    const joiner = await aFamily();
    await redeem(joiner, await codeOf(sharer));
    await buys(joiner, 'token-1', 'direct');
    const before = instant(
      (await read(`households/${joiner.householdId}/entitlement/current`))['premiumUntil'],
    );

    await buys(joiner, 'token-1', 'direct');

    const after = instant(
      (await read(`households/${joiner.householdId}/entitlement/current`))['premiumUntil'],
    );
    expect(after).toEqual(before);
    expect((await conversions()).length).toBe(1);
  });
});

describe('the weekly totals', () => {
  beforeEach(clearFirestore);

  it('count families shown the paywall, conversions by trigger and referrals — and nothing personal', async () => {
    await setReferrals(true);
    const sharer = await aFamily();
    const joiner = await aFamily();
    await callAs(joiner.admin, 'recordPaywallOpened', {
      householdId: joiner.householdId,
      trigger: 'prepList',
    });
    await callAs(sharer.admin, 'recordPaywallOpened', {
      householdId: sharer.householdId,
      trigger: 'prepList',
    });
    const code = await codeOf(sharer);
    await redeem(joiner, code);
    await buys(joiner, 'token-1', 'direct');

    const numbers = await rollupWeek(adminDb(), thisWeek(), new Date());

    expect(numbers.paywallFamilies).toBe(2);
    expect(numbers.paywallFamiliesByTrigger.prepList).toBe(2);
    expect(numbers.premiumConversionsByTrigger.prepList).toBe(1);
    expect(numbers.referralsRedeemed).toBe(1);
    expect(numbers.referralsQualified).toBe(1);
    expect(numbers.referralMonthsGiven).toBe(2);

    const written = JSON.stringify(
      [
        ...(await adminDb().collection('analyticsWeeks').get()).docs,
        ...(await adminDb().collection('analyticsHouseholdWeeks').get()).docs,
        ...(await adminDb().collection('analyticsHouseholds').get()).docs,
        ...(await adminDb().collection('analyticsConversions').get()).docs,
      ].map((doc) => doc.data()),
    );
    for (const secret of [HOUSEHOLD_NAME, ADMIN_NAME, joiner.admin.email, joiner.admin.uid, code]) {
      expect(written).not.toContain(secret);
    }
    const totals = JSON.stringify(
      (await adminDb().doc(`analyticsWeeks/${thisWeek()}`).get()).data(),
    );
    expect(totals).not.toContain(joiner.householdId);
    expect(totals).not.toContain(sharer.householdId);
  });
});
