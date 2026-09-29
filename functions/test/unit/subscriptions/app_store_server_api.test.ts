import { createPublicKey, verify } from 'node:crypto';

import { describe, expect, it } from 'vitest';

import {
  APP_STORE_API_PRODUCTION,
  AppStoreServerApi,
} from '../../../src/subscriptions/apple/app_store_server_api';
import { StoreUnreachable } from '../../../src/subscriptions/verified_purchase';
import { ScriptedHttp, json, text } from '../calendar_sync/fakes';
import { BUNDLE_ID, NOW, TEST_PRIVATE_KEY } from './store_fixtures';

/**
 * Asking Apple for a subscription's status (subscriptions ADR-0001): the
 * bearer token is Apple's specified ES256 JWT, and every answer that is not a
 * status is either "not known" or "could not ask" — never a guess.
 */
const KEY = { issuerId: 'issuer-1', keyId: 'KEY123', privateKey: TEST_PRIVATE_KEY };

function api(http: ScriptedHttp): AppStoreServerApi {
  return new AppStoreServerApi(KEY, BUNDLE_ID, http, () => NOW);
}

function decode(part: string | undefined): Record<string, unknown> {
  return JSON.parse(Buffer.from(part ?? '', 'base64url').toString('utf8')) as Record<
    string,
    unknown
  >;
}

describe('AppStoreServerApi', () => {
  it('signs a five-minute ES256 token for this key, issuer and bundle', async () => {
    const http = new ScriptedHttp(() => json(200, { data: [] }));
    await api(http).latestStatus({ originalTransactionId: '1000', isSandbox: false });

    const request = http.requests[0];
    expect(request?.url).toBe(`${APP_STORE_API_PRODUCTION}/inApps/v1/subscriptions/1000`);
    const token = (request?.request.headers?.['Authorization'] ?? '').replace('Bearer ', '');
    const [header, claims, signature] = token.split('.');
    expect(decode(header)).toEqual({ alg: 'ES256', kid: 'KEY123', typ: 'JWT' });
    const issuedAt = Math.floor(NOW.getTime() / 1000);
    expect(decode(claims)).toEqual({
      iss: 'issuer-1',
      iat: issuedAt,
      exp: issuedAt + 300,
      aud: 'appstoreconnect-v1',
      bid: BUNDLE_ID,
    });
    const isSigned = verify(
      'sha256',
      Buffer.from(`${header ?? ''}.${claims ?? ''}`),
      { key: createPublicKey(TEST_PRIVATE_KEY), dsaEncoding: 'ieee-p1363' },
      Buffer.from(signature ?? '', 'base64url'),
    );
    expect(isSigned).toBe(true);
  });

  it('answers null when Apple does not know the subscription', async () => {
    const http = new ScriptedHttp(() => json(404, { errorCode: 4040010 }));
    expect(
      await api(http).latestStatus({ originalTransactionId: '1', isSandbox: true }),
    ).toBeNull();
  });

  it('says the store could not be asked when Apple refuses the key or fails', async () => {
    for (const status of [401, 429, 500]) {
      const http = new ScriptedHttp(() => json(status, {}));
      await expect(
        api(http).latestStatus({ originalTransactionId: '1', isSandbox: true }),
      ).rejects.toBeInstanceOf(StoreUnreachable);
    }
    const garbled = new ScriptedHttp(() => text(200, '<html>'));
    await expect(
      api(garbled).latestStatus({ originalTransactionId: '1', isSandbox: true }),
    ).rejects.toBeInstanceOf(StoreUnreachable);
  });

  it('treats a key that is not a key as the store being unreachable, not a crash', async () => {
    const broken = new AppStoreServerApi(
      { ...KEY, privateKey: 'not a key' },
      BUNDLE_ID,
      new ScriptedHttp(() => json(200, {})),
      () => NOW,
    );
    await expect(
      broken.latestStatus({ originalTransactionId: '1', isSandbox: true }),
    ).rejects.toBeInstanceOf(StoreUnreachable);
  });
});
