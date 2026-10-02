/**
 * The two doors to Checkers Sixty60 (the Checkers build contract, BE-09): one
 * to link a member's account by SMS code, one to shop with the session that
 * gives. `HttpCheckersLogin` and `HttpCheckersShop` talk to Checkers;
 * `EmulatorCheckers` answers from a script, so no test and no local run ever
 * reaches Checkers or sends an SMS.
 *
 * A failure is one of three errors below, never a status code, so the
 * callables choose a refusal without knowing HTTP exists.
 */

/** A Sixty60 store that serves the member's delivery address. */
export interface StoreContext {
  readonly storeId: string;
  readonly serviceOptionIds: readonly string[];
  readonly hasCapacity: readonly string[];
  readonly brandPriority: number | null;
  readonly distanceFromCustomer: number | null;
}

/** The one delivery option Add to Checkers fills a cart for. */
export const SIXTY_MINUTE_DELIVERY = 'sixty-min-delivery';

/** Which Checkers login service sent the code; the code verifies only there. */
export type OtpRoute = 'bff' | 'dsl';

export interface PendingOtp {
  readonly mobile: string;
  readonly reference: string;
  readonly route: OtpRoute;
}

/**
 * A member's Sixty60 session: the token, good for an hour with no refresh, and
 * the three identifiers every shopping call carries.
 */
export interface CheckersSession {
  readonly token: string;
  /** Sixty60's own id for the customer — the `userid` header. */
  readonly userId: string;
  /** Shoprite's customer uuid — the `customer-id` header. */
  readonly uuid: string;
  /** Shoprite's short customer id — builds the customer-profile address. */
  readonly customerId: string;
}

export interface LinkedAccount {
  readonly session: CheckersSession;
  readonly expiresInSeconds: number;
  readonly storeContexts: readonly StoreContext[];
}

/** Everything a shopping call needs, from the member's link. */
export interface ShopContext {
  readonly session: CheckersSession;
  readonly storeContexts: readonly StoreContext[];
  readonly deviceId: string;
}

/** A product as the member's own stores sell it today. */
export interface CatalogProduct {
  readonly productId: string;
  readonly storeId: string;
  readonly articleCode: string;
  readonly name: string;
  readonly priceCents: number;
  readonly isInStock: boolean;
  readonly isSoldByWeight: boolean;
}

export interface CartLine {
  readonly lineId: string;
  readonly productId: string;
  readonly quantity: number;
}

export interface Cart {
  readonly cartId: string;
  readonly deliveryAddressId: string;
  readonly lines: readonly CartLine[];
  readonly totalCents: number;
}

export interface NewCartLine {
  readonly productId: string;
  readonly storeId: string;
  readonly priceCents: number;
  readonly quantity: number;
}

export interface CheckersLogin {
  /** Sends the SMS. Throws `CheckersRefused` when Checkers will not send to that number. */
  requestOtp(mobile: string, deviceId: string): Promise<PendingOtp>;
  /** Throws `CheckersRefused` when the code is not the one sent. */
  verifyOtp(pending: PendingOtp, code: string, deviceId: string): Promise<LinkedAccount>;
}

export interface CheckersShop {
  /** The products of these ids the member's stores range; an id they do not is left out. */
  findProducts(context: ShopContext, productIds: readonly string[]): Promise<CatalogProduct[]>;
  /** The product with this article code and unit, e.g. `10136729EA`, or null. */
  findByArticleCode(context: ShopContext, articleCode: string): Promise<CatalogProduct | null>;
  /** The member's sixty-minute cart. */
  readCart(context: ShopContext): Promise<Cart>;
  /** Adds lines to the cart — Checkers merges them in — and answers the cart after. */
  addLines(context: ShopContext, cart: Cart, lines: readonly NewCartLine[]): Promise<Cart>;
}

/** Checkers could not be reached, was busy, failing, or answered something unreadable. */
export class CheckersUnavailable extends Error {
  constructor(readonly reason: string) {
    super(`checkers unavailable: ${reason}`);
    this.name = 'CheckersUnavailable';
  }
}

/** Checkers said no to what the member typed: the number, or the code. */
export class CheckersRefused extends Error {
  constructor() {
    super('checkers refused the request');
    this.name = 'CheckersRefused';
  }
}

/** The session is no longer accepted; the member links again. */
export class CheckersSessionExpired extends Error {
  constructor() {
    super('checkers session expired');
    this.name = 'CheckersSessionExpired';
  }
}
