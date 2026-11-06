export interface WoolworthsTokens {
  readonly idToken: string;
  readonly refreshToken: string | null;
  readonly expiresInSeconds: number;
}

export interface WoolworthsCartLine {
  readonly sku: string;
  readonly quantity: number;
}

export interface WoolworthsCart {
  readonly storeId: string | null;
  readonly itemCount: number;
  readonly totalCents: number;
  readonly lines: readonly WoolworthsCartLine[];
}

export interface WoolworthsProduct {
  readonly sku: string;
  readonly name: string;
  readonly priceCents: number;
  readonly isWeighed: boolean;
}

export interface WoolworthsLogin {
  refresh(refreshToken: string): Promise<WoolworthsTokens>;
}

export interface WoolworthsShop {
  readCart(idToken: string): Promise<WoolworthsCart>;
  findProduct(idToken: string, sku: string): Promise<WoolworthsProduct | null>;
  addItems(idToken: string, lines: readonly WoolworthsCartLine[]): Promise<void>;
}

export class WoolworthsUnavailable extends Error {
  constructor(readonly reason: string) {
    super(`woolworths unavailable: ${reason}`);
    this.name = 'WoolworthsUnavailable';
  }
}

export class WoolworthsSessionExpired extends Error {
  constructor() {
    super('woolworths session expired');
    this.name = 'WoolworthsSessionExpired';
  }
}

export class WoolworthsRejected extends Error {
  constructor(readonly status: number) {
    super(`woolworths rejected the cart call: ${String(status)}`);
    this.name = 'WoolworthsRejected';
  }
}
