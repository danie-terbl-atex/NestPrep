import { Timestamp } from 'firebase-admin/firestore';
import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import { adminDb, callAs, clearFirestore, closeAdmin, signUp } from './emulator_harness';
import { expectRefusal } from './product_analytics_fixture';
import {
  DAY_MS,
  aFamily,
  codeOf,
  grantsOf,
  historyOf,
  instant,
  isAbout,
  joins,
  opens,
  read,
  redeem,
  setReferrals,
} from './referrals_fixture';

/**
 * Give a month, get a month, end to end (subscriptions ADR-0002): the
 * callables over HTTP with real tokens, qualification through the app's own
 * daily `recordActivity`, and the month landing in both entitlements.
 */

afterAll(closeAdmin);

describe('a household"s own code', () => {
  beforeEach(clearFirestore);

  it('is made on first ask and the same ever after, and only its family reads it', async () => {
    const family = await aFamily();
    const code = await codeOf(family);

    expect(code).toMatch(/^[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{8}$/);
    expect(await codeOf(family)).toBe(code);
    expect((await read(`referralCodes/${code}`))['householdId']).toBe(family.householdId);
    const own = await read(`households/${family.householdId}/referral/current`);
    expect(own['code']).toBe(code);
    expect(isAbout(own['redeemBy'], 7)).toBe(true);
  });

  it('is not given to a helper, nor to somebody outside the household', async () => {
    const family = await aFamily();
    const helper = await joins(family, 'helper');
    const stranger = await signUp();

    await expectRefusal(
      callAs(helper, 'ensureReferralCode', { householdId: family.householdId }),
      'onlyFamilyCanRefer',
    );
    await expectRefusal(
      callAs(stranger, 'ensureReferralCode', { householdId: family.householdId }),
      'notAMember',
    );
  });

  it('is refused while referrals are switched off', async () => {
    const family = await aFamily();
    await setReferrals(false);
    await expectRefusal(
      callAs(family.admin, 'ensureReferralCode', { householdId: family.householdId }),
      'referralsOff',
    );
  });
});

describe('entering a code', () => {
  beforeEach(clearFirestore);

  it('records a pending referral on both sides, naming neither household to the other', async () => {
    const sharer = await aFamily();
    const joiner = await aFamily();
    const qualifyBy = await redeem(joiner, await codeOf(sharer));

    expect(new Date(qualifyBy).getTime()).toBeGreaterThan(Date.now() + 13 * DAY_MS);
    const ledger = await read(`referrals/${joiner.householdId}`);
    expect(ledger['status']).toBe('pending');
    expect(ledger['referrerHouseholdId']).toBe(sharer.householdId);
    expect(ledger['activeUids']).toEqual([joiner.admin.uid]);

    const [given] = await historyOf(sharer.householdId);
    const [taken] = await historyOf(joiner.householdId);
    expect(given?.['side']).toBe('referrer');
    expect(taken?.['side']).toBe('referred');
    expect(JSON.stringify(given)).not.toContain(joiner.householdId);
    expect(JSON.stringify(taken)).not.toContain(sharer.householdId);
    expect((await read(`households/${joiner.householdId}/referral/current`))['hasRedeemed']).toBe(
      true,
    );
    expect(await grantsOf(sharer.householdId)).toEqual([]);
  });

  it('is once per household', async () => {
    const sharer = await aFamily();
    const other = await aFamily();
    const joiner = await aFamily();
    await redeem(joiner, await codeOf(sharer));
    await expectRefusal(redeem(joiner, await codeOf(other)), 'alreadyRedeemed');
  });

  it('refuses a household"s own code, and a code from a household the caller is in', async () => {
    const sharer = await aFamily();
    await expectRefusal(redeem(sharer, await codeOf(sharer)), 'ownReferralCode');

    // The sharer's admin makes a second household and tries to refer it.
    const { householdId } = await callAs<{ householdId: string }>(sharer.admin, 'createHousehold', {
      name: 'Second home',
      timeZone: 'Africa/Johannesburg',
      adminDisplayName: 'Sam',
      adminColor: 'violet',
    });
    await expectRefusal(
      redeem({ admin: sharer.admin, householdId }, await codeOf(sharer)),
      'ownReferralCode',
    );
  });

  it('refuses a household in which somebody from the sharing household already is', async () => {
    const sharer = await aFamily();
    const joiner = await aFamily();
    await joins(joiner, 'parent', sharer.admin);
    await expectRefusal(redeem(joiner, await codeOf(sharer)), 'ownReferralCode');
  });

  it('refuses a code that is not one, and a household past its first week', async () => {
    const sharer = await aFamily();
    const joiner = await aFamily();
    await expectRefusal(redeem(joiner, 'ZZZZ2222'), 'referralCodeNotFound');

    await adminDb()
      .doc(`households/${joiner.householdId}`)
      .update({ createdAt: Timestamp.fromMillis(Date.now() - 8 * DAY_MS) });
    await expectRefusal(redeem(joiner, await codeOf(sharer)), 'tooLateToRedeem');
  });

  it('refuses a helper, and anybody while referrals are switched off', async () => {
    const sharer = await aFamily();
    const joiner = await aFamily();
    const code = await codeOf(sharer);
    const helper = await joins(joiner, 'helper');
    await expectRefusal(redeem(joiner, code, helper), 'onlyFamilyCanRefer');

    await setReferrals(false);
    await expectRefusal(redeem(joiner, code), 'referralsOff');
  });

  it('pauses a code redeemed five times in a day', async () => {
    const sharer = await aFamily();
    const code = await codeOf(sharer);
    for (let index = 0; index < 5; index += 1) await redeem(await aFamily(), code);
    await expectRefusal(redeem(await aFamily(), code), 'tooManyRedemptions');
  });
});

describe('becoming a real family', () => {
  beforeEach(clearFirestore);

  it('gives both households a month once a second adult opens the new one', async () => {
    const sharer = await aFamily();
    const joiner = await aFamily();
    await redeem(joiner, await codeOf(sharer));
    const partner = await joins(joiner, 'parent');

    await opens(partner, joiner);

    const ledger = await read(`referrals/${joiner.householdId}`);
    expect(ledger['status']).toBe('qualified');
    expect(ledger['qualifiedBy']).toBe('twoAdults');
    expect(ledger['referrerReward']).toBe('month');
    expect(ledger['referredReward']).toBe('month');
    for (const householdId of [sharer.householdId, joiner.householdId]) {
      const entitlement = await read(`households/${householdId}/entitlement/current`);
      expect(isAbout(entitlement['premiumUntil'], 30), householdId).toBe(true);
      expect(isAbout(entitlement['referralUntil'], 30)).toBe(true);
      expect(entitlement['status']).toBe('none');
      expect(entitlement['store']).toBeNull();
      const grants = await grantsOf(householdId);
      expect(grants).toHaveLength(1);
      expect(grants[0]?.['days']).toBe(30);
      expect(instant(grants[0]?.['startsAt'])).not.toBeNull();
      const [line] = await historyOf(householdId);
      expect(line?.['status']).toBe('qualified');
      expect(line?.['reward']).toBe('month');
    }
    // A household given a month has made no store purchase.
    expect((await adminDb().collection('storePurchases').get()).size).toBe(0);
  });

  it('pays once, however often the family opens the app afterwards', async () => {
    const sharer = await aFamily();
    const joiner = await aFamily();
    await redeem(joiner, await codeOf(sharer));
    const partner = await joins(joiner, 'parent');
    await opens(partner, joiner);
    await opens(partner, joiner);
    await opens(joiner.admin, joiner);

    expect(await grantsOf(sharer.householdId)).toHaveLength(1);
    expect(await grantsOf(joiner.householdId)).toHaveLength(1);
  });

  it('does not count the same adult twice, nor a member of the sharing household', async () => {
    const sharer = await aFamily();
    const joiner = await aFamily();
    await redeem(joiner, await codeOf(sharer));
    await opens(joiner.admin, joiner);
    const insider = await joins(sharer, 'parent');
    await joins(joiner, 'parent', insider);
    await opens(insider, joiner);

    expect((await read(`referrals/${joiner.householdId}`))['status']).toBe('pending');
    expect(await grantsOf(joiner.householdId)).toEqual([]);
  });

  it('waits while referrals are switched off, and pays once they are back on', async () => {
    const sharer = await aFamily();
    const joiner = await aFamily();
    await redeem(joiner, await codeOf(sharer));
    const partner = await joins(joiner, 'parent');

    await setReferrals(false);
    await opens(partner, joiner);
    expect((await read(`referrals/${joiner.householdId}`))['status']).toBe('pending');
    expect(await grantsOf(joiner.householdId)).toEqual([]);

    await setReferrals(true);
    await opens(joiner.admin, joiner);
    expect((await read(`referrals/${joiner.householdId}`))['status']).toBe('qualified');
  });

  it('expires once its fourteen days have passed', async () => {
    const sharer = await aFamily();
    const joiner = await aFamily();
    await redeem(joiner, await codeOf(sharer));
    await adminDb()
      .doc(`referrals/${joiner.householdId}`)
      .update({ qualifyBy: Timestamp.fromMillis(Date.now() - 1000) });
    const partner = await joins(joiner, 'parent');

    await opens(partner, joiner);

    expect((await read(`referrals/${joiner.householdId}`))['status']).toBe('expired');
    const [line] = await historyOf(sharer.householdId);
    expect(line?.['status']).toBe('expired');
    expect(await grantsOf(sharer.householdId)).toEqual([]);
  });
});

describe('the month and the rest of premium', () => {
  beforeEach(clearFirestore);

  it('stops at six a year for the sharer, and still pays the new family', async () => {
    const sharer = await aFamily();
    const grants = adminDb().collection(`households/${sharer.householdId}/premiumGrants`);
    for (let index = 0; index < 6; index += 1) {
      await grants.doc(`old-${String(index)}`).set({
        source: 'referral',
        days: 30,
        grantedAt: Timestamp.fromMillis(Date.now() - (index + 1) * 20 * DAY_MS),
        startsAt: Timestamp.fromMillis(Date.now() - (index + 1) * 20 * DAY_MS),
      });
    }
    const joiner = await aFamily();
    await redeem(joiner, await codeOf(sharer));
    await opens(await joins(joiner, 'parent'), joiner);

    const ledger = await read(`referrals/${joiner.householdId}`);
    expect(ledger['referrerReward']).toBe('capped');
    expect(ledger['referredReward']).toBe('month');
    expect(await grantsOf(sharer.householdId)).toHaveLength(6);
    expect(await grantsOf(joiner.householdId)).toHaveLength(1);
  });

  it('waits behind a paying household"s subscription, so premium runs thirty days past it', async () => {
    const sharer = await aFamily();
    const paidUntil = new Date(Date.now() + 20 * DAY_MS);
    await adminDb()
      .doc('storePurchases/sharer-sub')
      .set({
        store: 'playStore',
        storeRef: 'token-sharer',
        productId: 'nestprep_premium_monthly',
        plan: 'monthly',
        status: 'cancelled',
        accessUntil: Timestamp.fromDate(paidUntil),
        willRenew: false,
        isTest: true,
        householdId: sharer.householdId,
        linkedByUid: sharer.admin.uid,
        linkedByMemberId: 'm-sam',
        supersededBy: null,
      });
    await adminDb()
      .doc(`households/${sharer.householdId}/entitlement/current`)
      .set({ premiumUntil: Timestamp.fromDate(paidUntil), status: 'cancelled' });
    const joiner = await aFamily();
    await redeem(joiner, await codeOf(sharer));
    await opens(await joins(joiner, 'parent'), joiner);

    const entitlement = await read(`households/${sharer.householdId}/entitlement/current`);
    expect(instant(entitlement['storeUntil'])).toEqual(paidUntil);
    expect(entitlement['referralDaysWaiting']).toBe(30);
    expect(instant(entitlement['premiumUntil'])).toEqual(
      new Date(paidUntil.getTime() + 30 * DAY_MS),
    );
    expect(entitlement['status']).toBe('cancelled');
    const [grant] = await grantsOf(sharer.householdId);
    expect(grant?.['startsAt']).toBeNull();
  });
});
