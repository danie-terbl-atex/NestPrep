import type { BillingStore, PurchaseState } from './purchase_state';

/**
 * A store subscription the store itself has vouched for — through a
 * signature Apple made, or an answer Google's API gave — ready to be recorded
 * and linked to a household (subscriptions ADR-0001).
 */
export interface VerifiedPurchase {
  readonly store: BillingStore;

  /**
   * The store's own name for the subscription across renewals: Apple's
   * original transaction id, or Google's purchase token. Server-only: it is
   * stored in `storePurchases`, which no client reads.
   */
  readonly storeRef: string;

  readonly state: PurchaseState;

  /**
   * An earlier purchase token this one replaces — Google's
   * `linkedPurchaseToken` after an upgrade or a resubscribe — which stops
   * giving premium so one payment is not counted twice.
   */
  readonly replaces: string | null;
}

/** Thrown by an adapter when the store's own server could not be asked. */
export class StoreUnreachable extends Error {
  constructor(readonly why: string) {
    super(`store unreachable: ${why}`);
    this.name = 'StoreUnreachable';
  }
}

/** Thrown by an adapter when what the phone sent is not a purchase of ours. */
export class PurchaseRejected extends Error {
  constructor(readonly why: string) {
    super(`purchase rejected: ${why}`);
    this.name = 'PurchaseRejected';
  }
}
