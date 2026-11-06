import { hash, randomBytes, randomUUID } from 'node:crypto';

import { z } from 'zod';

import { CheckersUnavailable, type StoreContext } from '../checkers/checkers_api';
import { CHECKERS_HOSTS, askCheckers, readReply } from '../checkers/checkers_request';
import {
  sixtyMinuteStores,
  storeContextWireOf,
  storeContextsReply,
} from '../checkers/checkers_wire';
import { PnpUnavailable } from '../pnp/pnp_api';
import { OCC_LOCALE, PNP_OCC, askPnp, readPnpReply } from '../pnp/pnp_request';
import { runsInEmulator } from '../shared/feature_flags';
import { HttpUnreachable, fetchHttpClient, jsonOf, type HttpClient } from '../shared/http_client';
import { FRAME_AREAS, type FrameArea } from './frame_areas';
import type { FrameGroceries } from './frame_documents';
import type { FrameGroceryShop } from './frame_policy';

/**
 * The family's shop searched for a frame, from the server (photo-frames
 * ADR-0012): the unauthenticated catalogue calls the app makes on the phone
 * (add-to-checkers ADR-0003, add-to-pnp ADR-0002, add-to-woolworths
 * ADR-0002), ported so a frame, which never updates, depends on nothing a
 * shop can change under it. Woolworths' store lookup sits behind Cloudflare,
 * so the phone finds the store when the frame is saved and only the
 * Constructor search runs here. Under the emulator a script answers and
 * nothing reaches a shop.
 */

export interface FrameShopProduct {
  readonly retailer: FrameGroceryShop;
  readonly productId: string;
  readonly articleCode: string;
  readonly unitOfMeasure: string;
  readonly name: string;
  readonly brand: string | null;
  readonly priceCents: number;
  readonly imageId: string | null;
  readonly isSoldByWeight: boolean;
}

export interface FrameCatalogue {
  /** Throws [FrameShopUnavailable] when the shop fails or has no store near the frame's area. */
  search(groceries: FrameGroceries, query: string, limit: number): Promise<FrameShopProduct[]>;
}

export class FrameShopUnavailable extends Error {
  constructor(readonly reason: string) {
    super(`frame shop unavailable: ${reason}`);
    this.name = 'FrameShopUnavailable';
  }
}

const CHECKERS_IMAGE_HOST = 'catalog.sixty60.co.za';
export const PNP_IMAGE_HOST = 'cdn-prd-02.pnp.co.za';
export const WOOLWORTHS_IMAGE_HOST = 'assets.woolworthsstatic.co.za';
const WOOLWORTHS_IMAGE_PREFIX = `https://${WOOLWORTHS_IMAGE_HOST}/`;
const WOOLWORTHS_IMAGE_ID = /^[^/\s]{1,600}$/;

/** Where a shop serves a product's picture: the app's `retailerImageUrl`, and nowhere else. */
export function productImageUrl(retailer: string, imageId: string | null): string | null {
  if (imageId === null || imageId === '') return null;
  if (retailer === 'checkers') {
    return `https://${CHECKERS_IMAGE_HOST}/v2/files/${encodeURIComponent(imageId)}?width=300&height=300`;
  }
  if (retailer === 'pickNPay') {
    const url = `https://${PNP_IMAGE_HOST}/${encodeURI(imageId.replace(/^\/+/, ''))}`;
    return URL.canParse(url) && new URL(url).host === PNP_IMAGE_HOST ? url : null;
  }
  if (retailer === 'woolworths') return woolworthsImageUrl(imageId);
  return null;
}

/** The file name and query stored after Woolworths' host, joined back to it and asked for 200 wide. */
function woolworthsImageUrl(imageId: string): string | null {
  if (!WOOLWORTHS_IMAGE_ID.test(imageId)) return null;
  const separator =
    imageId.endsWith('&') || imageId.endsWith('?') ? '' : imageId.includes('?') ? '&' : '?';
  const url = `${WOOLWORTHS_IMAGE_PREFIX}${imageId}${separator}w=200&q=85`;
  if (!URL.canParse(url)) return null;
  const parsed = new URL(url);
  return parsed.host === WOOLWORTHS_IMAGE_HOST && parsed.hash === '' ? parsed.href : null;
}

/** About a kilometre, as the app keys a place: the same stores serve all of it. */
function placeKey(area: FrameArea): string {
  return `${area.latitude.toFixed(2)},${area.longitude.toFixed(2)}`;
}

