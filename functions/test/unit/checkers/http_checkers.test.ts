import { describe, expect, it } from 'vitest';

import {
  CheckersRefused,
  CheckersSessionExpired,
  CheckersUnavailable,
  type ShopContext,
} from '../../../src/checkers/checkers_api';
import { HttpCheckersLogin } from '../../../src/checkers/http_checkers_login';
import { HttpCheckersShop, PRODUCTS_PER_CALL } from '../../../src/checkers/http_checkers_shop';
import { HttpUnreachable, type HttpResponse } from '../../../src/shared/http_client';
import { ScriptedHttp, json } from '../calendar_sync/fakes';
import {
  APP_TOKEN,
  IDENTITY,
  MILK,
  ONE_DAY_CONTEXT,
  OTP_SENT,
  OTP_VERIFIED,
  OUT_OF_STOCK,
  PROFILE,
  STEAK,
  STORE_CONTEXT,
  cartsWith,
} from './checkers_replies';
import { ACCOUNT, APP, MOBILE, STORE } from './fakes';

/**
 * The Sixty60 adapters against canned answers shaped like Checkers' own
 * (BE-09): what each call sends, what each answer means, and which failure
 * becomes which error. Nothing here reaches the network.
 */

type Route = (url: string) => HttpResponse | undefined;

function http(...routes: Route[]): ScriptedHttp {
  return new ScriptedHttp((url) => {
    for (const route of routes) {
      const answer = route(url);
      if (answer !== undefined) return answer;
    }
    return json(404, { message: 'not scripted' });
  });
}

const on =
  (part: string, answer: HttpResponse): Route =>
  (url) =>
    url.includes(part) ? answer : undefined;

const loginRoutes = (overrides: Route[] = []): Route[] => [
  ...overrides,
  on('/token/dsl', json(200, APP_TOKEN)),
  on('dc-app-backend-for-frontend.sixty60.co.za/api/v1/users/loginbymobile', json(200, OTP_SENT)),
  on('/otp/loginbymobile/verify', json(200, OTP_VERIFIED)),
  on('shopritegroup.co.za/dsl/brands/checkers/countries/ZA/users', json(200, IDENTITY)),
  on('/customer-profile/v2/', json(200, PROFILE)),
];

describe('sending a login code', () => {
  it('asks the BFF with the free app token, and names the route', async () => {
    const scripted = http(...loginRoutes());
    const pending = await new HttpCheckersLogin(scripted, APP).requestOtp(MOBILE, 'device-1');
    expect(pending).toEqual({ mobile: MOBILE, reference: 'otp-reference-1', route: 'bff' });
    const send = scripted.requests[1];
    expect(send?.url).toContain('mobileNumber=%2B27821234567');
    expect(send?.request.headers?.['authorization']).toBe('Bearer app-jwt');
    expect(send?.request.headers?.['x-api-key']).toBeUndefined();
    expect(send?.request.headers?.['device-id']).toBe('device-1');
  });

  it('falls back to Shoprite’s own service when the BFF will not, with its key', async () => {
    const scripted = http(
      on('dc-app-backend-for-frontend.sixty60.co.za/api/v1/users/loginbymobile', json(502, {})),
      on(
        'shopritegroup.co.za/dsl/brands/checkers/countries/ZA/users/loginbymobile',
        json(200, OTP_SENT),
      ),
      ...loginRoutes(),
    );
    const pending = await new HttpCheckersLogin(scripted, APP).requestOtp(MOBILE, 'device-1');
    expect(pending.route).toBe('dsl');
    expect(scripted.requests.at(-1)?.request.headers?.['x-api-key']).toBe(APP.apiKey);
  });

  it('is refused when neither service will send to the number', async () => {
    const scripted = http(
      on('/users/loginbymobile', json(400, { error: 'unknown number' })),
      ...loginRoutes(),
    );
    await expect(new HttpCheckersLogin(scripted, APP).requestOtp(MOBILE, 'd')).rejects.toThrow(
      CheckersRefused,
    );
  });

  it('is unavailable when the app token cannot be had', async () => {
    const scripted = http(on('/token/dsl', json(503, {})));
    await expect(new HttpCheckersLogin(scripted, APP).requestOtp(MOBILE, 'd')).rejects.toThrow(
      CheckersUnavailable,
    );
  });
});

