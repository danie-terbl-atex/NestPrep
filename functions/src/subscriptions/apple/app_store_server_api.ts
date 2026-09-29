import { sign } from 'node:crypto';

import { z } from 'zod';

import { type HttpClient, HttpUnreachable, jsonOf } from '../../shared/http_client';
import type { AppleApiKey } from '../subscription_config';
import { StoreUnreachable } from '../verified_purchase';

/**
 * The App Store Server API's *Get All Subscription Statuses*, which is how a
 * verification learns whether a subscription will renew and whether it is in
 * a grace period — things a single signed transaction does not say
 * (subscriptions ADR-0001). Optional: without a key, verification leans on
 * the transaction's own dates and the notifications that follow.
 *
 * The request is signed with a short-lived ES256 token made from the key
 * Daniel creates in App Store Connect; the key never leaves Secret Manager.
 */
export const APP_STORE_API_PRODUCTION = 'https://api.storekit.itunes.apple.com';
export const APP_STORE_API_SANDBOX = 'https://api.storekit-sandbox.itunes.apple.com';

/** What Apple answered for one subscription, still signed. */
export interface SignedStatus {
  readonly status: number;
  readonly signedTransactionInfo: string;
  readonly signedRenewalInfo: string | null;
}

const statusesResponse = z.object({
  data: z
    .array(
      z.object({
        lastTransactions: z
          .array(
            z.object({
              originalTransactionId: z.string(),
              status: z.number().int(),
              signedTransactionInfo: z.string(),
              signedRenewalInfo: z.string().optional(),
            }),
          )
          .default([]),
      }),
    )
    .default([]),
});

export interface AppStoreStatusRequest {
  readonly originalTransactionId: string;
  readonly isSandbox: boolean;
}

export class AppStoreServerApi {
  constructor(
    private readonly key: AppleApiKey,
    private readonly bundleId: string,
    private readonly http: HttpClient,
    private readonly now: () => Date,
  ) {}

  /** The latest signed status, or null when Apple does not know the subscription. */
  async latestStatus(request: AppStoreStatusRequest): Promise<SignedStatus | null> {
    const base = request.isSandbox ? APP_STORE_API_SANDBOX : APP_STORE_API_PRODUCTION;
    const id = encodeURIComponent(request.originalTransactionId);
    const token = this.token();
    let response;
    try {
      response = await this.http.send(`${base}/inApps/v1/subscriptions/${id}`, {
        method: 'GET',
        headers: { Authorization: `Bearer ${token}` },
      });
    } catch (error) {
      if (error instanceof HttpUnreachable) throw new StoreUnreachable(error.reason);
      throw error;
    }
    if (response.status === 404) return null;
    if (response.status !== 200) throw new StoreUnreachable(`status ${String(response.status)}`);
    const parsed = statusesResponse.safeParse(jsonOf(response.body));
    if (!parsed.success) throw new StoreUnreachable('unexpected answer');
    const match = parsed.data.data
      .flatMap((group) => group.lastTransactions)
      .find((last) => last.originalTransactionId === request.originalTransactionId);
    if (match === undefined) return null;
    return {
      status: match.status,
      signedTransactionInfo: match.signedTransactionInfo,
      signedRenewalInfo: match.signedRenewalInfo ?? null,
    };
  }

  /** A five-minute bearer token, as Apple specifies it. */
  private token(): string {
    const issuedAt = Math.floor(this.now().getTime() / 1000);
    const header = { alg: 'ES256', kid: this.key.keyId, typ: 'JWT' };
    const claims = {
      iss: this.key.issuerId,
      iat: issuedAt,
      exp: issuedAt + 300,
      aud: 'appstoreconnect-v1',
      bid: this.bundleId,
    };
    const unsigned = `${encode(header)}.${encode(claims)}`;
    let signature: Buffer;
    try {
      signature = sign('sha256', Buffer.from(unsigned), {
        // A key pasted into Secret Manager on one line keeps its newlines as
        // the two characters `\n`; the PEM parser needs them real.
        key: this.key.privateKey.replace(/\\n/g, '\n'),
        dsaEncoding: 'ieee-p1363',
      });
    } catch (error) {
      // A key that is not a PKCS#8 EC key is a configuration mistake, and
      // the purchase is still good: say the store could not be asked, so the
      // phone keeps the transaction and tries again once it is fixed.
      if (error instanceof Error) throw new StoreUnreachable('api key unreadable');
      throw error;
    }
    return `${unsigned}.${signature.toString('base64url')}`;
  }
}

function encode(value: object): string {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}