const STORE_LIFETIME_MS = 60 * 60 * 1000;

interface Remembered<T> {
  readonly value: T;
  readonly until: number;
}

// Records, not Maps: `writes_are_atomic.test.ts` reads a Map's setter as a Firestore write.
const checkersStores: Record<string, Remembered<StoreContext[]> | undefined> = {};
const pnpStores: Record<string, Remembered<string> | undefined> = {};

function recalled<T>(memory: Record<string, Remembered<T> | undefined>, key: string): T | null {
  const entry = memory[key];
  return entry !== undefined && entry.until > Date.now() ? entry.value : null;
}

const CHECKERS_FILTER_PATH =
  '/api/v3/products/filter?isCarousel=false&includePromotions=true&promotionChannel=sixty60';

const checkersProductWire = z.object({
  id: z.string().regex(/^[0-9a-f]{24}$/),
  articleNumber: z.string().regex(/^[0-9A-Za-z]{1,32}$/),
  unitOfMeasure: z.string().regex(/^[A-Z0-9]{1,8}$/),
  priceWithoutDecimal: z.number().int().nonnegative(),
  priceFactor: z.number().int().positive().nullish(),
  displayName: z.string().nullish(),
  name: z.string().nullish(),
  brand: z.string().nullish(),
  imageId: z.string().nullish(),
});

const pnpProductWire = z.object({
  code: z.string().regex(/^([0-9]{6,20})_([A-Z]{2,3})$/),
  name: z.string(),
  price: z.object({ value: z.number().nonnegative() }),
  quantityType: z.string().nullish(),
  images: z.array(z.unknown()).nullish(),
});

const pnpImageWire = z.object({ format: z.string(), url: z.string() });
const pnpGuidReply = z.object({ guid: z.string().min(1) });
const pnpStoreReply = z.object({ baseStore: z.object({ uid: z.string().min(1) }) });
const productsReply = z.object({ products: z.array(z.unknown()) });

const PNP_LIST_FIELDS = 'products(code,name,price(FULL),images(DEFAULT),stock(FULL),quantityType)';
const PNP_IMAGE_FORMATS = ['carousel', 'product', 'listing'];

function nonEmpty(value: string | null | undefined): string | null {
  const trimmed = value?.trim() ?? '';
  return trimmed === '' ? null : trimmed;
}

/** A Checkers product in whole cents, or null when it cannot be read exactly (`ENG-20`). */
export function checkersProductOf(raw: unknown): FrameShopProduct | null {
  const parsed = checkersProductWire.safeParse(raw);
  if (!parsed.success) return null;
  const product = parsed.data;
  const name = nonEmpty(product.displayName) ?? nonEmpty(product.name);
  const factor = product.priceFactor ?? 100;
  const scaled = product.priceWithoutDecimal * 100;
  if (name === null || scaled % factor !== 0) return null;
  return {
    retailer: 'checkers',
    productId: product.id,
    articleCode: `${product.articleNumber}${product.unitOfMeasure}`,
    unitOfMeasure: product.unitOfMeasure,
    name: Array.from(name).slice(0, 200).join(''),
    brand: nonEmpty(product.brand)?.slice(0, 100) ?? null,
    priceCents: scaled / factor,
    imageId: nonEmpty(product.imageId)?.slice(0, 100) ?? null,
    isSoldByWeight: product.unitOfMeasure === 'KG',
  };
}

/** A Pick n Pay product in whole cents, or null when it cannot be read (`ENG-20`). */
export function pnpProductOf(raw: unknown): FrameShopProduct | null {
  const parsed = pnpProductWire.safeParse(raw);
  if (!parsed.success) return null;
  const product = parsed.data;
  const [, digits = '', unit = ''] = /^([0-9]{6,20})_([A-Z]{2,3})$/.exec(product.code) ?? [];
  const name = nonEmpty(product.name);
  const cents = product.price.value * 100;
  const isSoldByWeight =
    unit === 'KGM' || (product.quantityType != null && product.quantityType !== 'NORMAL');
  if (name === null || (!isSoldByWeight && Math.abs(cents - Math.round(cents)) >= 0.0001)) {
    return null;
  }
  return {
    retailer: 'pickNPay',
    productId: product.code,
    articleCode: digits,
    unitOfMeasure: unit,
    name: Array.from(name).slice(0, 200).join(''),
    brand: null,
    priceCents: Math.round(cents),
    imageId: pnpImagePath(product.images ?? []),
    isSoldByWeight,
  };
}

