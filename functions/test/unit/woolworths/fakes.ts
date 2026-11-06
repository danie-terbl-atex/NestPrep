import { randomBytes } from 'node:crypto';

import type { GroceryLine } from '../../../src/cart_push/grocery_lines';
import {
  WoolworthsSessionExpired,
  type WoolworthsCart,
  type WoolworthsCartLine,
  type WoolworthsLogin,
  type WoolworthsProduct,
  type WoolworthsShop,
  type WoolworthsTokens,
} from '../../../src/woolworths/woolworths_api';
import type {
  SessionSwap,
  WoolworthsLink,
  WoolworthsLinkStore,
  WoolworthsSessionLink,
} from '../../../src/woolworths/woolworths_link_store';

export const KEY = randomBytes(32);
export const NOW = new Date('2026-11-05T10:00:00Z');
export const UID = 'uid-sam';

export function fakeIdToken(claims: Record<string, unknown>): string {
  const part = (value: unknown): string =>
    Buffer.from(JSON.stringify(value), 'utf8').toString('base64url');
  return `${part({ alg: 'RS256' })}.${part(claims)}.signature`;
}

export class MemoryWoolworthsLinks implements WoolworthsLinkStore {
  readonly links: Record<string, WoolworthsLink> = {};

  read(uid: string): Promise<WoolworthsLink | null> {
    return Promise.resolve(this.links[uid] ?? null);
  }

  saveSession(uid: string, session: WoolworthsSessionLink): Promise<void> {
    this.links[uid] = { session };
    return Promise.resolve();
  }

  replaceSession(
    uid: string,
    expectedSealed: string,
    next: WoolworthsSessionLink,
  ): Promise<SessionSwap> {
    const link = this.links[uid];
    if (link?.session == null) return Promise.resolve('gone');
    if (link.session.sealed !== expectedSealed) return Promise.resolve('changed');
    this.links[uid] = { session: next };
    return Promise.resolve('replaced');
  }

  remove(uid: string): Promise<void> {
    Reflect.deleteProperty(this.links, uid);
    return Promise.resolve();
  }
}

export class ScriptedWoolworthsLogin implements WoolworthsLogin {
  readonly refreshed: string[] = [];
  readonly spent = new Set<string>();
  failWith: Error | null = null;
  refuse = false;
  rotate = false;
  email = 'daniel@acme.io';
  private issued = 0;

  refresh(refreshToken: string): Promise<WoolworthsTokens> {
    this.refreshed.push(refreshToken);
    if (this.failWith !== null) return Promise.reject(this.failWith);
    if (this.refuse || this.spent.has(refreshToken)) {
      return Promise.reject(new WoolworthsSessionExpired());
    }
    if (this.rotate) this.spent.add(refreshToken);
    this.issued += 1;
    return Promise.resolve({
      idToken: fakeIdToken({
        email: this.email,
        exp: Math.floor(NOW.getTime() / 1000) + 86_400,
        n: this.issued,
      }),
      refreshToken: this.rotate ? `refresh-${String(this.issued)}` : null,
      expiresInSeconds: 3600,
    });
  }
}

export function woolworthsProduct(
  sku: string,
  overrides: Partial<WoolworthsProduct> = {},
): WoolworthsProduct {
  return {
    sku,
    name: `Product ${sku.slice(-4)}`,
    priceCents: 4099,
    isWeighed: false,
    ...overrides,
  };
}

export const EMPTY_CART: WoolworthsCart = {
  storeId: '471',
  itemCount: 0,
  totalCents: 0,
  lines: [],
};

export class ScriptedWoolworthsShop implements WoolworthsShop {
  readonly catalogue: Record<string, WoolworthsProduct> = {};
  readonly posts: WoolworthsCartLine[][] = [];
  readonly tokensSeen: string[] = [];
  readonly refused = new Set<string>();
  cart: WoolworthsCart = EMPTY_CART;
  failWith: Error | null = null;
  addFailsWith: Error | null = null;
  readonly takesAtMost: Record<string, number> = {};
  lookupsAtOnce = 0;
  private lookupsNow = 0;

  readCart(idToken: string): Promise<WoolworthsCart> {
    this.tokensSeen.push(idToken);
    if (this.refused.has(idToken)) return Promise.reject(new WoolworthsSessionExpired());
    if (this.failWith !== null) return Promise.reject(this.failWith);
    return Promise.resolve(this.cart);
  }

  async findProduct(_idToken: string, sku: string): Promise<WoolworthsProduct | null> {
    this.lookupsNow += 1;
    this.lookupsAtOnce = Math.max(this.lookupsAtOnce, this.lookupsNow);
    await new Promise((resolve) => setTimeout(resolve, 1));
    this.lookupsNow -= 1;
    return this.catalogue[sku] ?? null;
  }

  addItems(_idToken: string, lines: readonly WoolworthsCartLine[]): Promise<void> {
    this.posts.push([...lines]);
    if (this.addFailsWith !== null) return Promise.reject(this.addFailsWith);
    const bySku: Record<string, number> = Object.fromEntries(
      this.cart.lines.map((line) => [line.sku, line.quantity]),
    );
    for (const { sku, quantity } of lines) {
      const wanted = (bySku[sku] ?? 0) + quantity;
      bySku[sku] = Math.min(wanted, this.takesAtMost[sku] ?? wanted);
    }
    const next = Object.entries(bySku).map(([sku, quantity]) => ({ sku, quantity }));
    const itemCount = next.reduce((total, line) => total + line.quantity, 0);
    this.cart = { ...this.cart, lines: next, itemCount, totalCents: itemCount * 4099 };
    return Promise.resolve();
  }
}

export function woolworthsPicked(
  itemId: string,
  sku: string,
  unitOfMeasure = 'EA',
  isBought = false,
): GroceryLine {
  return {
    itemId,
    isBought,
    pick: { retailer: 'woolworths', productId: sku, articleCode: sku, unitOfMeasure },
  };
}
