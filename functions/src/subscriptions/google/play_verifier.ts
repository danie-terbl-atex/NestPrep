import { logger } from 'firebase-functions/v2';

import {
  type HttpClient,
  type HttpResponse,
  HttpUnreachable,
  jsonOf,
} from '../../shared/http_client';
import { PurchaseRejected, StoreUnreachable, type VerifiedPurchase } from '../verified_purchase';
import type { AccessTokenSource } from './play_access_token';
import { needsAcknowledging, playState, playSubscription } from './play_subscription';

/**
 * Google Play's side of verification (subscriptions ADR-0001): a purchase
 * token is only believed once the Play Developer API, asked by our own
 * service account, says what it is. The same call answers a Real-time
 * Developer Notification and the daily reconcile — Google's notifications
 * carry no state of their own, only a token to go and ask about.
 *
 * A purchase Google says is not yet acknowledged is acknowledged here, so a
 * family is never refunded after three days because a phone went offline
 * between paying and finishing.
 */
export const ANDROID_PUBLISHER_API =
  'https://androidpublisher.googleapis.com/androidpublisher/v3/applications';

export class PlayVerifier {
  constructor(
    private readonly packageName: string,
    private readonly http: HttpClient,
    private readonly tokens: AccessTokenSource,
  ) {}

  /** The subscription behind a purchase token, or a rejection when Google does not know it. */
  async verify(purchaseToken: string): Promise<VerifiedPurchase> {
    const response = await this.request('GET', this.subscriptionUrl(purchaseToken));
    if (response.status === 404 || response.status === 410 || response.status === 400) {
      throw new PurchaseRejected(`play answered ${String(response.status)}`);
    }
    if (response.status !== 200) {
      throw new StoreUnreachable(`play answered ${String(response.status)}`);
    }
    const parsed = playSubscription.safeParse(jsonOf(response.body));
    if (!parsed.success) throw new StoreUnreachable('unexpected answer');
    const state = playState(parsed.data);
    if (needsAcknowledging(parsed.data)) await this.acknowledge(state.productId, purchaseToken);
    return {
      store: 'playStore',
      storeRef: purchaseToken,
      state,
      replaces: parsed.data.linkedPurchaseToken ?? null,
    };
  }

  /**
   * Best effort by design: the client acknowledges too when it finishes the
   * purchase, and verification has already succeeded. A failure is logged,
   * never thrown — acknowledging must not fail the write it does not own
   * (BE-09).
   */
  private async acknowledge(productId: string, purchaseToken: string): Promise<void> {
    const url =
      `${ANDROID_PUBLISHER_API}/${encodeURIComponent(this.packageName)}/purchases/subscriptions/` +
      `${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}:acknowledge`;
    try {
      const response = await this.request('POST', url, '{}');
      if (response.status !== 200 && response.status !== 204) {
        logger.warn('play acknowledge refused', { status: response.status });
      }
    } catch (error) {
      if (!(error instanceof StoreUnreachable)) throw error;
      logger.warn('play acknowledge unreachable', { why: error.why });
    }
  }

  private subscriptionUrl(purchaseToken: string): string {
    return (
      `${ANDROID_PUBLISHER_API}/${encodeURIComponent(this.packageName)}` +
      `/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`
    );
  }

  private async request(method: 'GET' | 'POST', url: string, body?: string): Promise<HttpResponse> {
    const token = await this.tokens.token();
    try {
      return await this.http.send(url, {
        method,
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        ...(body === undefined ? {} : { body }),
      });
    } catch (error) {
      if (error instanceof HttpUnreachable) throw new StoreUnreachable(error.reason);
      throw error;
    }
  }
}
