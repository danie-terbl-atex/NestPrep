import { hash } from 'node:crypto';

import type { Plan } from './purchase_state';
import type { Cohort, SubscriptionConfig } from './subscription_config';

/**
 * What premium is offered to one household, and in which cohort of the
 * monthly-versus-yearly test (subscriptions ADR-0001).
 *
 * The cohort is derived from the household id, not stored: the same
 * household sees the same offer on every phone and every day, and nothing has
 * to be written to put it there. Cohort `a` is shown the yearly plan first,
 * cohort `b` the monthly one — and, when cohort `b` has products of its own,
 * at its own price point. The prices themselves are the stores'; the server
 * never knows a number (`ENG-20`).
 */
export interface SubscriptionOffer {
  readonly isAvailable: boolean;
  readonly cohort: Cohort;
  readonly featuredPlan: Plan;
  readonly products: readonly OfferedProduct[];
}

export interface OfferedProduct {
  readonly productId: string;
  readonly plan: Plan;
}

const FEATURED: Readonly<Record<Cohort, Plan>> = { a: 'yearly', b: 'monthly' };

export function cohortOf(householdId: string, isPricingTestOn: boolean): Cohort {
  if (!isPricingTestOn) return 'a';
  const firstByte = Number.parseInt(hash('sha256', householdId, 'hex').slice(0, 2), 16);
  return firstByte % 2 === 0 ? 'a' : 'b';
}

export function offerFor(config: SubscriptionConfig, householdId: string): SubscriptionOffer {
  const cohort = cohortOf(householdId, config.isPricingTestOn);
  const products = config.products?.[cohort];
  if (products === undefined) {
    return { isAvailable: false, cohort, featuredPlan: FEATURED[cohort], products: [] };
  }
  return {
    isAvailable: true,
    cohort,
    featuredPlan: FEATURED[cohort],
    products: [
      { productId: products.monthly, plan: 'monthly' },
      { productId: products.yearly, plan: 'yearly' },
    ],
  };
}

/**
 * Which plan a store product is, or null when it is not one of ours — a
 * receipt for somebody else's app, or a product retired from the config. The
 * cohort a purchase counts towards is the household's (`cohortOf`), not the
 * product's: two cohorts may share products and differ only in which plan
 * was shown first.
 */
export function planOfProduct(config: SubscriptionConfig, productId: string): Plan | null {
  const products = config.products;
  if (products === null) return null;
  for (const cohort of ['a', 'b'] as const) {
    for (const plan of ['monthly', 'yearly'] as const) {
      if (products[cohort][plan] === productId) return plan;
    }
  }
  return null;
}
