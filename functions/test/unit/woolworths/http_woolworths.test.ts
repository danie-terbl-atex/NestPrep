import { describe, expect, it } from 'vitest';

import { HttpWoolworthsLogin } from '../../../src/woolworths/http_woolworths_login';
import { HttpWoolworthsShop } from '../../../src/woolworths/http_woolworths_shop';
import {
  WoolworthsRejected,
  WoolworthsSessionExpired,
  WoolworthsUnavailable,
} from '../../../src/woolworths/woolworths_api';
import type { WoolworthsAppIdentity } from '../../../src/woolworths/woolworths_config';
import type { HttpResponse } from '../../../src/shared/http_client';
import { ScriptedHttp, json } from '../calendar_sync/fakes';
import { fakeIdToken } from './fakes';

const COGNITO = { clientId: 'test-client', region: 'xx-test-1' };

const APP: WoolworthsAppIdentity = {
  apiId: 'test-api-id',
  sha1Password: 'test-sha1',
  appVersion: '0.0.1',
  os: 'TestOS',
  osVersion: '1',
  deviceVersion: 'test-maker',
  deviceModel: 'test-model',
  userAgent: 'test-agent/1',
};

const ID_TOKEN = fakeIdToken({
  email: 'sam@example.com',
  'custom:AtgId': 'atg-42',
  exp: 2_000_000_000,
});

function http(answer: (url: string, method: string) => HttpResponse): ScriptedHttp {
  return new ScriptedHttp((url, request) => answer(url, request.method));
}

const CART = {
  data: [
    {
      items: {
        foodCommerceItem: [
          { commerceItemInfo: { id: 'ci1', catalogRefId: '20011697', quantity: 2 } },
          { commerceItemInfo: { id: 'ci2', catalogRefId: 6009204330856, quantity: 1 } },
        ],
        generalCommerceItem: [
          { commerceItemInfo: { id: 'ci3', catalogRefId: '20011697', quantity: 1 } },
        ],
      },
      orderSummary: {
        total: 163.96,
        totalItemsCount: 4,
        fulfillmentDetails: {
          address: { id: 'addr-1', nickname: 'Home', placeId: 'place-1' },
          deliveryType: 'Standard',
          deliverable: true,
          fulfillmentStores: { '01': '471', '02': '2001', '07': '2002' },
          deliveryStatus: { '01': true, '02': true, '07': true },
        },
      },
    },
  ],
  response: { code: '-1', desc: 'Success' },
  httpCode: 200,
};

const PRODUCT = {
  product: {
    productId: '20011697',
    productName: 'Fresh Full Cream Milk 2 L',
    sku: '20011697',
    price: 40.99,
  },
  response: { code: '-1', desc: 'Success' },
  httpCode: 200,
};

describe('Cognito', () => {
  it('refreshes with REFRESH_TOKEN_AUTH as the public app client, in the configured region', async () => {
    const scripted = http(() =>
      json(200, {
        AuthenticationResult: { IdToken: ID_TOKEN, AccessToken: 'access', ExpiresIn: 86_400 },
      }),
    );
    const tokens = await new HttpWoolworthsLogin(scripted, COGNITO).refresh('the-refresh');
    expect(tokens).toEqual({ idToken: ID_TOKEN, refreshToken: null, expiresInSeconds: 86_400 });
    const sent = scripted.requests[0];
    expect(sent?.url).toBe('https://cognito-idp.xx-test-1.amazonaws.com/');
    expect(sent?.request.headers).toEqual({
      'Content-Type': 'application/x-amz-json-1.1',
      'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
    });
    expect(JSON.parse(sent?.request.body ?? '')).toEqual({
      AuthFlow: 'REFRESH_TOKEN_AUTH',
      ClientId: 'test-client',
      AuthParameters: { REFRESH_TOKEN: 'the-refresh' },
    });
  });

  it('a refresh token Cognito will not take is an expired session', async () => {
    const scripted = http(() =>
      json(400, { __type: 'NotAuthorizedException', message: 'Invalid Refresh Token' }),
    );
    await expect(new HttpWoolworthsLogin(scripted, COGNITO).refresh('r')).rejects.toBeInstanceOf(
      WoolworthsSessionExpired,
    );
  });

  it('throttled, failing or unreadable is unavailable, never expired', async () => {
    for (const answer of [
      json(400, { __type: 'TooManyRequestsException' }),
      json(400, { __type: 'ResourceNotFoundException' }),
      json(503, {}),
      json(200, { AuthenticationResult: {} }),
    ]) {
      await expect(
        new HttpWoolworthsLogin(
          http(() => answer),
          COGNITO,
        ).refresh('r'),
      ).rejects.toBeInstanceOf(WoolworthsUnavailable);
    }
  });
});

