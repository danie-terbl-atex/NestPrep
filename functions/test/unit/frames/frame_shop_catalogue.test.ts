import { describe, expect, it } from 'vitest';

import type { FrameGroceries } from '../../../src/frames/frame_documents';
import {
  EmulatorFrameCatalogue,
  FrameShopUnavailable,
  HttpFrameCatalogue,
  type FrameShopProduct,
  checkersProductOf,
  pnpProductOf,
  productImageUrl,
  woolworthsProductOf,
} from '../../../src/frames/frame_shop_catalogue';
import {
  HttpUnreachable,
  type HttpClient,
  type HttpRequest,
  type HttpResponse,
} from '../../../src/shared/http_client';

/** The family's shop searched from the server for a frame (photo-frames ADR-0012). */

interface Sent {
  readonly url: string;
  readonly request: HttpRequest;
}

interface Scripted {
  readonly http: HttpClient;
  readonly sent: Sent[];
}

function scripted(answer: (url: string, request: HttpRequest) => [number, unknown]): Scripted {
  const sent: Sent[] = [];
  return {
    sent,
    http: {
      send: (url: string, request: HttpRequest): Promise<HttpResponse> => {
        sent.push({ url, request });
        const [status, body] = answer(url, request);
        return Promise.resolve({ status, body: JSON.stringify(body), location: null });
      },
    },
  };
}

const WOOLWORTHS: FrameGroceries = {
  shop: 'woolworths',
  area: 'capeTown',
  store: '2008',
  priceZone: 'p10',
};

const CHECKERS_PRODUCT = {
  id: '5f1b2c3d4e5f60718293a4b5',
  storeId: 's1',
  articleNumber: '10136729',
  unitOfMeasure: 'EA',
  priceWithoutDecimal: 3499,
  priceFactor: 100,
  displayName: ' Clover Milk 2L ',
  brand: 'Clover',
  imageId: '62a1f0',
};

const PNP_PRODUCT = {
  code: '000000000000838685_EA',
  name: 'PnP Milk 2L',
  price: { value: 29.99 },
  quantityType: 'NORMAL',
  images: [
    { format: 'thumbnail', url: 'https://cdn-prd-02.pnp.co.za/thumb/838685.jpg' },
    { format: 'carousel', url: 'https://cdn-prd-02.pnp.co.za/medias/838685.jpg' },
    { format: 'product', url: 'https://evil.example.com/838685.jpg' },
  ],
};

describe('reading a product', () => {
  it('a Checkers one in whole cents, with what a pick needs', () => {
    expect(checkersProductOf(CHECKERS_PRODUCT)).toEqual({
      retailer: 'checkers',
      productId: CHECKERS_PRODUCT.id,
      articleCode: '10136729EA',
      unitOfMeasure: 'EA',
      name: 'Clover Milk 2L',
      brand: 'Clover',
      priceCents: 3499,
      imageId: '62a1f0',
      isSoldByWeight: false,
    });
    expect(checkersProductOf({ ...CHECKERS_PRODUCT, unitOfMeasure: 'KG' })?.isSoldByWeight).toBe(
      true,
    );
  });

  it('never a Checkers one it cannot price exactly or name', () => {
    expect(checkersProductOf({ ...CHECKERS_PRODUCT, priceFactor: 3 })).toBeNull();
    expect(checkersProductOf({ ...CHECKERS_PRODUCT, displayName: ' ', name: null })).toBeNull();
    expect(checkersProductOf({ ...CHECKERS_PRODUCT, id: 'not-hex' })).toBeNull();
    expect(checkersProductOf('milk')).toBeNull();
  });

  it('a Pick n Pay one with its code digits and the CDN path only', () => {
    expect(pnpProductOf(PNP_PRODUCT)).toEqual({
      retailer: 'pickNPay',
      productId: '000000000000838685_EA',
      articleCode: '000000000000838685',
      unitOfMeasure: 'EA',
      name: 'PnP Milk 2L',
      brand: null,
      priceCents: 2999,
      imageId: 'medias/838685.jpg',
      isSoldByWeight: false,
    });
    expect(pnpProductOf({ ...PNP_PRODUCT, code: '000000000000838685_KGM' })?.isSoldByWeight).toBe(
      true,
    );
    expect(pnpProductOf({ ...PNP_PRODUCT, quantityType: 'AVERAGE_WEIGHT' })?.isSoldByWeight).toBe(
      true,
    );
    expect(pnpProductOf({ ...PNP_PRODUCT, images: [] })?.imageId).toBeNull();
    expect(pnpProductOf({ ...PNP_PRODUCT, price: { value: 29.995 } })).toBeNull();
  });
});