describe('verifying a login code', () => {
  const pending = { mobile: MOBILE, reference: 'otp-reference-1', route: 'bff' as const };

  it('reads the session, the three identifiers and the sixty-minute stores', async () => {
    const scripted = http(...loginRoutes());
    const account = await new HttpCheckersLogin(scripted, APP).verifyOtp(pending, '1234', 'd');
    expect(account.session).toEqual({
      token: 'SESSIONTOKEN0001',
      userId: '64aa00bb11cc22dd33ee44ff',
      uuid: 'uuid-0000-1111',
      customerId: '000TEST1',
    });
    expect(account.expiresInSeconds).toBe(3600);
    expect(account.storeContexts.map((store) => store.storeId)).toEqual([STORE_CONTEXT.storeId]);
    const verify = scripted.requests.find(({ url }) => url.includes('/verify'));
    expect(JSON.parse(verify?.request.body ?? '{}')).toEqual({
      target: { type: 'SMS', identifier: MOBILE, reference: 'otp-reference-1' },
      otp: '1234',
    });
    const identity = scripted.requests.find(({ url }) => url.endsWith('/ZA/users'));
    expect(identity?.request.headers?.['access_token']).toBe('SESSIONTOKEN0001');
    const profile = scripted.requests.find(({ url }) => url.includes('customer-profile'));
    expect(profile?.request.headers?.['authorization']).toBe(`Bearer ${APP.profileToken}`);
  });

  it('asks for stores at the default address when the profile names none', async () => {
    const noStores = { userProfile: { ...PROFILE.userProfile, storeContexts: [] } };
    const scripted = http(
      on('/customer-profile/v2/', json(200, noStores)),
      on(
        '/api/v3/store-contexts',
        json(200, { success: true, items: [ONE_DAY_CONTEXT, STORE_CONTEXT] }),
      ),
      ...loginRoutes(),
    );
    const account = await new HttpCheckersLogin(scripted, APP).verifyOtp(pending, '1234', 'd');
    expect(account.storeContexts.map((store) => store.storeId)).toEqual([STORE_CONTEXT.storeId]);
    const asked = scripted.requests.find(({ url }) => url.includes('store-contexts'));
    expect(JSON.parse(asked?.request.body ?? '{}')).toEqual({ latitude: -33.92, longitude: 18.42 });
  });

  it('is refused when the code is wrong', async () => {
    const scripted = http(on('/verify', json(400, { message: 'invalid otp' })), ...loginRoutes());
    await expect(
      new HttpCheckersLogin(scripted, APP).verifyOtp(pending, '0000', 'd'),
    ).rejects.toThrow(CheckersRefused);
  });

  it('is unavailable when the identifiers cannot be read', async () => {
    const scripted = http(
      on('/customer-profile/v2/', json(200, { userProfile: {} })),
      ...loginRoutes(),
    );
    await expect(
      new HttpCheckersLogin(scripted, APP).verifyOtp(pending, '1234', 'd'),
    ).rejects.toThrow(CheckersUnavailable);
  });
});

const context: ShopContext = { session: ACCOUNT.session, storeContexts: [STORE], deviceId: 'd' };