describe('the Dash cart', () => {
  it('reads the lines by SKU, summed, with the delivery store and totals', async () => {
    const scripted = http(() => json(200, CART));
    const cart = await new HttpWoolworthsShop(scripted, APP).readCart(ID_TOKEN);
    expect(cart).toEqual({
      storeId: '471',
      itemCount: 4,
      totalCents: 16396,
      lines: [
        { sku: '20011697', quantity: 3 },
        { sku: '6009204330856', quantity: 1 },
      ],
    });
    expect(scripted.requests[0]?.url).toBe('https://wfs-appserver.wigroup.co/wfs/app/v4/cartV2');
    expect(scripted.requests[0]?.request.method).toBe('GET');
  });

  it('sends the app identity from config, the IdToken and the member id from it, JSON even on a GET', async () => {
    const scripted = http(() => json(200, CART));
    await new HttpWoolworthsShop(scripted, APP).readCart(ID_TOKEN);
    expect(scripted.requests[0]?.request.headers).toEqual({
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'Media-Type': 'application/json',
      Sessiontoken: ID_TOKEN,
      Apiid: 'test-api-id',
      Sha1password: 'test-sha1',
      Appversion: '0.0.1',
      Os: 'TestOS',
      Osversion: '1',
      Iscognito: 'true',
      Deviceversion: 'test-maker',
      Devicemodel: 'test-model',
      Network: 'Unavailable',
      'User-Agent': 'test-agent/1',
      Dyn_user_id: 'atg-42',
    });
  });

  it('a cart with no fulfilment store has none', async () => {
    const noStore = { ...CART, data: [{ ...CART.data[0], orderSummary: { total: 0 } }] };
    const cart = await new HttpWoolworthsShop(
      http(() => json(200, noStore)),
      APP,
    ).readCart(ID_TOKEN);
    expect(cart.storeId).toBeNull();
    const noFoodStore = {
      ...CART,
      data: [
        {
          ...CART.data[0],
          orderSummary: {
            total: 0,
            fulfillmentDetails: { fulfillmentStores: { '02': '2001', '07': '2002' } },
          },
        },
      ],
    };
    const withoutFood = await new HttpWoolworthsShop(
      http(() => json(200, noFoodStore)),
      APP,
    ).readCart(ID_TOKEN);
    expect(withoutFood.storeId).toBeNull();
    const empty = await new HttpWoolworthsShop(
      http(() => json(200, { data: [] })),
      APP,
    ).readCart(ID_TOKEN);
    expect(empty).toEqual({ storeId: null, itemCount: 0, totalCents: 0, lines: [] });
  });

  it('a 401, or a session timeout in the body, is an expired session', async () => {
    for (const answer of [json(401, {}), json(200, { httpCode: 440, response: { code: '440' } })]) {
      await expect(
        new HttpWoolworthsShop(
          http(() => answer),
          APP,
        ).readCart(ID_TOKEN),
      ).rejects.toBeInstanceOf(WoolworthsSessionExpired);
    }
  });

  it('a failing or unreadable cart is unavailable', async () => {
    for (const answer of [json(502, {}), json(200, { httpCode: 500 }), json(200, { data: 'x' })]) {
      await expect(
        new HttpWoolworthsShop(
          http(() => answer),
          APP,
        ).readCart(ID_TOKEN),
      ).rejects.toBeInstanceOf(WoolworthsUnavailable);
    }
  });

  it('adds in one additive POST of SKUs with the shopper’s choice of substitute — nothing else', async () => {
    const scripted = http(() => json(200, { httpCode: 200 }));
    await new HttpWoolworthsShop(scripted, APP).addItems(ID_TOKEN, [
      { sku: '20011697', quantity: 2 },
      { sku: '6009204330856', quantity: 1 },
    ]);
    expect(scripted.requests).toHaveLength(1);
    const sent = scripted.requests[0];
    expect(sent?.url).toBe('https://wfs-appserver.wigroup.co/wfs/app/v4/cart/OnDemand/itemV2');
    expect(sent?.request.method).toBe('POST');
    expect(JSON.parse(sent?.request.body ?? '')).toEqual([
      {
        catalogRefId: '20011697',
        productId: '20011697',
        quantity: 2,
        substitutionSelection: 'SHOPPER_CHOICE',
      },
      {
        catalogRefId: '6009204330856',
        productId: '6009204330856',
        quantity: 1,
        substitutionSelection: 'SHOPPER_CHOICE',
      },
    ]);
  });

  it('an add Woolworths refuses is rejected; one it fails on is unavailable', async () => {
    const add = (answer: HttpResponse): Promise<void> =>
      new HttpWoolworthsShop(
        http(() => answer),
        APP,
      ).addItems(ID_TOKEN, [{ sku: '1234567', quantity: 1 }]);
    await expect(add(json(400, {}))).rejects.toBeInstanceOf(WoolworthsRejected);
    await expect(add(json(200, { httpCode: 422 }))).rejects.toBeInstanceOf(WoolworthsRejected);
    await expect(add(json(503, {}))).rejects.toBeInstanceOf(WoolworthsUnavailable);
    await expect(add(json(401, {}))).rejects.toBeInstanceOf(WoolworthsSessionExpired);
  });
});

