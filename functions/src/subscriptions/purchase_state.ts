/**
 * One store subscription as NestPrep understands it, whichever store sold it
 * (subscriptions ADR-0001). Each store's own vocabulary — Google's
 * `SUBSCRIPTION_STATE_*`, Apple's numbered statuses and notification types —
 * is translated into this at the adapter, so nothing past it knows two stores
 * exist.
 */
export const BILLING_STORES = ['appStore', 'playStore'] as const;
export type BillingStore = (typeof BILLING_STORES)[number];

export const PLANS = ['monthly', 'yearly'] as const;
export type Plan = (typeof PLANS)[number];

/**
 * What the store says about the subscription now. Only the first three give
 * premium: `cancelled` means it will not renew but has been paid until
 * `accessUntil`, and `inGracePeriod` is the store still trying a card while
 * the family keeps what they paid for. `onHold`, `paused` and `pending` are
 * the store holding back access itself, so NestPrep does too.
 */
export const PURCHASE_STATUSES = [
  'active',
  'cancelled',
  'inGracePeriod',
  'onHold',
  'paused',
  'pending',
  'expired',
  'revoked',
] as const;
export type PurchaseStatus = (typeof PURCHASE_STATUSES)[number];

const GRANTING: readonly PurchaseStatus[] = ['active', 'cancelled', 'inGracePeriod'];

export interface PurchaseState {
  readonly status: PurchaseStatus;

  /** When what was paid for runs out — the expiry, or the grace period's end. */
  readonly accessUntil: Date | null;

  /** Null when the store has not said, which Apple does not without its API. */
  readonly willRenew: boolean | null;

  readonly productId: string;

  /** A sandbox or licence-tester purchase. */
  readonly isTest: boolean;
}

/**
 * How long past its expiry an auto-renewing subscription keeps premium while
 * the renewal is on its way to us. Both stores renew ahead of the expiry, but
 * the notification that says so can arrive minutes late, and a family should
 * not see premium blink off at midnight for that (subscriptions ADR-0001).
 */
export const RENEWAL_LEEWAY_MS = 60 * 60 * 1000;

/** Until when this subscription gives premium, or null when it gives none. */
export function premiumUntil(state: PurchaseState): Date | null {
  if (!GRANTING.includes(state.status) || state.accessUntil === null) return null;
  const leeway = state.status === 'active' && state.willRenew === true ? RENEWAL_LEEWAY_MS : 0;
  return new Date(state.accessUntil.getTime() + leeway);
}

export function grantsPremiumAt(state: PurchaseState, now: Date): boolean {
  const until = premiumUntil(state);
  return until !== null && until.getTime() > now.getTime();
}
