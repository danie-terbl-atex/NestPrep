import { beforeEach, describe, expect, it } from 'vitest';

import { HttpPnpLogin } from '../../../src/pnp/http_pnp_login';
import { HttpPnpShop } from '../../../src/pnp/http_pnp_shop';
import {
  PnpRefused,
  PnpSessionExpired,
  PnpUnavailable,
  type PnpProduct,
} from '../../../src/pnp/pnp_api';
import { forgetPnpClient } from '../../../src/pnp/pnp_client_config';
import type { HttpResponse } from '../../../src/shared/http_client';
import { ScriptedHttp, formFields, json } from '../calendar_sync/fakes';
import { CART, CONFIG, PRODUCT, SAVED_CART, TOKENS, UNKNOWN_PRODUCT } from './pnp_replies';

/**
 * The PnP adapters against canned answers shaped like PnP's own (BE-09):
 * what each call sends, what each answer means, and which failure becomes
 * which error. Nothing here reaches the network.
 */
type Route = (url: string, method: string) => HttpResponse | undefined;

function http(...routes: Route[]): ScriptedHttp {
  return new ScriptedHttp((url, request) => {
    for (const route of routes) {
      const answer = route(url, request.method);
      if (answer !== undefined) return answer;
    }
    return json(404, { message: 'not scripted' });
  });
}

const on =
  (part: string, answer: HttpResponse, method?: string): Route =>
  (url, verb) =>
    url.includes(part) && (method === undefined || method === verb) ? answer : undefined;

const config = on('/pnp-spa/config', json(200, CONFIG));

beforeEach(() => {
  forgetPnpClient();
});

describe('the website’s client', () => {
  it('is read from PnP’s /config, and remembered', async () => {
    const scripted = http(config);
    const login = new HttpPnpLogin(scripted);
    const client = await login.client();
    await login.client();
    expect(client.clientId).toBe('storefront-test');
    expect(client.tokenEndpoint).toBe('https://login.pnp.co.za/token');
    expect(scripted.requests).toHaveLength(1);
  });

  it('a /config without the client is unreadable', async () => {
    const login = new HttpPnpLogin(http(on('/pnp-spa/config', json(200, { oidc: {} }))));
    await expect(login.client()).rejects.toBeInstanceOf(PnpUnavailable);
  });

  it('a token endpoint off login.pnp.co.za is not trusted', async () => {
    const elsewhere = { oidc: { ...CONFIG.oidc, tokenEndpoint: 'https://evil.example/token' } };
    const login = new HttpPnpLogin(http(on('/pnp-spa/config', json(200, elsewhere))));
    await expect(login.client()).rejects.toBeInstanceOf(PnpUnavailable);
  });
});

