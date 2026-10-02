import { randomBytes } from 'node:crypto';

import type { HttpClient } from '../shared/http_client';
import {
  CheckersSessionExpired,
  CheckersUnavailable,
  SIXTY_MINUTE_DELIVERY,
  type Cart,
  type CatalogProduct,
  type CheckersShop,
  type NewCartLine,
  type ShopContext,
} from './checkers_api';
import type { CheckersAppIdentity } from './checkers_config';
import { sessionHeaders } from './checkers_headers';
import { CHECKERS_HOSTS, askCheckers, readReply, type CheckersReply } from './checkers_request';
import {
  cartsReply,
  catalogProductOf,
  productsReply,
  sixtyMinuteCart,
  storeContextWireOf,
} from './checkers_wire';

/** How many product ids one catalogue call asks for — the OSS clients' page. */
export const PRODUCTS_PER_CALL = 50;

const FILTER_PATH =
  '/api/v3/products/filter?isCarousel=false&includePromotions=true&promotionChannel=sixty60';
const CART_READ_PATH = '/api/v2/carts/user?useProductMinInfoAnnotation=true';
const CART_UPDATE_PATH = '/api/v3/carts/update?useProductMinInfoAnnotation=true';

/**
 * Shopping as the member (the Checkers build contract): each picked product
 * re-read at the member's own stores, their cart read, and new lines merged
 * into it. Cart only — nothing here reaches a slot, a checkout or a payment.
 */
export class HttpCheckersShop implements CheckersShop {
  constructor(
    private readonly http: HttpClient,
    private readonly app: CheckersAppIdentity,
  ) {}

  async findProducts(
    context: ShopContext,
    productIds: readonly string[],
  ): Promise<CatalogProduct[]> {
    const found: CatalogProduct[] = [];
    for (let start = 0; start < productIds.length; start += PRODUCTS_PER_CALL) {
      const batch = productIds.slice(start, start + PRODUCTS_PER_CALL);
      found.push(...(await this.filter(context, { productIds: batch }, batch.length)));
    }
    const asked = new Set(productIds);
    return found.filter((product) => asked.has(product.productId));
  }

  async findByArticleCode(
    context: ShopContext,
    articleCode: string,
  ): Promise<CatalogProduct | null> {
    const found = await this.filter(context, { productAUoM: articleCode }, 5);
    return found.find((product) => product.articleCode === articleCode) ?? null;
  }

  async readCart(context: ShopContext): Promise<Cart> {
    const reply = await this.post(context, `${CHECKERS_HOSTS.orders}${CART_READ_PATH}`, {
      storeContexts: context.storeContexts.map(storeContextWireOf),
    });
    const cart = sixtyMinuteCart(readReply(cartsReply, reply));
    if (cart === null) throw new CheckersUnavailable('no sixty-minute cart');
    return cart;
  }

  async addLines(context: ShopContext, cart: Cart, lines: readonly NewCartLine[]): Promise<Cart> {
    // Checkers merges the lines it is sent into the cart by line id, so only
    // the new lines go; a line already there is never re-sent, and so never
    // zeroed. A cart write is never retried (BE-06).
    const reply = await this.post(context, `${CHECKERS_HOSTS.orders}${CART_UPDATE_PATH}`, {
      carts: [
        {
          id: cart.cartId,
          serviceOptionId: SIXTY_MINUTE_DELIVERY,
          lineItems: lines.map(newLineWire),
        },
      ],
      deliveryAddressId: cart.deliveryAddressId,
      storeContexts: context.storeContexts.map(storeContextWireOf),
    });
    return sixtyMinuteCart(readReply(cartsReply, reply)) ?? this.readCart(context);
  }

  private async filter(
    context: ShopContext,
    source: Record<string, unknown>,
    pageSize: number,
  ): Promise<CatalogProduct[]> {
    const reply = await this.post(context, `${CHECKERS_HOSTS.catalog}${FILTER_PATH}`, {
      filter: {
        showAllDisplayVariants: false,
        showNotRangedProducts: false,
        productListSource: source,
        paginationOptions: { page: 0, pageSize },
      },
      userContext: {
        storeContexts: context.storeContexts.map(storeContextWireOf),
        userId: context.session.userId,
      },
    });
    const products = readReply(productsReply, reply).products ?? [];
    return products.flatMap((raw) => {
      const product = catalogProductOf(raw);
      return product === null ? [] : [product];
    });
  }

  private async post(context: ShopContext, url: string, body: unknown): Promise<CheckersReply> {
    const reply = await askCheckers(this.http, url, {
      method: 'POST',
      headers: sessionHeaders(this.app, context.deviceId, context.session, context.storeContexts),
      body: JSON.stringify(body),
    });
    if (reply.status === 401 || reply.status === 403) throw new CheckersSessionExpired();
    return reply;
  }
}

/** A Mongo-style ObjectId, as the app makes for a new line. */
export function lineObjectId(now: Date = new Date()): string {
  const seconds = Math.floor(now.getTime() / 1000)
    .toString(16)
    .padStart(8, '0');
  return seconds + randomBytes(8).toString('hex');
}

/** A new cart line in the shape the app sends (the OSS clients' capture). */
function newLineWire(line: NewCartLine): Record<string, unknown> {
  return {
    id: lineObjectId(),
    status: 'available',
    price: line.priceCents,
    priceFactor: 100,
    previousPrice: 0,
    productId: line.productId,
    instruction: '',
    quantity: line.quantity,
    specialInstruction: '',
    storeId: line.storeId,
    replacementPreferenceId: '',
    missionName: '',
    missionType: '',
    addToBasketType: 'quick_add',
    addToBasketJourney: 'cli',
    serviceOptionId: SIXTY_MINUTE_DELIVERY,
    isStockAvailable: true,
    requiresOver18: false,
    isSponsoredProduct: false,
    hasAlcohol: false,
    product: null,
  };
}