/** The picture's path on PnP's CDN, without its leading `/`, as the app stores it. */
function pnpImagePath(images: readonly unknown[]): string | null {
  const byFormat: Record<string, string> = {};
  for (const entry of images) {
    const image = pnpImageWire.safeParse(entry);
    if (!image.success || !URL.canParse(image.data.url)) continue;
    const url = new URL(image.data.url);
    if (url.host !== PNP_IMAGE_HOST || url.pathname.length < 2) continue;
    byFormat[image.data.format] ??= url.pathname.slice(1);
  }
  const preferred = PNP_IMAGE_FORMATS.map((format) => byFormat[format]).find(Boolean);
  const path = preferred ?? Object.values(byFormat)[0] ?? null;
  return path === null || path.length > 300 ? null : path;
}

const WOOLWORTHS_SEARCH_HOST = 'https://wpkmgeuco-zone.cnstrc.com';
const WOOLWORTHS_SEARCH_KEY = 'key_tw9hKe0fkfgEf36D';
const WOOLWORTHS_SKU = /^[0-9]{6,14}$/;
const WOOLWORTHS_VARIABLE_WEIGHT_SKU = /^2[0-9]{12}$/;
const WOOLWORTHS_AVERAGE_WEIGHT = /\bavg\b/i;

const woolworthsResult = z.object({
  value: z.string().nullish(),
  data: z.record(z.string(), z.unknown()),
});
const woolworthsReply = z.object({ response: z.object({ results: z.array(z.unknown()) }) });

type WoolworthsPriceZone = Extract<FrameGroceries, { shop: 'woolworths' }>['priceZone'];

function woolworthsText(value: unknown): string | null {
  return typeof value === 'string' ? nonEmpty(value) : null;
}

/** Cents from Woolworths' rand: exact to the cent or nothing (`ENG-20`), except a weighed product's. */
function woolworthsCents(rand: unknown, isSoldByWeight: boolean): number | null {
  if (typeof rand !== 'number' || !Number.isFinite(rand) || rand <= 0) return null;
  const cents = rand * 100;
  const whole = Math.round(cents);
  return isSoldByWeight || Math.abs(cents - whole) < 0.0001 ? whole : null;
}

/** The file name and query after Woolworths' image host, or null when it is elsewhere or unsafe to store. */
function woolworthsImageId(imageUrl: unknown): string | null {
  if (typeof imageUrl !== 'string' || !imageUrl.startsWith(WOOLWORTHS_IMAGE_PREFIX)) return null;
  const id = imageUrl.slice(WOOLWORTHS_IMAGE_PREFIX.length);
  return WOOLWORTHS_IMAGE_ID.test(id) ? id : null;
}

/** A Woolworths product at [priceZone]'s price, the app's `WoolworthsCatalogueParser` ported. */
export function woolworthsProductOf(
  raw: unknown,
  priceZone: WoolworthsPriceZone,
): FrameShopProduct | null {
  const parsed = woolworthsResult.safeParse(raw);
  if (!parsed.success) return null;
  const { data } = parsed.data;
  const sku = data.id;
  const name = woolworthsText(parsed.data.value ?? data.description);
  if (typeof sku !== 'string' || !WOOLWORTHS_SKU.test(sku) || name === null) return null;
  const isSoldByWeight =
    WOOLWORTHS_VARIABLE_WEIGHT_SKU.test(sku) || WOOLWORTHS_AVERAGE_WEIGHT.test(name);
  const price = woolworthsCents(
    isSoldByWeight ? (data[`${priceZone}_kg`] ?? data[priceZone]) : data[priceZone],
    isSoldByWeight,
  );
  if (price === null) return null;
  return {
    retailer: 'woolworths',
    productId: sku,
    articleCode: sku,
    unitOfMeasure: isSoldByWeight ? 'KG' : 'EA',
    name: Array.from(name).slice(0, 200).join(''),
    brand: woolworthsText(data.brand)?.slice(0, 100) ?? null,
    priceCents: price,
    imageId: woolworthsImageId(data.image_url),
    isSoldByWeight,
  };
}

/** The catalogues over HTTPS, with no credential of any kind. */
export class HttpFrameCatalogue implements FrameCatalogue {
  private readonly deviceId = randomBytes(16).toString('hex');
  private readonly visitorId = randomUUID();

  constructor(private readonly http: HttpClient) {}