describe('a product’s picture', () => {
  it('is on the shop’s own host, and nowhere else', () => {
    expect(productImageUrl('checkers', 'a b')).toBe(
      'https://catalog.sixty60.co.za/v2/files/a%20b?width=300&height=300',
    );
    expect(productImageUrl('checkers', '../x')).toBe(
      'https://catalog.sixty60.co.za/v2/files/..%2Fx?width=300&height=300',
    );
    expect(productImageUrl('pickNPay', 'medias/a b.jpg')).toBe(
      'https://cdn-prd-02.pnp.co.za/medias/a%20b.jpg',
    );
    expect(productImageUrl('pickNPay', '//evil.example.com/x.jpg')).toBe(
      'https://cdn-prd-02.pnp.co.za/evil.example.com/x.jpg',
    );
    expect(productImageUrl('pickNPay', '@evil.example.com/x.jpg')).toBe(
      'https://cdn-prd-02.pnp.co.za/@evil.example.com/x.jpg',
    );
    expect(productImageUrl('checkers', null)).toBeNull();
    expect(productImageUrl('spar', 'x')).toBeNull();
  });

  it('at Woolworths, its file name and query on the asset host, asked for 200 wide', () => {
    expect(productImageUrl('woolworths', 'images/milk.jpg')).toBeNull();
    expect(productImageUrl('woolworths', 'milk.jpg')).toBe(
      'https://assets.woolworthsstatic.co.za/milk.jpg?w=200&q=85',
    );
    expect(productImageUrl('woolworths', 'milk.jpg?v=3')).toBe(
      'https://assets.woolworthsstatic.co.za/milk.jpg?v=3&w=200&q=85',
    );
    expect(productImageUrl('woolworths', 'milk.jpg?v=3&')).toBe(
      'https://assets.woolworthsstatic.co.za/milk.jpg?v=3&w=200&q=85',
    );
    expect(productImageUrl('woolworths', '@evil.example.com')).toBe(
      'https://assets.woolworthsstatic.co.za/@evil.example.com?w=200&q=85',
    );
    for (const unsafe of ['milk.jpg#x', 'milk 2l.jpg', 'x'.repeat(601), '']) {
      expect(productImageUrl('woolworths', unsafe)).toBeNull();
    }
  });
});

