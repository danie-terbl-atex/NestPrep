import type { HttpClient, HttpRequest } from '../shared/http_client';
import {
  PnpSessionExpired,
  type CartWriteShortfall,
  type PnpCart,
  type PnpProduct,
  type PnpShop,
} from './pnp_api';
import { cartWriteShortfallOf, isExpiredToken } from './pnp_cart_write';
import { OCC_LOCALE, PNP_OCC, askPnp, readPnpReply, type PnpReply } from './pnp_request';
import {
  CART_FIELDS,
  PRODUCT_FIELDS,
  activeCartOf,
  cartOf,
  cartShape,
  cartsReply,
  occErrors,
  productOf,
  productReply,
} from './pnp_wire';

const CARTS = `${PNP_OCC}/users/current/carts`;

/**
 * The member's own cart on PnP's commerce API, as the member (add-to-pnp
 * ADR-0004). Cart only: it reads the cart, reads a product at the cart's
 * store, adds a line and sets a line's quantity. Nothing here reaches a slot,
 * a fulfilment option, a payment or an order, and nothing is ever removed.
 */
export class HttpPnpShop implements PnpShop {
  constructor(private readonly http: HttpClient) {}

  async readCart(accessToken: string): Promise<PnpCart> {
    const listed = await this.ask(
      accessToken,
      'GET',
      `${CARTS}?fields=carts(${CART_FIELDS})&refreshCart=false&${OCC_LOCALE}`,
    );
    const active = activeCartOf(readPnpReply(cartsReply, listed));
    if (active !== null) return active;
    const made = await this.ask(
      accessToken,
      'POST',
      `${CARTS}?fields=${CART_FIELDS}&${OCC_LOCALE}`,
      {},
    );
    return cartOf(readPnpReply(cartShape, made));
  }

  async findProduct(
    accessToken: string,
    storeCode: string,
    code: string,
  ): Promise<PnpProduct | null> {
    const query = `storeCode=${encodeURIComponent(storeCode)}&fields=${PRODUCT_FIELDS}&${OCC_LOCALE}`;
    const reply = await this.ask(
      accessToken,
      'GET',
      `${PNP_OCC}/products/${encodeURIComponent(code)}?${query}`,
    );
    if (reply.status === 404 || isUnknownProduct(reply)) return null;
    return productOf(readPnpReply(productReply, reply));
  }

  async addEntry(
    accessToken: string,
    cartCode: string,
    code: string,
    quantity: number,
  ): Promise<CartWriteShortfall | null> {
    // A cart write is never retried (BE-06): `add` increments.
    const reply = await this.ask(
      accessToken,
      'POST',
      `${CARTS}/${encodeURIComponent(cartCode)}/entries?${OCC_LOCALE}`,
      { product: { code }, quantity },
    );
    return cartWriteShortfallOf(reply);
  }

  async setQuantity(
    accessToken: string,
    cartCode: string,
    entryGuid: string,
    quantity: number,
  ): Promise<CartWriteShortfall | null> {
    const reply = await this.ask(
      accessToken,
      'PATCH',
      `${CARTS}/${encodeURIComponent(cartCode)}/entries/guid/${encodeURIComponent(entryGuid)}?${OCC_LOCALE}`,
      { quantity },
    );
    return cartWriteShortfallOf(reply);
  }

  private async ask(
    accessToken: string,
    method: HttpRequest['method'],
    url: string,
    body?: unknown,
  ): Promise<PnpReply> {
    const reply = await askPnp(this.http, url, {
      method,
      headers: {
        Accept: 'application/json',
        Authorization: `Bearer ${accessToken}`,
        ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
      },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
    if (isExpiredToken(reply)) throw new PnpSessionExpired();
    return reply;
  }
}

function isUnknownProduct(reply: PnpReply): boolean {
  if (reply.status !== 400) return false;
  const parsed = occErrors.safeParse(reply.body);
  return (
    parsed.success && parsed.data.errors.some((error) => error.type === 'UnknownIdentifierError')
  );
}