  async search(
    groceries: FrameGroceries,
    query: string,
    limit: number,
  ): Promise<FrameShopProduct[]> {
    const area = FRAME_AREAS[groceries.area];
    try {
      switch (groceries.shop) {
        case 'checkers':
          return await this.searchCheckers(area, query, limit);
        case 'pickNPay':
          return await this.searchPnp(area, query, limit);
        case 'woolworths':
          return await this.searchWoolworths(groceries.store, groceries.priceZone, query, limit);
      }
    } catch (error) {
      if (
        error instanceof CheckersUnavailable ||
        error instanceof PnpUnavailable ||
        error instanceof HttpUnreachable
      ) {
        throw new FrameShopUnavailable(error.reason);
      }
      throw error;
    }
  }

  private checkersHeaders(): Record<string, string> {
    return {
      'content-type': 'application/json',
      accept: 'application/json',
      channel: 'super-app',
      'device-id': this.deviceId,
    };
  }

  private async checkersStoresNear(area: FrameArea): Promise<StoreContext[]> {
    const key = placeKey(area);
    const known = recalled(checkersStores, key);
    if (known !== null) return known;
    const reply = await askCheckers(this.http, `${CHECKERS_HOSTS.catalog}/api/v3/store-contexts`, {
      method: 'POST',
      headers: this.checkersHeaders(),
      body: JSON.stringify({ latitude: area.latitude, longitude: area.longitude }),
    });
    const stores = sixtyMinuteStores(readReply(storeContextsReply, reply).items);
    if (stores.length === 0) throw new FrameShopUnavailable('no checkers store');
    checkersStores[key] = { value: stores, until: Date.now() + STORE_LIFETIME_MS };
    return stores;
  }

  private async searchCheckers(
    area: FrameArea,
    query: string,
    limit: number,
  ): Promise<FrameShopProduct[]> {
    const stores = await this.checkersStoresNear(area);
    const reply = await askCheckers(this.http, `${CHECKERS_HOSTS.catalog}${CHECKERS_FILTER_PATH}`, {
      method: 'POST',
      headers: this.checkersHeaders(),
      body: JSON.stringify({
        filter: {
          showAllDisplayVariants: false,
          showNotRangedProducts: false,
          productListSource: { search: query },
          paginationOptions: { page: 0, pageSize: limit },
        },
        userContext: { storeContexts: stores.map(storeContextWireOf) },
      }),
    });
    return readReply(productsReply, reply).products.flatMap((raw) => {
      const product = checkersProductOf(raw);
      return product === null ? [] : [product];
    });
  }

