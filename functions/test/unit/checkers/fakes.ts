import { randomBytes } from 'node:crypto';

import {
  CheckersRefused,
  SIXTY_MINUTE_DELIVERY,
  type Cart,
  type CatalogProduct,
  type CheckersLogin,
  type CheckersShop,
  type LinkedAccount,
  type NewCartLine,
  type PendingOtp,
  type StoreContext,
} from '../../../src/checkers/checkers_api';
import type { CheckersAppIdentity } from '../../../src/checkers/checkers_config';
import type { GroceryLine, GroceryLineReader } from '../../../src/checkers/grocery_lines';
import type {
  CheckersLink,
  CheckersLinkStore,
  ClaimedAttempt,
  PendingLink,
  SessionLink,
} from '../../../src/checkers/link_store';

/**
 * Stand-ins for everything Add to Checkers reaches, so its rules are tested
 * with nothing running and nothing sent (BE-09, BE-14). No value here is a
 * real person's, a real key or a real session.
 */
export const KEY = randomBytes(32);
export const NOW = new Date('2026-09-30T10:00:00Z');
export const MOBILE = '+27821234567';

export const APP: CheckersAppIdentity = {
  apiKey: 'test-api-key',
  profileToken: 'test-profile-token',
  appVersion: 'Android 0.0.0 (1)',
  appVersionCode: '1',
};

export const STORE: StoreContext = {
  storeId: '62dabd7f832d656087c747d8',
  serviceOptionIds: [SIXTY_MINUTE_DELIVERY],
  hasCapacity: [SIXTY_MINUTE_DELIVERY],
  brandPriority: 1,
  distanceFromCustomer: 0.69,
};

export const ACCOUNT: LinkedAccount = {
  session: { token: 'session-token', userId: 'user-1', uuid: 'uuid-1', customerId: 'cust-1' },
  expiresInSeconds: 3600,
  storeContexts: [STORE],
};

/** `checkersLinks` in memory, with the same claim-first semantics as Firestore's. */
export class MemoryLinkStore implements CheckersLinkStore {
  readonly links: Record<string, CheckersLink> = {};

  read(uid: string): Promise<CheckersLink | null> {
    return Promise.resolve(this.links[uid] ?? null);
  }

  savePending(uid: string, deviceId: string, pending: PendingLink): Promise<void> {
    this.links[uid] = { deviceId, pending, session: this.links[uid]?.session ?? null };
    return Promise.resolve();
  }

  claimAttempt(uid: string, now: Date, maxAttempts: number): Promise<ClaimedAttempt | null> {
    const link = this.links[uid];
    const pending = link?.pending ?? null;
    if (link === undefined || pending === null) return Promise.resolve(null);
    const isLive = pending.expiresAt > now && pending.attempts < maxAttempts;
    const next = isLive ? { ...pending, attempts: pending.attempts + 1 } : null;
    this.links[uid] = { ...link, pending: next };
    return Promise.resolve(next === null ? null : { deviceId: link.deviceId, pending: next });
  }

  saveSession(uid: string, deviceId: string, session: SessionLink): Promise<void> {
    this.links[uid] = { deviceId, pending: null, session };
    return Promise.resolve();
  }

  remove(uid: string): Promise<void> {
    Reflect.deleteProperty(this.links, uid);
    return Promise.resolve();
  }
}

/** A login that answers from a script and remembers what it was asked. */
export class ScriptedLogin implements CheckersLogin {
  readonly codesSent: string[] = [];
  refuseNumber = false;
  failWith: Error | null = null;

  requestOtp(mobile: string): Promise<PendingOtp> {
    if (this.failWith !== null) return Promise.reject(this.failWith);
    if (this.refuseNumber) return Promise.reject(new CheckersRefused());
    this.codesSent.push(mobile);
    return Promise.resolve({ mobile, reference: 'ref-1', route: 'bff' });
  }

  verifyOtp(_pending: PendingOtp, code: string): Promise<LinkedAccount> {
    if (this.failWith !== null) return Promise.reject(this.failWith);
    return code === '1234' ? Promise.resolve(ACCOUNT) : Promise.reject(new CheckersRefused());
  }
}

export function product(id: string, overrides: Partial<CatalogProduct> = {}): CatalogProduct {
  return {
    productId: id,
    storeId: STORE.storeId,
    articleCode: `${id.slice(-8)}EA`,
    name: `Product ${id.slice(-4)}`,
    priceCents: 3799,
    isInStock: true,
    isSoldByWeight: false,
    ...overrides,
  };
}

/** A catalogue and a cart in memory, recording every line it was sent. */
export class ScriptedShop implements CheckersShop {
  readonly catalogue: Record<string, CatalogProduct> = {};
  readonly byArticle: Record<string, CatalogProduct> = {};
  readonly sent: NewCartLine[][] = [];
  cart: Cart = { cartId: 'cart-1', deliveryAddressId: 'addr-1', lines: [], totalCents: 0 };
  failWith: Error | null = null;

  findProducts(_context: unknown, ids: readonly string[]): Promise<CatalogProduct[]> {
    if (this.failWith !== null) return Promise.reject(this.failWith);
    return Promise.resolve(ids.flatMap((id) => this.catalogue[id] ?? []));
  }

  findByArticleCode(_context: unknown, code: string): Promise<CatalogProduct | null> {
    return Promise.resolve(this.byArticle[code] ?? null);
  }

  readCart(): Promise<Cart> {
    if (this.failWith !== null) return Promise.reject(this.failWith);
    return Promise.resolve(this.cart);
  }

  addLines(_context: unknown, cart: Cart, lines: readonly NewCartLine[]): Promise<Cart> {
    this.sent.push([...lines]);
    const added = lines.map((line, index) => ({
      lineId: `new-${String(index)}`,
      productId: line.productId,
      quantity: line.quantity,
    }));
    const extra = lines.reduce((total, line) => total + line.priceCents * line.quantity, 0);
    this.cart = { ...cart, lines: [...cart.lines, ...added], totalCents: cart.totalCents + extra };
    return Promise.resolve(this.cart);
  }
}

export class MemoryGroceries implements GroceryLineReader {
  constructor(readonly lines: Record<string, GroceryLine>) {}

  read(_householdId: string, itemIds: readonly string[]): Promise<Record<string, GroceryLine>> {
    return Promise.resolve(
      Object.fromEntries(itemIds.flatMap((id) => (this.lines[id] ? [[id, this.lines[id]]] : []))),
    );
  }
}

export function picked(itemId: string, productId: string, unitOfMeasure = 'EA'): GroceryLine {
  return {
    itemId,
    isBought: false,
    pick: {
      retailer: 'checkers',
      productId,
      articleCode: `12345678${unitOfMeasure}`,
      unitOfMeasure,
    },
  };
}
