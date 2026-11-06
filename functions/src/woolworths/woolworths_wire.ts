import { z } from 'zod';

import type {
  WoolworthsCart,
  WoolworthsCartLine,
  WoolworthsProduct,
  WoolworthsTokens,
} from './woolworths_api';
import type { WoolworthsReply } from './woolworths_request';

export const cognitoAuthReply = z.object({
  AuthenticationResult: z.object({
    IdToken: z.string().min(1),
    RefreshToken: z.string().min(1).optional(),
    ExpiresIn: z.number().int().positive().optional(),
  }),
});

export const cognitoError = z.object({ __type: z.string() });

export const DEFAULT_ID_SECONDS = 3600;

export function tokensOf(reply: z.infer<typeof cognitoAuthReply>): WoolworthsTokens {
  const result = reply.AuthenticationResult;
  return {
    idToken: result.IdToken,
    refreshToken: result.RefreshToken ?? null,
    expiresInSeconds: result.ExpiresIn ?? DEFAULT_ID_SECONDS,
  };
}

const id = z.union([z.string().min(1), z.number()]).transform(String);
const amount = z
  .union([z.number(), z.string()])
  .transform(Number)
  .refine((value) => Number.isFinite(value) && value >= 0);

const envelope = z.object({ httpCode: z.number().int().optional() });

export function wfsCodeOf(reply: WoolworthsReply): number {
  const parsed = envelope.safeParse(reply.body);
  return parsed.success && parsed.data.httpCode !== undefined ? parsed.data.httpCode : reply.status;
}

const SESSION_CODES = new Set([401, 440]);

export function isExpiredSession(reply: WoolworthsReply): boolean {
  return reply.status === 401 || SESSION_CODES.has(wfsCodeOf(reply));
}

export const FOOD_FULFILMENT = '01';

const fulfilment = z
  .object({ fulfillmentStores: z.record(z.string(), id.nullish()).optional() })
  .optional();

const cartData = z.object({
  items: z.unknown().optional(),
  fulfillmentDetails: fulfilment,
  orderSummary: z
    .object({
      total: amount.optional(),
      totalItemsCount: z.number().int().nonnegative().optional(),
      fulfillmentDetails: fulfilment,
    })
    .optional(),
});

export const cartReply = z.object({ data: z.array(cartData) });

const commerceItem = z.object({
  quantity: z.number().int().nonnegative().optional(),
  commerceItemInfo: z.object({
    catalogRefId: id,
    quantity: z.number().int().nonnegative().optional(),
  }),
});

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function commerceItemsIn(items: unknown): unknown[] {
  const groups: unknown[] = Array.isArray(items)
    ? items
    : isRecord(items)
      ? Object.values(items)
      : [];
  return groups.flatMap((group) => {
    if (Array.isArray(group)) return group as unknown[];
    if (isRecord(group) && Array.isArray(group['commerceItems'])) {
      return group['commerceItems'] as unknown[];
    }
    return [group];
  });
}

export function cartLinesOf(items: unknown): WoolworthsCartLine[] {
  const bySku: Record<string, number> = {};
  for (const item of commerceItemsIn(items)) {
    const parsed = commerceItem.safeParse(item);
    if (!parsed.success) continue;
    const { commerceItemInfo, quantity } = parsed.data;
    const sku = commerceItemInfo.catalogRefId;
    bySku[sku] = (bySku[sku] ?? 0) + (commerceItemInfo.quantity ?? quantity ?? 0);
  }
  return Object.entries(bySku).map(([sku, count]) => ({ sku, quantity: count }));
}

export function deliveryStoreOf(data: z.infer<typeof cartData>): string | null {
  const storeId =
    data.orderSummary?.fulfillmentDetails?.fulfillmentStores?.[FOOD_FULFILMENT] ??
    data.fulfillmentDetails?.fulfillmentStores?.[FOOD_FULFILMENT];
  return storeId == null || storeId.trim() === '' ? null : storeId.trim();
}

export function cartOf(reply: z.infer<typeof cartReply>): WoolworthsCart {
  const data = reply.data[0];
  if (data === undefined) return { storeId: null, itemCount: 0, totalCents: 0, lines: [] };
  const lines = cartLinesOf(data.items);
  return {
    storeId: deliveryStoreOf(data),
    itemCount:
      data.orderSummary?.totalItemsCount ?? lines.reduce((total, line) => total + line.quantity, 0),
    totalCents: centsOf(data.orderSummary?.total ?? 0),
    lines,
  };
}

export const productReply = z.object({
  product: z
    .object({
      productName: z.string().optional(),
      productDisplayName: z.string().optional(),
      price: amount.optional(),
    })
    .optional(),
});

export function isWeighedWoolworths(sku: string, name: string): boolean {
  return /^2\d{12}$/.test(sku) || /^avg/i.test(name.trim());
}

export function productOf(
  sku: string,
  reply: z.infer<typeof productReply>,
): WoolworthsProduct | null {
  const product = reply.product;
  const name = (product?.productName ?? product?.productDisplayName ?? '').trim();
  if (product?.price === undefined || name === '') return null;
  return {
    sku,
    name,
    priceCents: centsOf(product.price),
    isWeighed: isWeighedWoolworths(sku, name),
  };
}

export function centsOf(rand: number): number {
  return Math.round(rand * 100);
}