describe('re-reading picked products at the member’s stores', () => {
  it('reads price in cents, stock, and weighed items', async () => {
    const scripted = http(
      on('/products/filter', json(200, { products: [MILK, STEAK, OUT_OF_STOCK] })),
    );
    const found = await new HttpCheckersShop(scripted, APP).findProducts(context, [
      MILK.id,
      STEAK.id,
      OUT_OF_STOCK.id,
    ]);
    expect(found).toEqual([
      {
        productId: MILK.id,
        storeId: MILK.storeId,
        articleCode: '10136729EA',
        name: 'Clover Fresh Full Cream Milk 2L',
        priceCents: 3799,
        isInStock: true,
        isSoldByWeight: false,
      },
      expect.objectContaining({ productId: STEAK.id, isSoldByWeight: true, priceCents: 12999 }),
      expect.objectContaining({ productId: OUT_OF_STOCK.id, isInStock: false }),
    ]);
    const sent = scripted.requests[0];
    expect(JSON.parse(sent?.request.body ?? '{}')).toMatchObject({
      filter: { productListSource: { productIds: [MILK.id, STEAK.id, OUT_OF_STOCK.id] } },
      userContext: { storeContexts: [{ storeId: STORE.storeId }], userId: ACCOUNT.session.userId },
    });
    expect(sent?.request.headers).toMatchObject({
      authorization: 'Bearer session-token',
      userid: 'user-1',
      'customer-id': 'uuid-1',
      storeids: JSON.stringify([STORE.storeId]),
    });
  });

  it(`asks ${String(PRODUCTS_PER_CALL)} ids at a time, and drops products it was not asked for`, async () => {
    const scripted = http(
      on('/products/filter', json(200, { products: [MILK, { broken: true }] })),
    );
    const ids = Array.from({ length: PRODUCTS_PER_CALL + 1 }, (_, index) =>
      index.toString(16).padStart(24, '0'),
    );
    expect(await new HttpCheckersShop(scripted, APP).findProducts(context, ids)).toEqual([]);
    expect(scripted.requests).toHaveLength(2);
  });

  it('says the session is over on a 401', async () => {
    const scripted = http(on('/products/filter', json(401, {})));
    await expect(
      new HttpCheckersShop(scripted, APP).findProducts(context, [MILK.id]),
    ).rejects.toThrow(CheckersSessionExpired);
  });

  it('is unavailable on a 429, a 5xx or no answer at all', async () => {
    for (const answer of [json(429, {}), json(503, {})]) {
      const scripted = http(on('/products/filter', answer));
      await expect(
        new HttpCheckersShop(scripted, APP).findProducts(context, [MILK.id]),
      ).rejects.toThrow(CheckersUnavailable);
    }
    const unreachable = new ScriptedHttp(() => {
      throw new HttpUnreachable('TimeoutError');
    });
    await expect(
      new HttpCheckersShop(unreachable, APP).findProducts(context, [MILK.id]),
    ).rejects.toThrow(CheckersUnavailable);
  });
});

describe('the cart', () => {
  it('is the sixty-minute cart, with its lines and the discounted total', async () => {
    const scripted = http(
      on('/carts/user', json(200, cartsWith([{ id: 'l1', productId: MILK.id, quantity: 2 }]))),
    );
    const cart = await new HttpCheckersShop(scripted, APP).readCart(context);
    expect(cart).toEqual({
      cartId: 'cart-sixty',
      deliveryAddressId: 'addr-1',
      lines: [{ lineId: 'l1', productId: MILK.id, quantity: 2 }],
      totalCents: 7598,
    });
  });

  it('gets only the new lines, in the app’s shape, with an ObjectId each — never the old ones', async () => {
    const before = cartsWith([{ id: 'l1', productId: MILK.id, quantity: 1 }]);
    const after = cartsWith([
      { id: 'l1', productId: MILK.id, quantity: 1 },
      { id: 'l2', productId: OUT_OF_STOCK.id, quantity: 2 },
    ]);
    const scripted = http(
      on('/carts/user', json(200, before)),
      on('/carts/update', json(200, after)),
    );
    const shop = new HttpCheckersShop(scripted, APP);
    const cart = await shop.readCart(context);
    const updated = await shop.addLines(context, cart, [
      { productId: OUT_OF_STOCK.id, storeId: STORE.storeId, priceCents: 3799, quantity: 2 },
    ]);
    expect(updated.lines).toHaveLength(2);
    const body = JSON.parse(scripted.requests[1]?.request.body ?? '{}') as {
      carts: { id: string; serviceOptionId: string; lineItems: Record<string, unknown>[] }[];
      deliveryAddressId: string;
    };
    expect(body.deliveryAddressId).toBe('addr-1');
    expect(body.carts).toHaveLength(1);
    expect(body.carts[0]?.id).toBe('cart-sixty');
    expect(body.carts[0]?.serviceOptionId).toBe('sixty-min-delivery');
    expect(body.carts[0]?.lineItems).toEqual([
      expect.objectContaining({
        productId: OUT_OF_STOCK.id,
        quantity: 2,
        price: 3799,
        storeId: STORE.storeId,
        id: expect.stringMatching(/^[0-9a-f]{24}$/) as unknown,
      }),
    ]);
    expect(scripted.requests[1]?.url).toContain('/api/v3/carts/update');
  });

  it('is unavailable when there is no sixty-minute cart', async () => {
    const scripted = http(on('/carts/user', json(200, { carts: [] })));
    await expect(new HttpCheckersShop(scripted, APP).readCart(context)).rejects.toThrow(
      CheckersUnavailable,
    );
  });
});
