import {
  CheckersRefused,
  SIXTY_MINUTE_DELIVERY,
  type Cart,
  type CartLine,
  type CatalogProduct,
  type CheckersLogin,
  type CheckersShop,
  type LinkedAccount,
  type NewCartLine,
  type PendingOtp,
  type ShopContext,
} from './checkers_api';

/**
 * Checkers under the emulator (BE-09): a script, so no local run and no test
 * ever sends an SMS or touches a real cart.
 *
 * - A number ending `0000` is one Checkers will not send to.
 * - The code is always `123456`.
 * - A product id starting `dead` is not ranged; one starting `0000` is out of
 *   stock; every other 24-hex id is in stock at R19.99, sold each.
 * - Each linked account has one cart, kept in memory for the emulator's life.
 */
export const EMULATOR_OTP = '123456';
export const EMULATOR_STORE_ID = 'emulator-store';
export const EMULATOR_PRICE_CENTS = 1999;

// A record, not a Map: `writes_are_atomic.test.ts` reads a Map's setter as a Firestore write.
const carts: Record<string, CartLine[]> = {};

export class EmulatorCheckers implements CheckersLogin, CheckersShop {
  requestOtp(mobile: string): Promise<PendingOtp> {
    if (mobile.endsWith('0000')) return Promise.reject(new CheckersRefused());
    return Promise.resolve({ mobile, reference: 'emulator-reference', route: 'bff' });
  }

  verifyOtp(pending: PendingOtp, code: string): Promise<LinkedAccount> {
    if (code !== EMULATOR_OTP) return Promise.reject(new CheckersRefused());
    const account = pending.mobile.slice(-4);
    return Promise.resolve({
      session: {
        token: `emulator-session-${account}`,
        userId: `emulator-user-${account}`,
        uuid: `emulator-uuid-${account}`,
        customerId: `emulator-customer-${account}`,
      },
      expiresInSeconds: 3600,
      storeContexts: [
        {
          storeId: EMULATOR_STORE_ID,
          serviceOptionIds: [SIXTY_MINUTE_DELIVERY],
          hasCapacity: [SIXTY_MINUTE_DELIVERY],
          brandPriority: 1,
          distanceFromCustomer: 0.5,
        },
      ],
    });
  }

  findProducts(_context: ShopContext, productIds: readonly string[]): Promise<CatalogProduct[]> {
    return Promise.resolve(
      productIds
        .filter((id) => /^[0-9a-f]{24}$/.test(id) && !id.startsWith('dead'))
        .map((id) => ({
          productId: id,
          storeId: EMULATOR_STORE_ID,
          articleCode: `${id.slice(-8)}EA`,
          name: `Emulator product ${id.slice(-4)}`,
          priceCents: EMULATOR_PRICE_CENTS,
          isInStock: !id.startsWith('0000'),
          isSoldByWeight: false,
        })),
    );
  }

  findByArticleCode(): Promise<CatalogProduct | null> {
    return Promise.resolve(null);
  }

  readCart(context: ShopContext): Promise<Cart> {
    return Promise.resolve(cartOf(context.session.userId));
  }

  addLines(context: ShopContext, _cart: Cart, lines: readonly NewCartLine[]): Promise<Cart> {
    const existing = carts[context.session.userId] ?? [];
    const added = lines.map((line, index) => ({
      lineId: `line-${String(existing.length + index)}`,
      productId: line.productId,
      quantity: line.quantity,
    }));
    carts[context.session.userId] = [...existing, ...added];
    return Promise.resolve(cartOf(context.session.userId));
  }
}

function cartOf(userId: string): Cart {
  const lines = carts[userId] ?? [];
  return {
    cartId: `emulator-cart-${userId}`,
    deliveryAddressId: 'emulator-address',
    lines,
    totalCents: lines.reduce((total, line) => total + line.quantity * EMULATOR_PRICE_CENTS, 0),
  };
}
