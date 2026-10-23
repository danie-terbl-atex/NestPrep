import { z } from 'zod';

import type { PnpCart, PnpClient, PnpProduct, PnpTokens } from './pnp_api';
import { PNP_LOGIN } from './pnp_request';

/**
 * PnP's answers, as far as NestPrep reads them (add-to-pnp ADR-0003,
 * ADR-0004; the facts in the vault's PnP commerce API reference). Every
 * other field PnP sends is ignored, so an addition on PnP's side breaks
 * nothing; a missing field this reads is an unreadable answer.
 */
export const configReply = z.object({
  oidc: z.object({
    clientId: z.string().min(1),
    clientSecret: z.string().min(1),
    authorizeEndpoint: z.string().startsWith(`${PNP_LOGIN}/`).optional(),
    tokenEndpoint: z.string().startsWith(`${PNP_LOGIN}/`).optional(),
  }),
});

export function pnpClientOf(reply: z.infer<typeof configReply>): PnpClient {
  const { oidc } = reply;
  return {
    clientId: oidc.clientId,
    clientSecret: oidc.clientSecret,
    authorizeEndpoint: oidc.authorizeEndpoint ?? `${PNP_LOGIN}/authorize`,
    tokenEndpoint: oidc.tokenEndpoint ?? `${PNP_LOGIN}/token`,
  };
}

export const tokenReply = z.object({
  access_token: z.string().min(1),
  refresh_token: z.string().min(1).optional(),
  expires_in: z.number().int().positive().optional(),
});

/** When PnP does not say how long an access token lasts, it is treated as five minutes. */
export const DEFAULT_ACCESS_SECONDS = 300;

export function tokensOf(reply: z.infer<typeof tokenReply>): PnpTokens {
  return {
    accessToken: reply.access_token,
    refreshToken: reply.refresh_token ?? null,
    expiresInSeconds: reply.expires_in ?? DEFAULT_ACCESS_SECONDS,
  };
}

export const oauthError = z.object({ error: z.string() });

const entryShape = z.object({
  guid: z.string().min(1),
  quantity: z.number().int().nonnegative(),
  product: z.object({ code: z.string().min(1) }),
});

export const cartShape = z.object({
  code: z.string().min(1),
  saveTime: z.string().optional(),
  totalItems: z.number().int().nonnegative().optional(),
  totalPrice: z.object({ value: z.number() }).optional(),
  baseStore: z.object({ uid: z.string().min(1) }).optional(),
  cartSizeEnabled: z
    .object({ maximumDeliveryItemsQuantity: z.number().int().positive().optional() })
    .optional(),
  entries: z.array(entryShape).optional(),
});

export const cartsReply = z.object({ carts: z.array(cartShape).optional() });

/** The fields every cart read asks for — no addresses, no payment, nothing about the member. */
export const CART_FIELDS =
  'code,saveTime,totalItems,totalPrice(value),baseStore(uid),' +
  'cartSizeEnabled(maximumDeliveryItemsQuantity),entries(guid,quantity,product(code))';

export function cartOf(raw: z.infer<typeof cartShape>): PnpCart {
  const entries = (raw.entries ?? []).map((entry) => ({
    guid: entry.guid,
    productCode: entry.product.code,
    quantity: entry.quantity,
  }));
  return {
    code: raw.code,
    storeCode: raw.baseStore?.uid ?? null,
    maxItems: raw.cartSizeEnabled?.maximumDeliveryItemsQuantity ?? null,
    itemCount: raw.totalItems ?? entries.reduce((total, entry) => total + entry.quantity, 0),
    totalCents: centsOf(raw.totalPrice?.value ?? 0),
    entries,
  };
}

/** The active cart among the member's carts: the first one not saved for later. */
export function activeCartOf(reply: z.infer<typeof cartsReply>): PnpCart | null {
  const active = (reply.carts ?? []).find((cart) => cart.saveTime === undefined);
  return active === undefined ? null : cartOf(active);
}

export const productReply = z.object({
  code: z.string().min(1),
  name: z.string().min(1),
  price: z.object({ value: z.number().nonnegative() }),
  stock: z.object({ stockLevelStatus: z.string() }).optional(),
  quantityType: z.string().optional(),
  maxOrderQuantity: z.number().int().positive().optional(),
});

export const PRODUCT_FIELDS = 'code,name,price(FULL),stock(FULL),quantityType,maxOrderQuantity';

/** Weighed codes end `_KGM`; anything not plainly counted is weighed too. */
export function productOf(raw: z.infer<typeof productReply>): PnpProduct {
  const quantityType = raw.quantityType ?? 'NORMAL';
  return {
    code: raw.code,
    name: raw.name,
    priceCents: centsOf(raw.price.value),
    isInStock: raw.stock?.stockLevelStatus !== 'outOfStock',
    isWeighed: raw.code.endsWith('_KGM') || quantityType !== 'NORMAL',
    maxOrderQuantity: raw.maxOrderQuantity ?? null,
  };
}

export const occErrors = z.object({ errors: z.array(z.object({ type: z.string() })) });

/** PnP prices are rand with cents as decimals; NestPrep's money is whole cents (ENG-20). */
export function centsOf(rand: number): number {
  return Math.round(rand * 100);
}
