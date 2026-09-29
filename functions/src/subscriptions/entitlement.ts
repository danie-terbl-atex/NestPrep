import {
  type BillingStore,
  type Plan,
  type PurchaseState,
  type PurchaseStatus,
  premiumUntil,
} from './purchase_state';

/**
 * What a household may do, decided from every store subscription linked to
 * it (subscriptions ADR-0001). Premium belongs to the household, so two
 * parents who both subscribed simply give it the later of the two dates.
 *
 * `premiumUntil` is the whole of the truth that matters: the rules compare
 * it with `request.time`, so premium lapses at its instant without a job
 * having to notice. Everything else is for the plan screen to say.
 */
export interface LinkedPurchase {
  readonly store: BillingStore;
  readonly plan: Plan | null;
  readonly state: PurchaseState;
  readonly linkedByMemberId: string | null;
}

export type EntitlementStatus = PurchaseStatus | 'none';

export interface Entitlement {
  readonly premiumUntil: Date | null;
  readonly status: EntitlementStatus;
  readonly plan: Plan | null;
  readonly store: BillingStore | null;
  readonly willRenew: boolean | null;
  /** Who bought it — the one person whose store account can manage it. */
  readonly managedByMemberId: string | null;
  readonly isTest: boolean;
}

export const FREE: Entitlement = {
  premiumUntil: null,
  status: 'none',
  plan: null,
  store: null,
  willRenew: null,
  managedByMemberId: null,
  isTest: false,
};

export function entitlementFrom(purchases: readonly LinkedPurchase[], now: Date): Entitlement {
  const granting = purchases
    .map((purchase) => ({ purchase, until: premiumUntil(purchase.state) }))
    .filter((entry) => entry.until !== null && entry.until.getTime() > now.getTime())
    .sort((a, b) => (b.until?.getTime() ?? 0) - (a.until?.getTime() ?? 0));
  const best = granting[0];
  if (best !== undefined) return describe(best.purchase, best.until);

  // Nothing gives premium now; the one that ran out last says why.
  const latest = [...purchases].sort(
    (a, b) => (b.state.accessUntil?.getTime() ?? 0) - (a.state.accessUntil?.getTime() ?? 0),
  )[0];
  return latest === undefined ? FREE : describe(latest, null);
}

function describe(purchase: LinkedPurchase, until: Date | null): Entitlement {
  return {
    premiumUntil: until,
    status: purchase.state.status,
    plan: purchase.plan,
    store: purchase.store,
    willRenew: purchase.state.willRenew,
    managedByMemberId: purchase.linkedByMemberId,
    isTest: purchase.state.isTest,
  };
}

/** The limits of the free tier (business plan, *How it makes money*). */
export const FREE_CHILD_PROFILES = 1;
