import { type HttpClient, fetchHttpClient } from '../shared/http_client';
import { appleRootCertificate } from './apple/apple_root_certificate';
import { AppStoreServerApi } from './apple/app_store_server_api';
import { AppleVerifier } from './apple/apple_verifier';
import { ApplicationDefaultTokenSource } from './google/play_access_token';
import { PlayVerifier } from './google/play_verifier';
import type { BillingStore } from './purchase_state';
import type { SubscriptionConfig } from './subscription_config';
import type { VerifiedPurchase } from './verified_purchase';

/**
 * The two stores, each behind the one question every caller asks of them:
 * what is this subscription, really? Built from configuration here, and
 * replaced by fakes in every test (BE-09).
 */
export interface StoreVerifiers {
  /** What the phone handed over after a purchase or a restore. */
  verifyFromDevice(store: BillingStore, verificationData: string): Promise<VerifiedPurchase>;

  /**
   * The latest state of a subscription already on record, or null when it
   * cannot be asked for — Apple without an API key.
   */
  refresh(store: BillingStore, storeRef: string, isTest: boolean): Promise<VerifiedPurchase | null>;
}

export class LiveStoreVerifiers implements StoreVerifiers {
  readonly apple: AppleVerifier;
  private readonly play: PlayVerifier;

  constructor(config: SubscriptionConfig, http: HttpClient = fetchHttpClient) {
    const now = (): Date => new Date();
    const key = config.appleApiKey;
    this.apple = new AppleVerifier({
      config,
      roots: [appleRootCertificate()],
      api: key === null ? null : new AppStoreServerApi(key, config.iosBundleId, http, now),
      now,
    });
    this.play = new PlayVerifier(config.androidPackage, http, new ApplicationDefaultTokenSource());
  }

  verifyFromDevice(store: BillingStore, verificationData: string): Promise<VerifiedPurchase> {
    return store === 'appStore'
      ? this.apple.verifyClientTransaction(verificationData)
      : this.play.verify(verificationData);
  }

  refresh(
    store: BillingStore,
    storeRef: string,
    isTest: boolean,
  ): Promise<VerifiedPurchase | null> {
    return store === 'appStore' ? this.apple.refresh(storeRef, isTest) : this.play.verify(storeRef);
  }
}
