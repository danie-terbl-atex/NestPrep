/**
 * Checkers' answers, shaped like the real ones — the OSS clients' captures and
 * the public catalogue probed on 2026-09-30 — with every identifier, token and
 * number made up. No real person's data is in here.
 */

export const STORE_CONTEXT = {
  storeId: '62dabd7f832d656087c747d8',
  serviceOptionIds: ['sixty-min-delivery'],
  brandPriority: 1,
  hasCapacity: ['sixty-min-delivery'],
  distanceFromCustomer: 0.6909514913029257,
  returnServiceOptionIds: null,
  hasReturnCapacity: null,
};

export const ONE_DAY_CONTEXT = {
  storeId: '60dc2d30c1f98d8e2a812b9e',
  serviceOptionIds: ['one-day-delivery'],
  brandPriority: 2,
  hasCapacity: ['sixty-min-delivery', 'one-day-delivery'],
  distanceFromCustomer: 6.87,
};

/** A product as `products/filter` answers it, trimmed of the fields nothing reads. */
export const MILK = {
  id: '5d3af63bf434cf8420737dd6',
  storeId: '62dabd7f832d656087c747d8',
  serviceOptionId: 'sixty-min-delivery',
  unitOfMeasure: 'EA',
  active: true,
  ranged: true,
  name: 'Clover Fresh Full Cream Milk 2L',
  displayName: 'Clover Fresh Full Cream Milk 2L',
  imageId: '6a5973a6f76689d8c79e254f',
  weightOptions: [],
  variableWeightOptions: [],
  priceFactor: 100,
  priceWithoutDecimal: 3799,
  currency: 'ZAR',
  oldPrice: 3799,
  isOnPromotion: false,
  articleNumber: '10136729',
  isStockAvailable: true,
  stockOnHand: 42,
  brand: 'Clover',
  hasAlcohol: false,
  requiresOver18: false,
};

/** A steak sold per kilogram, with the weight range the app asks for. */
export const STEAK = {
  ...MILK,
  id: '5f1a2b3c4d5e6f7a8b9c0d1e',
  unitOfMeasure: 'KG',
  name: 'Stewing Beef Per kg',
  displayName: 'Stewing Beef Per kg',
  weightOptions: ['900-1100'],
  variableWeightOptions: [{ maximumValue: 1100, minimumValue: 900 }],
  priceWithoutDecimal: 12999,
  articleNumber: '10000001',
};

export const OUT_OF_STOCK = {
  ...MILK,
  id: '5d3af63bf434cf8420737aa1',
  isStockAvailable: false,
  articleNumber: '10136730',
};

/** `carts/user` and `carts/update`: both delivery modes, the sixty-minute one with a line. */
export function cartsWith(
  lines: { id: string; productId: string; quantity: number }[],
): Record<string, unknown> {
  return {
    carts: [
      {
        item: {
          id: 'cart-one-day',
          cartVersion: 3,
          serviceOptionId: 'one-day-delivery',
          deliveryAddressId: 'addr-1',
          lineItems: [],
        },
      },
      {
        item: {
          id: 'cart-sixty',
          cartVersion: 7,
          serviceOptionId: 'sixty-min-delivery',
          deliveryAddressId: 'addr-1',
          lineItems: lines.map((line) => ({
            ...line,
            price: 3799,
            priceFactor: 100,
            status: 'available',
            storeId: STORE_CONTEXT.storeId,
          })),
          lineItemTotals: {
            productTotal: lines.reduce((total, line) => total + 3799 * line.quantity, 0),
            discountTotal: 0,
            cartTotalAfterDiscounts: lines.reduce((total, line) => total + 3799 * line.quantity, 0),
          },
        },
      },
    ],
  };
}

export const APP_TOKEN = { access_token: 'app-jwt', expires_in: 86400, token_type: 'Bearer' };
export const OTP_SENT = { response: { reference: 'otp-reference-1' } };
export const OTP_VERIFIED = { response: { accessToken: 'SESSIONTOKEN0001', expiresIn: 3600 } };
export const IDENTITY = {
  response: { user: { uuid: 'uuid-0000-1111', customerId: '000TEST1', email: null } },
};
export const PROFILE = {
  userProfile: {
    id: '64aa00bb11cc22dd33ee44ff',
    storeContexts: [STORE_CONTEXT, ONE_DAY_CONTEXT],
    addresses: [
      {
        identifier: 'addr-1',
        name: 'Home',
        isDefault: true,
        coordinates: { latitude: -33.92, longitude: 18.42 },
      },
    ],
  },
};
