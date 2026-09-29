import { describe, expect, it } from 'vitest';

import { cohortOf, offerFor, planOfProduct } from '../../../src/subscriptions/offer';
import { readSubscriptionConfig } from '../../../src/subscriptions/subscription_config';
import { CONFIG, MONTHLY, YEARLY } from './store_fixtures';

/**
 * What premium is offered, and to which cohort (subscriptions ADR-0001).
 * Nothing configured is "not on sale yet", never an error; the cohort is the
 * same for a household every time it asks.
 */
const BARE = { androidPackage: 'io.nullstate.nestprep', iosBundleId: 'io.nullstate.nestprep' };

describe('readSubscriptionConfig', () => {
  it('has nothing on sale until both product ids are set', () => {
    expect(readSubscriptionConfig(BARE).products).toBeNull();
    expect(readSubscriptionConfig({ ...BARE, monthly: MONTHLY }).products).toBeNull();
    expect(
      readSubscriptionConfig({ ...BARE, monthly: MONTHLY, yearly: 'unset' }).products,
    ).toBeNull();
  });

  it('offers cohort b cohort a’s products unless it has its own', () => {
    const shared = readSubscriptionConfig({ ...BARE, monthly: MONTHLY, yearly: YEARLY });
    expect(shared.products?.b).toEqual({ monthly: MONTHLY, yearly: YEARLY });
    const own = readSubscriptionConfig({
      ...BARE,
      monthly: MONTHLY,
      yearly: YEARLY,
      testMonthly: 'np_monthly_b',
      testYearly: 'np_yearly_b',
    });
    expect(own.products?.b).toEqual({ monthly: 'np_monthly_b', yearly: 'np_yearly_b' });
  });

  it('asks Apple’s API only with all three parts of the key, and treats the placeholder as none', () => {
    const partial = readSubscriptionConfig({ ...BARE, appleIssuerId: 'i', appleKeyId: 'k' });
    expect(partial.appleApiKey).toBeNull();
    const placeholder = readSubscriptionConfig({
      ...BARE,
      appleIssuerId: 'i',
      appleKeyId: 'k',
      applePrivateKey: 'unset',
    });
    expect(placeholder.appleApiKey).toBeNull();
    const whole = readSubscriptionConfig({
      ...BARE,
      appleIssuerId: 'i',
      appleKeyId: 'k',
      applePrivateKey: 'pem',
    });
    expect(whole.appleApiKey).toEqual({ issuerId: 'i', keyId: 'k', privateKey: 'pem' });
  });

  it('reads the Apple app id as a number, or not at all', () => {
    expect(readSubscriptionConfig({ ...BARE, appleAppId: '1234567890' }).appleAppId).toBe(
      1234567890,
    );
    expect(readSubscriptionConfig({ ...BARE, appleAppId: 'abc' }).appleAppId).toBeNull();
  });
});

describe('offerFor', () => {
  it('says premium is not on sale when nothing is configured', () => {
    const offer = offerFor(readSubscriptionConfig(BARE), 'h1');
    expect(offer).toEqual({
      isAvailable: false,
      cohort: 'a',
      featuredPlan: 'yearly',
      products: [],
    });
  });

  it('offers both plans, yearly first, when the pricing test is off', () => {
    expect(offerFor(CONFIG, 'any-household')).toEqual({
      isAvailable: true,
      cohort: 'a',
      featuredPlan: 'yearly',
      products: [
        { productId: MONTHLY, plan: 'monthly' },
        { productId: YEARLY, plan: 'yearly' },
      ],
    });
  });

  it('splits households between the cohorts when the test is on, the same way every time', () => {
    const ids = Array.from({ length: 200 }, (_, index) => `household-${String(index)}`);
    const cohorts = ids.map((id) => cohortOf(id, true));
    expect(cohorts.filter((cohort) => cohort === 'a').length).toBeGreaterThan(60);
    expect(cohorts.filter((cohort) => cohort === 'b').length).toBeGreaterThan(60);
    expect(ids.map((id) => cohortOf(id, true))).toEqual(cohorts);

    const b = ids.find((id) => cohortOf(id, true) === 'b') ?? '';
    expect(offerFor({ ...CONFIG, isPricingTestOn: true }, b).featuredPlan).toBe('monthly');
  });
});

describe('planOfProduct', () => {
  it('names the plan of any cohort’s product, and nothing for somebody else’s', () => {
    const config = readSubscriptionConfig({
      ...BARE,
      monthly: MONTHLY,
      yearly: YEARLY,
      testYearly: 'np_yearly_b',
    });
    expect(planOfProduct(config, MONTHLY)).toBe('monthly');
    expect(planOfProduct(config, 'np_yearly_b')).toBe('yearly');
    expect(planOfProduct(config, 'com.other.app.premium')).toBeNull();
    expect(planOfProduct(readSubscriptionConfig(BARE), MONTHLY)).toBeNull();
  });
});