describe('the token endpoint', () => {
  it('swaps a code with its verifier, as the website’s client', async () => {
    const scripted = http(config, on('login.pnp.co.za/token', json(200, TOKENS)));
    const tokens = await new HttpPnpLogin(scripted).exchangeCode('the-code', 'the-verifier');
    expect(tokens).toEqual({
      accessToken: TOKENS.access_token,
      refreshToken: TOKENS.refresh_token,
      expiresInSeconds: 3599,
    });
    const sent = scripted.requests[1];
    expect(formFields(sent?.request.body)).toEqual({
      grant_type: 'authorization_code',
      code: 'the-code',
      redirect_uri: 'https://www.pnp.co.za/oidc_login',
      code_verifier: 'the-verifier',
    });
    const basic = Buffer.from('storefront-test:not-a-real-secret').toString('base64');
    expect(sent?.request.headers?.['Authorization']).toBe(`Basic ${basic}`);
  });

  it('a spent code is refused', async () => {
    const scripted = http(
      config,
      on('login.pnp.co.za/token', json(400, { error: 'invalid_grant', error_description: 'x' })),
    );
    await expect(new HttpPnpLogin(scripted).exchangeCode('c', 'v')).rejects.toBeInstanceOf(
      PnpRefused,
    );
  });

  it('a refresh token PnP no longer takes is an expired session', async () => {
    const scripted = http(
      config,
      on('login.pnp.co.za/token', json(401, { error: 'invalid_token', error_description: 'x' })),
    );
    await expect(new HttpPnpLogin(scripted).refresh('old')).rejects.toBeInstanceOf(
      PnpSessionExpired,
    );
  });

  it('a refused client is forgotten, so the next call reads /config again', async () => {
    const scripted = http(
      config,
      on(
        'login.pnp.co.za/token',
        json(401, { error: 'unauthorized', error_description: 'Bad credentials' }),
      ),
    );
    const login = new HttpPnpLogin(scripted);
    await expect(login.refresh('r')).rejects.toBeInstanceOf(PnpUnavailable);
    await login.client();
    expect(scripted.requests.filter((r) => r.url.includes('/config'))).toHaveLength(2);
  });

  it('a refresh with no new refresh token keeps the old one', async () => {
    const noRotation = { ...TOKENS, refresh_token: undefined };
    const scripted = http(config, on('login.pnp.co.za/token', json(200, noRotation)));
    expect((await new HttpPnpLogin(scripted).refresh('r')).refreshToken).toBeNull();
  });

  it('PnP busy is unavailable', async () => {
    const scripted = http(config, on('login.pnp.co.za/token', json(429, {})));
    await expect(new HttpPnpLogin(scripted).refresh('r')).rejects.toBeInstanceOf(PnpUnavailable);
  });
});

describe('the member’s cart', () => {
  it('reads the active cart, not one saved for later, with its store and cap', async () => {
    const scripted = http(on('/users/current/carts?', json(200, { carts: [SAVED_CART, CART] })));
    const cart = await new HttpPnpShop(scripted).readCart('access');
    expect(cart).toEqual({
      code: '0379085864',
      storeCode: 'GC13',
      maxItems: 45,
      itemCount: 3,
      totalCents: 6597,
      entries: [
        {
          guid: '00ab85b1-1aae-4ef0-97d3-11c977d667c9',
          productCode: '000000000000838685_EA',
          quantity: 3,
        },
      ],
    });
    expect(scripted.requests[0]?.request.headers?.['Authorization']).toBe('Bearer access');
  });

  it('makes a cart when the member has none', async () => {
    const scripted = http(
      on('/users/current/carts?fields=carts', json(200, { carts: [] })),
      on('/users/current/carts?fields=code', json(201, { ...CART, entries: [] }), 'POST'),
    );
    const cart = await new HttpPnpShop(scripted).readCart('access');
    expect(cart.entries).toEqual([]);
    expect(scripted.requests.map((r) => r.request.method)).toEqual(['GET', 'POST']);
  });

  it('an unauthorised answer is an expired session', async () => {
    const scripted = http(
      on('/users/current/carts', json(401, { errors: [{ type: 'InvalidTokenError' }] })),
    );
    await expect(new HttpPnpShop(scripted).readCart('a')).rejects.toBeInstanceOf(PnpSessionExpired);
  });

  it('adds a line with a POST and sets one by guid with a PATCH — nothing else', async () => {
    const scripted = http(on('/entries', json(200, { statusCode: 'success' })));
    const shop = new HttpPnpShop(scripted);
    await shop.addEntry('a', '0379085864', '000000000000838685_EA', 2);
    await shop.setQuantity('a', '0379085864', 'guid-1', 5);
    expect(scripted.requests.map((r) => [r.request.method, r.request.body])).toEqual([
      ['POST', JSON.stringify({ product: { code: '000000000000838685_EA' }, quantity: 2 })],
      ['PATCH', JSON.stringify({ quantity: 5 })],
    ]);
    expect(scripted.requests[1]?.url).toContain('/carts/0379085864/entries/guid/guid-1?');
  });

  it('a line PnP refuses with a 400 is that line’s refusal, never retried', async () => {
    const scripted = http(on('/entries', json(400, { errors: [{ type: 'CartError' }] })));
    expect(await new HttpPnpShop(scripted).addEntry('a', 'c', '000000000000838685_EA', 1)).toBe(
      'shop-refused',
    );
    expect(scripted.requests).toHaveLength(1);
  });

  it('reads what PnP did with a write, not just the status', async () => {
    const write = (body: unknown): Promise<unknown> =>
      new HttpPnpShop(http(on('/entries', json(200, body)))).addEntry('a', 'c', 'x', 3);
    expect(await write({ statusCode: 'success', quantityAdded: 3, quantity: 3 })).toBeNull();
    expect(await write({ statusCode: 'noStock', quantityAdded: 0 })).toBe('out-of-stock');
    expect(await write({ statusCode: 'lowStock', quantityAdded: 1, quantity: 1 })).toBe(
      'low-stock',
    );
    expect(await write({ statusCode: 'maxOrderQuantityExceeded', quantityAdded: 2 })).toBe(
      'max-quantity',
    );
    expect(await write({ statusCode: 'somethingNew' })).toBe('shop-refused');
  });

  it('a write PnP fails on, or answers unreadably, is unavailable', async () => {
    const shop = (answer: HttpResponse): Promise<unknown> =>
      new HttpPnpShop(http(on('/entries', answer))).setQuantity('a', 'c', 'g', 2);
    await expect(shop(json(503, {}))).rejects.toBeInstanceOf(PnpUnavailable);
    await expect(shop(json(200, ['not', 'a', 'modification']))).rejects.toBeInstanceOf(
      PnpUnavailable,
    );
  });

  it('a 403 is an expired session only when PnP says the token is the reason', async () => {
    const expired = http(
      on('/users/current/carts', json(403, { errors: [{ type: 'InvalidTokenError' }] })),
    );
    await expect(new HttpPnpShop(expired).readCart('a')).rejects.toBeInstanceOf(PnpSessionExpired);
    const forbidden = http(on('/entries', json(403, { errors: [{ type: 'ForbiddenError' }] })));
    expect(await new HttpPnpShop(forbidden).addEntry('a', 'c', 'x', 1)).toBe('shop-refused');
  });
});

