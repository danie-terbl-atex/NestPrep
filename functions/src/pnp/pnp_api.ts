/**
 * The two doors to Pick n Pay (add-to-pnp ADR-0003, ADR-0004; BE-09): one to
 * PnP's OpenID Connect server, to turn a login code into the member's tokens
 * and keep them fresh, and one to the member's own cart on the website's
 * commerce API. `HttpPnpLogin` and `HttpPnpShop` talk to PnP; `EmulatorPnp`
 * answers from a script, so no test and no local run reaches PnP.
 *
 * A failure is one of three errors below, never a status code, so the
 * callables choose a refusal without knowing HTTP exists.
 */

/** The website's own OIDC client, as PnP's `/config` serves it to every browser. */
export interface PnpClient {
  readonly clientId: string;
  readonly clientSecret: string;
  readonly authorizeEndpoint: string;
  readonly tokenEndpoint: string;
}

export interface PnpTokens {
  readonly accessToken: string;
  /** Null when a refresh answered without a new one — the old one stays good. */
  readonly refreshToken: string | null;
  readonly expiresInSeconds: number;
}

export interface PnpCartEntry {
  readonly guid: string;
  readonly productCode: string;
  readonly quantity: number;
}

/** The member's active cart, addressed by its `code`. */
export interface PnpCart {
  readonly code: string;
  /** The store whose prices and stock the member sees — set by their delivery address. */
  readonly storeCode: string | null;
  /** How many items a delivery cart may hold; null when PnP did not say. */
  readonly maxItems: number | null;
  /** Items, a line of three counting three. */
  readonly itemCount: number;
  readonly totalCents: number;
  readonly entries: readonly PnpCartEntry[];
}

/** A product as the member's own store sells it today. */
export interface PnpProduct {
  readonly code: string;
  readonly name: string;
  readonly priceCents: number;
  readonly isInStock: boolean;
  /** Sold by weight or by average weight: its quantity is grams or a guess. */
  readonly isWeighed: boolean;
  /** The most one cart may hold of it, when PnP says; a raise is clamped to it. */
  readonly maxOrderQuantity: number | null;
}

/**
 * What PnP did not do of a cart write it answered (add-to-pnp ADR-0004): no
 * stock, less stock than asked, past the product's order limit, or the line
 * refused outright. Null when the line holds what was asked.
 */
export type CartWriteShortfall = 'out-of-stock' | 'low-stock' | 'max-quantity' | 'shop-refused';

export interface PnpLogin {
  /** The website's client, read from PnP. Throws `PnpUnavailable` when it cannot be read. */
  client(): Promise<PnpClient>;
  /** Throws `PnpRefused` when PnP will not take the code. */
  exchangeCode(code: string, verifier: string): Promise<PnpTokens>;
  /** Throws `PnpSessionExpired` when PnP will not take the refresh token. */
  refresh(refreshToken: string): Promise<PnpTokens>;
}

export interface PnpShop {
  /** The member's active cart, made when they have none. */
  readCart(accessToken: string): Promise<PnpCart>;
  /** The product at [storeCode], or null when that store does not range it. */
  findProduct(accessToken: string, storeCode: string, code: string): Promise<PnpProduct | null>;
  /** A new line — PnP increments a line already there, so only for a product not in the cart. */
  addEntry(
    accessToken: string,
    cartCode: string,
    code: string,
    quantity: number,
  ): Promise<CartWriteShortfall | null>;
  /** An absolute quantity on an existing line, by its guid. */
  setQuantity(
    accessToken: string,
    cartCode: string,
    entryGuid: string,
    quantity: number,
  ): Promise<CartWriteShortfall | null>;
}

/** PnP could not be reached, was busy, failing, or answered something unreadable. */
export class PnpUnavailable extends Error {
  constructor(readonly reason: string) {
    super(`pnp unavailable: ${reason}`);
    this.name = 'PnpUnavailable';
  }
}

/** PnP would not take the login code. */
export class PnpRefused extends Error {
  constructor() {
    super('pnp refused the code');
    this.name = 'PnpRefused';
  }
}

/** The member's tokens are no longer accepted; the member links again. */
export class PnpSessionExpired extends Error {
  constructor() {
    super('pnp session expired');
    this.name = 'PnpSessionExpired';
  }
}