describe('searching Checkers', () => {
  it('asks for the stores that serve the area, then searches at them, with no credential', async () => {
    const { http, sent } = scripted((url) =>
      url.endsWith('/store-contexts')
        ? [200, { items: [{ storeId: 'c1', serviceOptionIds: ['sixty-min-delivery'] }] }]
        : [200, { products: [CHECKERS_PRODUCT, { id: 'broken' }] }],
    );
    const found = await new HttpFrameCatalogue(http).search(
      { shop: 'checkers', area: 'pretoria' },
      'milk',
      8,
    );
    expect(found.map((each) => each.productId)).toEqual([CHECKERS_PRODUCT.id]);
    expect(sent.map((each) => each.url)).toEqual([
      'https://catalog.sixty60.co.za/api/v3/store-contexts',
      'https://catalog.sixty60.co.za/api/v3/products/filter?isCarousel=false&includePromotions=true&promotionChannel=sixty60',
    ]);
    expect(JSON.parse(sent[0]?.request.body ?? '')).toEqual({
      latitude: -25.7479,
      longitude: 28.2293,
    });
    expect(JSON.parse(sent[1]?.request.body ?? '')).toMatchObject({
      filter: { productListSource: { search: 'milk' }, paginationOptions: { pageSize: 8 } },
      userContext: { storeContexts: [{ storeId: 'c1' }] },
    });
    for (const { request } of sent) {
      expect(Object.keys(request.headers ?? {})).not.toContain('authorization');
    }
  });

  it('remembers the stores for the area', async () => {
    const { http, sent } = scripted((url) =>
      url.endsWith('/store-contexts')
        ? [200, { items: [{ storeId: 'c1', serviceOptionIds: ['sixty-min-delivery'] }] }]
        : [200, { products: [] }],
    );
    const catalogue = new HttpFrameCatalogue(http);
    await catalogue.search({ shop: 'checkers', area: 'bloemfontein' }, 'milk', 8);
    await catalogue.search({ shop: 'checkers', area: 'bloemfontein' }, 'bread', 8);
    expect(sent.filter((each) => each.url.endsWith('/store-contexts'))).toHaveLength(1);
  });

  it.each([
    ['busy', [429, {}]],
    ['failing', [503, {}]],
    ['refusing', [403, {}]],
    ['unreadable', [200, { nothing: true }]],
    ['no sixty-minute store', [200, { items: [{ storeId: 'c1', serviceOptionIds: ['x'] }] }]],
  ] as const)('is unavailable when the shop is %s', async (_, reply) => {
    const { http } = scripted(() => [reply[0], reply[1]]);
    await expect(
      new HttpFrameCatalogue(http).search({ shop: 'checkers', area: 'eastLondon' }, 'milk', 8),
    ).rejects.toBeInstanceOf(FrameShopUnavailable);
  });
});

describe('searching Pick n Pay', () => {
  function pnpShop(addressStatus = 201): Scripted {
    return scripted((url, request) => {
      if (url.includes('/users/anonymous/carts?')) return [201, { guid: 'g-1' }];
      if (url.includes('/addresses/delivery')) return [addressStatus, {}];
      if (request.method === 'DELETE') return [200, {}];
      if (url.includes('/users/anonymous/carts/g-1?')) return [200, { baseStore: { uid: 'WC21' } }];
      return [200, { products: [PNP_PRODUCT] }];
    });
  }

  it('finds the store the area is priced at from a throw-away cart, then searches there', async () => {
    const { http, sent } = pnpShop();
    const found = await new HttpFrameCatalogue(http).search(
      { shop: 'pickNPay', area: 'gqeberha' },
      'full: cream',
      8,
    );
    expect(found.map((each) => each.productId)).toEqual(['000000000000838685_EA']);
    expect(sent.map((each) => each.request.method)).toEqual([
      'POST',
      'POST',
      'GET',
      'DELETE',
      'POST',
    ]);
    expect(JSON.parse(sent[1]?.request.body ?? '')).toMatchObject({
      streetname: 'Main Road',
      town: 'Gqeberha',
      postalCode: '6001',
      latitude: -33.96,
      longitude: 25.6,
    });
    const search = new URL(sent[4]?.url ?? '');
    expect(search.pathname).toBe('/pnphybris/v2/pnp-spa/products/search');
    expect(search.searchParams.get('query')).toBe('full  cream:relevance');
    expect(search.searchParams.get('storeCode')).toBe('WC21');
    expect(search.searchParams.get('curr')).toBe('ZAR');
  });

  it('is unavailable where PnP delivers nowhere, and still deletes its cart', async () => {
    const { http, sent } = pnpShop(400);
    await expect(
      new HttpFrameCatalogue(http).search({ shop: 'pickNPay', area: 'johannesburg' }, 'milk', 8),
    ).rejects.toBeInstanceOf(FrameShopUnavailable);
    expect(sent.at(-1)?.request.method).toBe('DELETE');
  });
});

