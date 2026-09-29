import { describe, expect, it } from 'vitest';

import { FREE, entitlementFrom, type LinkedPurchase } from '../../../src/subscriptions/entitlement';
import {
  RENEWAL_LEEWAY_MS,
  grantsPremiumAt,
  premiumUntil,
  type PurchaseState,
} from '../../../src/subscriptions/purchase_state';
import { IN_A_MONTH, LAST_WEEK, MONTHLY, NOW, YEARLY } from './store_fixtures';

/**
 * What a household may do, from the subscriptions linked to it
 * (subscriptions ADR-0001). The rules and the Functions read only
 * `premiumUntil`, so it is the number these tests pin down.
 */
function state(overrides: Partial<PurchaseState> = {}): PurchaseState {
  return {
    status: 'active',
    accessUntil: IN_A_MONTH,
    willRenew: true,
    productId: MONTHLY,
    isTest: false,
    ...overrides,
  };
}

function linked(overrides: Partial<PurchaseState>, by = 'm-sam'): LinkedPurchase {
  return { store: 'playStore', plan: 'monthly', state: state(overrides), linkedByMemberId: by };
}

describe('premiumUntil', () => {
  it('gives an auto-renewing subscription an hour past its expiry for the renewal to arrive', () => {
    expect(premiumUntil(state())?.getTime()).toBe(IN_A_MONTH.getTime() + RENEWAL_LEEWAY_MS);
  });

  it('gives a cancelled one exactly what was paid for, and no leeway', () => {
    expect(premiumUntil(state({ status: 'cancelled', willRenew: false }))).toEqual(IN_A_MONTH);
  });

  it('gives a grace period until its end', () => {
    expect(premiumUntil(state({ status: 'inGracePeriod', willRenew: true }))).toEqual(IN_A_MONTH);
  });

  it.each(['onHold', 'paused', 'pending', 'expired', 'revoked'] as const)(
    'gives nothing while %s, whatever the date says',
    (status) => {
      expect(premiumUntil(state({ status }))).toBeNull();
      expect(grantsPremiumAt(state({ status }), NOW)).toBe(false);
    },
  );

  it('gives nothing once the paid time is over', () => {
    expect(grantsPremiumAt(state({ status: 'cancelled', accessUntil: LAST_WEEK }), NOW)).toBe(
      false,
    );
  });
});

describe('entitlementFrom', () => {
  it('is free with no subscription at all', () => {
    expect(entitlementFrom([], NOW)).toEqual(FREE);
  });

  it('is premium until the latest of two parents’ subscriptions, managed by whoever bought that one', () => {
    const later = new Date(IN_A_MONTH.getTime() + 1000 * 60 * 60 * 24 * 300);
    const entitlement = entitlementFrom(
      [
        linked({ status: 'cancelled', willRenew: false }, 'm-sam'),
        {
          ...linked({ accessUntil: later, productId: YEARLY }, 'm-mia'),
          plan: 'yearly',
          store: 'appStore',
        },
      ],
      NOW,
    );
    expect(entitlement).toMatchObject({
      premiumUntil: new Date(later.getTime() + RENEWAL_LEEWAY_MS),
      plan: 'yearly',
      store: 'appStore',
      managedByMemberId: 'm-mia',
      status: 'active',
    });
  });

  it('keeps saying why when premium has lapsed, and gives no date', () => {
    const entitlement = entitlementFrom(
      [linked({ status: 'onHold', accessUntil: LAST_WEEK, willRenew: true })],
      NOW,
    );
    expect(entitlement).toMatchObject({ premiumUntil: null, status: 'onHold', plan: 'monthly' });
  });

  it('carries whether the subscription is a store test, for the plan screen to say so', () => {
    expect(entitlementFrom([linked({ isTest: true })], NOW).isTest).toBe(true);
  });
});