describe('a product, re-priced for Dash', () => {
  it('reads its name and price in whole cents, asking for on-demand delivery', async () => {
    const scripted = http(() => json(200, PRODUCT));
    expect(await new HttpWoolworthsShop(scripted, APP).findProduct(ID_TOKEN, '20011697')).toEqual({
      sku: '20011697',
      name: 'Fresh Full Cream Milk 2 L',
      priceCents: 4099,
      isWeighed: false,
    });
    expect(scripted.requests[0]?.url).toBe(
      'https://wfs-appserver.wigroup.co/wfs/app/v4/productsV2/20011697?sku=20011697&deliveryType=OnDemand',
    );
  });

  it('is weighed when its name starts Avg or its SKU is a variable-weight code', async () => {
    const shop = (sku: string, name: string): Promise<unknown> =>
      new HttpWoolworthsShop(
        http(() => json(200, { product: { ...PRODUCT.product, productName: name } })),
        APP,
      ).findProduct(ID_TOKEN, sku);
    expect(await shop('20011697', 'Avg 1kg Beef Mince')).toMatchObject({ isWeighed: true });
    expect(await shop('2000000123456', 'Beef Mince')).toMatchObject({ isWeighed: true });
    expect(await shop('20011697', 'Avocados 4 Pack')).toMatchObject({ isWeighed: false });
  });

  it('is null when Woolworths does not know it', async () => {
    for (const answer of [
      json(404, {}),
      json(200, { httpCode: 404 }),
      json(200, { httpCode: 200 }),
    ]) {
      expect(
        await new HttpWoolworthsShop(
          http(() => answer),
          APP,
        ).findProduct(ID_TOKEN, '99900000'),
      ).toBeNull();
    }
  });
});