  private async pnp(
    method: 'GET' | 'POST' | 'DELETE',
    path: string,
    body?: unknown,
  ): Promise<{ status: number; body: unknown }> {
    const separator = path.includes('?') ? '&' : '?';
    return askPnp(this.http, `${PNP_OCC}${path}${separator}${OCC_LOCALE}`, {
      method,
      headers: { accept: 'application/json', 'content-type': 'application/json' },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
  }

  /** The store PnP prices the area at, from a throw-away anonymous cart (add-to-pnp ADR-0002). */
  private async pnpStoreNear(area: FrameArea): Promise<string> {
    const key = placeKey(area);
    const known = recalled(pnpStores, key);
    if (known !== null) return known;
    const { guid } = readPnpReply(
      pnpGuidReply,
      await this.pnp('POST', '/users/anonymous/carts?fields=guid', {}),
    );
    const cart = `/users/anonymous/carts/${encodeURIComponent(guid)}`;
    try {
      const address = await this.pnp('POST', `${cart}/addresses/delivery`, {
        streetnumber: '1',
        streetname: 'Main Road',
        line2: '1 Main Road',
        district: area.label,
        town: area.label,
        postalCode: area.postalCode,
        latitude: Number(area.latitude.toFixed(2)),
        longitude: Number(area.longitude.toFixed(2)),
        country: { isocode: 'ZA' },
        defaultAddress: false,
      });
      if (address.status === 400) throw new FrameShopUnavailable('no pnp store');
      if (address.status < 200 || address.status >= 300) {
        throw new FrameShopUnavailable(`pnp address ${String(address.status)}`);
      }
      const store = readPnpReply(
        pnpStoreReply,
        await this.pnp('GET', `${cart}?fields=baseStore(uid)`),
      ).baseStore.uid;
      pnpStores[key] = { value: store, until: Date.now() + STORE_LIFETIME_MS };
      return store;
    } finally {
      await this.pnp('DELETE', cart).catch(() => undefined);
    }
  }

  private async searchPnp(
    area: FrameArea,
    query: string,
    limit: number,
  ): Promise<FrameShopProduct[]> {
    const store = await this.pnpStoreNear(area);
    const search = new URLSearchParams({
      query: `${query.replaceAll(':', ' ')}:relevance`,
      storeCode: store,
      pageSize: String(limit),
      currentPage: '0',
      fields: PNP_LIST_FIELDS,
    });
    const reply = await this.pnp('POST', `/products/search?${search.toString()}`, {});
    return readPnpReply(productsReply, reply).products.flatMap((raw) => {
      const product = pnpProductOf(raw);
      return product === null ? [] : [product];
    });
  }

  /** Constructor's search stocked at the store the phone found; never Woolworths' own `/server/*`. */
  private async searchWoolworths(
    store: string,
    priceZone: WoolworthsPriceZone,
    query: string,
    limit: number,
  ): Promise<FrameShopProduct[]> {
    const search = new URLSearchParams([
      ['key', WOOLWORTHS_SEARCH_KEY],
      ['i', this.visitorId],
      ['s', '1'],
      ['num_results_per_page', String(limit)],
      ['page', '1'],
      ['filters[visibility]', 'all'],
      ['filters[visibility]', 'web and app'],
      ['filters[stocked_at]', store],
      ['us', 'default'],
      ['us', `jda_${store}`],
    ]);
    const response = await this.http.send(
      `${WOOLWORTHS_SEARCH_HOST}/v1/search/${encodeURIComponent(query)}?${search.toString()}`,
      { method: 'GET', headers: { accept: 'application/json' } },
    );
    if (response.status < 200 || response.status >= 300) {
      throw new FrameShopUnavailable(`woolworths status ${String(response.status)}`);
    }
    const reply = woolworthsReply.safeParse(jsonOf(response.body));
    if (!reply.success) throw new FrameShopUnavailable('woolworths unreadable');
    return reply.data.response.results.flatMap((raw) => {
      const product = woolworthsProductOf(raw, priceZone);
      return product === null ? [] : [product];
    });
  }
}

/**
 * The shops under the emulator: a query starting `down` fails as an outage
 * would; any other answers three products named after it, the second sold
 * by weight, at R19.99 upwards. Ids are stable per query.
 */
export class EmulatorFrameCatalogue implements FrameCatalogue {
  search({ shop }: FrameGroceries, query: string, limit: number): Promise<FrameShopProduct[]> {
    if (query.toLowerCase().startsWith('down')) {
      return Promise.reject(new FrameShopUnavailable('emulator outage'));
    }
    const title = query.charAt(0).toUpperCase() + query.slice(1);
    const products = [0, 1, 2].map((index): FrameShopProduct => {
      const digest = hash('sha256', `${shop}:${query.toLowerCase()}:${String(index)}`, 'hex');
      const weighed = index === 1;
      const digits = String(BigInt(`0x${digest.slice(0, 12)}`))
        .padStart(18, '0')
        .slice(0, 18);
      const unit = weighed ? (shop === 'pickNPay' ? 'KGM' : 'KG') : 'EA';
      const ids = emulatorIds(shop, digest, digits, unit, weighed);
      return {
        retailer: shop,
        ...ids,
        unitOfMeasure: unit,
        name: `${title} ${['500 g', 'per kg', 'family pack'][index] ?? ''}`.trim(),
        brand: index === 2 ? null : 'Emulator',
        priceCents: 1999 + index * 1000,
        imageId: null,
        isSoldByWeight: weighed,
      };
    });
    return Promise.resolve(products.slice(0, limit));
  }
}

function emulatorIds(
  shop: FrameGroceryShop,
  digest: string,
  digits: string,
  unit: string,
  weighed: boolean,
): { productId: string; articleCode: string } {
  switch (shop) {
    case 'checkers':
      return { productId: digest.slice(0, 24), articleCode: `${digits.slice(-8)}${unit}` };
    case 'pickNPay':
      return { productId: `${digits}_${unit}`, articleCode: digits };
    case 'woolworths': {
      const sku = weighed ? `2${digits.slice(-12)}` : `6009${digits.slice(-9)}`;
      return { productId: sku, articleCode: sku };
    }
  }
}

/** The real shops in the cloud; the script under the emulator. */
export function frameCatalogueHere(): FrameCatalogue {
  return runsInEmulator() ? new EmulatorFrameCatalogue() : new HttpFrameCatalogue(fetchHttpClient);
}
