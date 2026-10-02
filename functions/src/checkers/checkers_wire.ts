import { z } from 'zod';

import {
  SIXTY_MINUTE_DELIVERY,
  type Cart,
  type CatalogProduct,
  type StoreContext,
} from './checkers_api';

/**
 * What Checkers answers, read into typed shapes at the edge and never cast
 * (ENG-09). Only the fields Add to Checkers uses are read; the rest is left
 * behind, so a field Checkers adds or renames elsewhere changes nothing here.
 * Shapes are the OSS clients' captures and the live probe of 2026-09-30.
 */

export const appTokenReply = z.object({ access_token: z.string().min(1) });

export const otpSentReply = z.object({
  response: z.object({ reference: z.string().min(1) }),
});

export const otpVerifiedReply = z.object({
  response: z.object({
    accessToken: z.string().min(1),
    expiresIn: z.number().optional(),
  }),
});

export const identityReply = z.object({
  response: z.object({
    user: z.object({ uuid: z.string().min(1), customerId: z.string().min(1) }),
  }),
});

const storeContextWire = z.object({
  storeId: z.string().min(1),
  serviceOptionIds: z.array(z.string()).nullish(),
  hasCapacity: z.array(z.string()).nullish(),
  brandPriority: z.number().nullish(),
  distanceFromCustomer: z.number().nullish(),
});

const addressWire = z.object({
  coordinates: z.object({ latitude: z.number(), longitude: z.number() }).nullish(),
  isDefault: z.boolean().nullish(),
});

export const profileReply = z.object({
  userProfile: z.object({
    id: z.string().min(1),
    storeContexts: z.array(z.unknown()).nullish(),
    addresses: z.array(z.unknown()).nullish(),
  }),
});

export const storeContextsReply = z.object({ items: z.array(z.unknown()).nullish() });

export const productsReply = z.object({ products: z.array(z.unknown()).nullish() });

const productWire = z.object({
  id: z.string().regex(/^[0-9a-f]{24}$/),
  storeId: z.string().min(1),
  articleNumber: z.string().nullish(),
  unitOfMeasure: z.string().nullish(),
  name: z.string().nullish(),
  displayName: z.string().nullish(),
  priceWithoutDecimal: z.number().nullish(),
  price: z.number().nullish(),
  priceFactor: z.number().positive().nullish(),
  isStockAvailable: z.boolean().nullish(),
  sellByWeight: z.boolean().nullish(),
  isVariableWeight: z.boolean().nullish(),
  variableWeightOptions: z.array(z.unknown()).nullish(),
});

const cartLineWire = z.object({
  id: z.string().min(1),
  productId: z.string().min(1),
  quantity: z.number(),
  price: z.number().nullish(),
});

const cartWire = z.object({
  item: z
    .object({
      id: z.string().min(1),
      serviceOptionId: z.string().nullish(),
      deliveryAddressId: z.string().nullish(),
      lineItems: z.array(cartLineWire).nullish(),
      lineItemTotals: z.object({ cartTotalAfterDiscounts: z.number().nullish() }).nullish(),
    })
    .nullish(),
});

export const cartsReply = z.object({ carts: z.array(cartWire).nullish() });

/** The contexts that deliver in sixty minutes; the rest are dropped, malformed ones too. */
export function sixtyMinuteStores(raw: readonly unknown[] | null | undefined): StoreContext[] {
  return (raw ?? []).flatMap((entry) => {
    const parsed = storeContextWire.safeParse(entry);
    if (!parsed.success) return [];
    const store = parsed.data;
    const options = store.serviceOptionIds ?? [];
    if (!options.includes(SIXTY_MINUTE_DELIVERY)) return [];
    return [
      {
        storeId: store.storeId,
        serviceOptionIds: options,
        hasCapacity: store.hasCapacity ?? [],
        brandPriority: store.brandPriority ?? null,
        distanceFromCustomer: store.distanceFromCustomer ?? null,
      },
    ];
  });
}

/** A store context as Checkers takes it back: what it gave, and no nulls. */
export function storeContextWireOf(store: StoreContext): Record<string, unknown> {
  return {
    storeId: store.storeId,
    serviceOptionIds: store.serviceOptionIds,
    hasCapacity: store.hasCapacity,
    ...(store.brandPriority === null ? {} : { brandPriority: store.brandPriority }),
    ...(store.distanceFromCustomer === null
      ? {}
      : { distanceFromCustomer: store.distanceFromCustomer }),
  };
}

/** The coordinates of the account's default address, or its first one's. */
export function defaultAddressCoordinates(
  raw: readonly unknown[] | null | undefined,
): { latitude: number; longitude: number } | null {
  const addresses = (raw ?? []).flatMap((entry) => {
    const parsed = addressWire.safeParse(entry);
    return parsed.success ? [parsed.data] : [];
  });
  const chosen = addresses.find((address) => address.isDefault === true) ?? addresses[0];
  return chosen?.coordinates ?? null;
}

/** A catalogue product in whole cents; one that cannot be read is dropped. */
export function catalogProductOf(raw: unknown): CatalogProduct | null {
  const parsed = productWire.safeParse(raw);
  if (!parsed.success) return null;
  const product = parsed.data;
  const shelfPrice = product.priceWithoutDecimal ?? product.price;
  if (shelfPrice === null || shelfPrice === undefined) return null;
  const unit = product.unitOfMeasure ?? '';
  return {
    productId: product.id,
    storeId: product.storeId,
    articleCode: `${product.articleNumber ?? ''}${unit}`,
    name: product.displayName ?? product.name ?? '',
    // `priceFactor` is 100 in every capture: the price is already cents.
    priceCents: Math.round((shelfPrice * 100) / (product.priceFactor ?? 100)),
    isInStock: product.isStockAvailable === true,
    isSoldByWeight:
      unit === 'KG' ||
      product.sellByWeight === true ||
      product.isVariableWeight === true ||
      (product.variableWeightOptions ?? []).length > 0,
  };
}

/** The sixty-minute cart out of a carts reply, or null when there is none. */
export function sixtyMinuteCart(reply: z.infer<typeof cartsReply>): Cart | null {
  const carts = (reply.carts ?? []).flatMap((entry) => (entry.item ? [entry.item] : []));
  const cart = carts.find((item) => item.serviceOptionId === SIXTY_MINUTE_DELIVERY);
  if (cart === undefined) return null;
  const lines = (cart.lineItems ?? []).filter((line) => line.quantity > 0);
  const summed = lines.reduce((total, line) => total + (line.price ?? 0) * line.quantity, 0);
  return {
    cartId: cart.id,
    deliveryAddressId: cart.deliveryAddressId ?? '',
    lines: lines.map((line) => ({
      lineId: line.id,
      productId: line.productId,
      quantity: line.quantity,
    })),
    totalCents: Math.round(cart.lineItemTotals?.cartTotalAfterDiscounts ?? summed),
  };
}