const WOOLWORTHS_PRODUCT = {
  value: ' Woolworths Full Cream Milk 2L ',
  data: {
    id: '6009178001234',
    brand: ' Woolworths ',
    p10: 36.99,
    p30: 38.99,
    p60: 39.99,
    image_url: 'https://assets.woolworthsstatic.co.za/milk.jpg?v=3',
  },
};

describe('reading a Woolworths product', () => {
  it('at the price list the frame’s store reads, with its SKU as both ids', () => {
    expect(woolworthsProductOf(WOOLWORTHS_PRODUCT, 'p10')).toEqual({
      retailer: 'woolworths',
      productId: '6009178001234',
      articleCode: '6009178001234',
      unitOfMeasure: 'EA',
      name: 'Woolworths Full Cream Milk 2L',
      brand: 'Woolworths',
      priceCents: 3699,
      imageId: 'milk.jpg?v=3',
      isSoldByWeight: false,
    });
    expect(woolworthsProductOf(WOOLWORTHS_PRODUCT, 'p60')?.priceCents).toBe(3999);
  });

  it('weighed when its SKU is a variable-weight barcode or it is an average pack', () => {
    const weighed = (
      data: Record<string, unknown>,
      value = WOOLWORTHS_PRODUCT.value,
    ): FrameShopProduct | null =>
      woolworthsProductOf({ value, data: { ...WOOLWORTHS_PRODUCT.data, ...data } }, 'p30');
    expect(weighed({ id: '2001234567890', p30_kg: 129.995 })).toMatchObject({
      unitOfMeasure: 'KG',
      isSoldByWeight: true,
      priceCents: 13000,
    });
    expect(weighed({}, 'Beef Mince Avg 500 g')?.isSoldByWeight).toBe(true);
    expect(weighed({}, 'Gravy Granules')?.isSoldByWeight).toBe(false);
  });

  it('a name from the description when there is no value, and no picture from elsewhere', () => {
    const product = woolworthsProductOf(
      {
        data: {
          ...WOOLWORTHS_PRODUCT.data,
          description: 'Rooibos 80s',
          brand: ' ',
          image_url: 'https://evil.example.com/milk.jpg',
        },
      },
      'p30',
    );
    expect(product).toMatchObject({ name: 'Rooibos 80s', brand: null, imageId: null });
  });

  it.each([
    ['no SKU', { id: undefined }],
    ['a SKU too short', { id: '12345' }],
    ['a SKU with letters', { id: '60091780A' }],
    ['no price at the store’s zone', { p30: undefined }],
    ['a price it cannot read exactly', { p30: 38.995 }],
    ['a free product', { p30: 0 }],
  ])('never one with %s', (_, data) => {
    expect(
      woolworthsProductOf(
        { ...WOOLWORTHS_PRODUCT, data: { ...WOOLWORTHS_PRODUCT.data, ...data } },
        'p30',
      ),
    ).toBeNull();
  });

  it('never one without a name, or not the shape at all', () => {
    expect(woolworthsProductOf({ ...WOOLWORTHS_PRODUCT, value: '  ' }, 'p30')).toBeNull();
    expect(woolworthsProductOf({ value: 'Milk' }, 'p30')).toBeNull();
    expect(woolworthsProductOf('milk', 'p30')).toBeNull();
  });
});