describe('a product at the cart’s store', () => {
  it('reads the price in whole cents, the stock and the unit', async () => {
    const scripted = http(on('/products/000000000000838685_EA?storeCode=GC13', json(200, PRODUCT)));
    expect(await new HttpPnpShop(scripted).findProduct('a', 'GC13', PRODUCT.code)).toEqual({
      code: PRODUCT.code,
      name: PRODUCT.name,
      priceCents: 2199,
      isInStock: true,
      isWeighed: false,
      maxOrderQuantity: null,
    });
  });

  it('asks for the product’s order limit, and reads it', async () => {
    const scripted = http(on('/products/', json(200, { ...PRODUCT, maxOrderQuantity: 6 })));
    const product = await new HttpPnpShop(scripted).findProduct('a', 'GC13', PRODUCT.code);
    expect(product?.maxOrderQuantity).toBe(6);
    expect(scripted.requests[0]?.url).toContain('maxOrderQuantity');
  });

  it('out of stock, and weighed by code or by quantity type', async () => {
    const shop = (body: unknown): Promise<PnpProduct | null> =>
      new HttpPnpShop(http(on('/products/', json(200, body)))).findProduct('a', 'GC13', 'x');
    expect((await shop({ ...PRODUCT, stock: { stockLevelStatus: 'outOfStock' } }))?.isInStock).toBe(
      false,
    );
    expect((await shop({ ...PRODUCT, code: '000000000000123456_KGM' }))?.isWeighed).toBe(true);
    expect((await shop({ ...PRODUCT, quantityType: 'AVERAGE_WEIGHT' }))?.isWeighed).toBe(true);
  });

  it('a product the store does not know is null', async () => {
    const scripted = http(on('/products/', json(400, UNKNOWN_PRODUCT)));
    expect(await new HttpPnpShop(scripted).findProduct('a', 'GC13', 'x')).toBeNull();
  });
});
