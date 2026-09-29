import type { z } from 'zod';

import type { SubscriptionConfig } from '../subscription_config';
import { PurchaseRejected, type VerifiedPurchase } from '../verified_purchase';
import type { AppStoreServerApi } from './app_store_server_api';
import {
  type AppleRecords,
  type AppStoreRenewal,
  type AppStoreTransaction,
  appStoreNotification,
  appStoreRenewal,
  appStoreTransaction,
  appleState,
} from './app_store_records';
import { SignedPayloadInvalid, verifySignedPayload } from './signed_payload';

/**
 * Everything the App Store tells NestPrep, checked before it is believed
 * (subscriptions ADR-0001): a transaction the phone hands over after a
 * purchase or a restore, a Server Notification v2, and — when the API key is
 * configured — the latest status asked for by original transaction id.
 */
export interface AppleVerifierOptions {
  readonly config: SubscriptionConfig;
  /** DER roots a chain may end in: Apple Root CA - G3 in production. */
  readonly roots: readonly Buffer[];
  readonly api: AppStoreServerApi | null;
  readonly now: () => Date;
}

/** What one notification means for NestPrep. */
export type AppleNotificationOutcome =
  | { readonly kind: 'purchase'; readonly purchase: VerifiedPurchase; readonly type: string }
  | { readonly kind: 'ignored'; readonly type: string };

/** Notification types that take back what was bought. */
const TAKEN_BACK = ['REFUND', 'REVOKE'];
const REVOKED_STATUS = 5;

export class AppleVerifier {
  constructor(private readonly options: AppleVerifierOptions) {}

  async verifyClientTransaction(signedTransaction: string): Promise<VerifiedPurchase> {
    const transaction = this.transaction(signedTransaction);
    const latest = await this.options.api?.latestStatus({
      originalTransactionId: transaction.originalTransactionId,
      isSandbox: transaction.environment !== 'Production',
    });
    if (latest === undefined || latest === null) {
      return this.purchaseOf({ transaction, renewal: null, status: null });
    }
    return this.purchaseOf({
      transaction: this.transaction(latest.signedTransactionInfo),
      renewal: this.renewal(latest.signedRenewalInfo),
      status: latest.status,
    });
  }

  verifyNotification(signedPayload: string): AppleNotificationOutcome {
    const notification = this.signed(signedPayload, appStoreNotification);
    const data = notification.data;
    const type = notification.notificationType;
    if (data === undefined || data.signedTransactionInfo === undefined) {
      return { kind: 'ignored', type };
    }
    this.checkApp(data.bundleId, data.environment, data.appAppleId);
    const isTakenBack = TAKEN_BACK.includes(type);
    return {
      kind: 'purchase',
      type,
      purchase: this.purchaseOf({
        transaction: this.transaction(data.signedTransactionInfo),
        renewal: this.renewal(data.signedRenewalInfo ?? null),
        status: isTakenBack ? REVOKED_STATUS : (data.status ?? null),
      }),
    };
  }

  /** The latest state of a known subscription, or null without an API key. */
  async refresh(
    originalTransactionId: string,
    isSandbox: boolean,
  ): Promise<VerifiedPurchase | null> {
    const api = this.options.api;
    if (api === null) return null;
    const latest = await api.latestStatus({ originalTransactionId, isSandbox });
    if (latest === null) return null;
    return this.purchaseOf({
      transaction: this.transaction(latest.signedTransactionInfo),
      renewal: this.renewal(latest.signedRenewalInfo),
      status: latest.status,
    });
  }

  private purchaseOf(records: AppleRecords): VerifiedPurchase {
    return {
      store: 'appStore',
      storeRef: records.transaction.originalTransactionId,
      state: appleState(records, this.options.now()),
      replaces: null,
    };
  }

  private transaction(jws: string): AppStoreTransaction {
    const transaction = this.signed(jws, appStoreTransaction);
    this.checkApp(transaction.bundleId, transaction.environment, undefined);
    return transaction;
  }

  private renewal(jws: string | null): AppStoreRenewal | null {
    return jws === null ? null : this.signed(jws, appStoreRenewal);
  }

  private signed<T extends z.ZodType>(jws: string, schema: T): z.infer<T> {
    let payload: unknown;
    try {
      payload = verifySignedPayload(jws, { roots: this.options.roots, now: this.options.now() });
    } catch (error) {
      if (error instanceof SignedPayloadInvalid) throw new PurchaseRejected(error.why);
      throw error;
    }
    const parsed = schema.safeParse(payload);
    if (!parsed.success) throw new PurchaseRejected('unexpected payload');
    return parsed.data;
  }

  /** A record for another app, or a production one for another Apple ID, is not ours. */
  private checkApp(bundleId: string, environment: string, appAppleId: number | undefined): void {
    const config = this.options.config;
    if (bundleId !== config.iosBundleId) throw new PurchaseRejected('another app');
    const expected = config.appleAppId;
    if (environment === 'Production' && expected !== null && appAppleId !== undefined) {
      if (appAppleId !== expected) throw new PurchaseRejected('another app id');
    }
  }
}