describe('searching Woolworths', () => {
  it('asks Constructor alone, stocked at the frame’s store, with no credential', async () => {
    const { http, sent } = scripted(() => [
      200,
      { response: { results: [WOOLWORTHS_PRODUCT, { data: { id: 'broken' } }] } },
    ]);
    const catalogue = new HttpFrameCatalogue(http);
    const found = await catalogue.search(WOOLWORTHS, 'full cream/milk', 8);
    await catalogue.search(WOOLWORTHS, 'bread', 8);

    expect(found.map((each) => [each.productId, each.priceCents])).toEqual([
      ['6009178001234', 3699],
    ]);
    expect(sent).toHaveLength(2);
    const url = new URL(sent[0]?.url ?? '');
    expect(url.origin).toBe('https://wpkmgeuco-zone.cnstrc.com');
    expect(url.pathname).toBe('/v1/search/full%20cream%2Fmilk');
    expect(url.searchParams.get('key')).toBe('key_tw9hKe0fkfgEf36D');
    expect(url.searchParams.get('i')).toMatch(/^[0-9a-f-]{36}$/);
    expect(new URL(sent[1]?.url ?? '').searchParams.get('i')).toBe(url.searchParams.get('i'));
    expect(url.searchParams.get('s')).toBe('1');
    expect(url.searchParams.get('num_results_per_page')).toBe('8');
    expect(url.searchParams.get('page')).toBe('1');
    expect(url.searchParams.getAll('filters[visibility]')).toEqual(['all', 'web and app']);
    expect(url.searchParams.get('filters[stocked_at]')).toBe('2008');
    expect(url.searchParams.getAll('us')).toEqual(['default', 'jda_2008']);
    for (const { url: each, request } of sent) {
      expect(each).not.toContain('woolworths.co.za');
      expect(request.method).toBe('GET');
      expect(Object.keys(request.headers ?? {})).not.toContain('authorization');
    }
  });

  it.each([
    ['busy', [429, {}]],
    ['failing', [503, {}]],
    ['refusing', [403, {}]],
    ['redirecting', [302, {}]],
    ['unreadable', [200, { nothing: true }]],
  ] as const)('is unavailable when Woolworths is %s', async (_, reply) => {
    const { http } = scripted(() => [reply[0], reply[1]]);
    await expect(new HttpFrameCatalogue(http).search(WOOLWORTHS, 'milk', 8)).rejects.toBeInstanceOf(
      FrameShopUnavailable,
    );
  });

  it('and when it cannot be reached at all', async () => {
    const http: HttpClient = {
      send: () => Promise.reject(new HttpUnreachable('timeout')),
    };
    await expect(new HttpFrameCatalogue(http).search(WOOLWORTHS, 'milk', 8)).rejects.toBeInstanceOf(
      FrameShopUnavailable,
    );
  });
});

describe('the shops under the emulator', () => {
  it('answer three products named after the search, one weighed, the same each time', async () => {
    const catalogue = new EmulatorFrameCatalogue();
    const first = await catalogue.search({ shop: 'pickNPay', area: 'capeTown' }, 'milk', 8);
    expect(first.map((each) => each.isSoldByWeight)).toEqual([false, true, false]);
    expect(first[0]?.name).toBe('Milk 500 g');
    expect(first[0]?.productId).toMatch(/^[0-9]{6,20}_EA$/);
    expect(await catalogue.search({ shop: 'pickNPay', area: 'capeTown' }, 'milk', 8)).toEqual(
      first,
    );
    const checkers = await catalogue.search({ shop: 'checkers', area: 'capeTown' }, 'milk', 8);
    expect(checkers[0]?.productId).toMatch(/^[0-9a-f]{24}$/);
  });

  it('and at Woolworths, SKUs a pick accepts, the weighed one a variable-weight barcode', async () => {
    const products = await new EmulatorFrameCatalogue().search(WOOLWORTHS, 'milk', 8);
    expect(products.map((each) => each.retailer)).toEqual([
      'woolworths',
      'woolworths',
      'woolworths',
    ]);
    for (const product of products) {
      expect(product.productId).toMatch(/^[0-9]{6,14}$/);
      expect(product.articleCode).toBe(product.productId);
    }
    expect(products[1]?.productId).toMatch(/^2[0-9]{12}$/);
    expect(products.map((each) => each.unitOfMeasure)).toEqual(['EA', 'KG', 'EA']);
  });

  it('and fail like an outage for a search starting “down”', async () => {
    await expect(
      new EmulatorFrameCatalogue().search({ shop: 'checkers', area: 'capeTown' }, 'down milk', 8),
    ).rejects.toBeInstanceOf(FrameShopUnavailable);
  });
});
