import { randomBytes } from 'node:crypto';

import type { GroceryLine } from '../../../src/cart_push/grocery_lines';
import {
  PnpRefused,
  PnpSessionExpired,
  type CartWriteShortfall,
  type PnpCart,
  type PnpClient,
  type PnpLogin,
  type PnpProduct,
  type PnpShop,
  type PnpTokens,
} from '../../../src/pnp/pnp_api';
import type {
  PendingPnpLink,
  PnpLink,
  PnpLinkStore,
  PnpSessionLink,
  SessionSwap,
} from '../../../src/pnp/pnp_link_store';

/**
 * Stand-ins for everything Add to Pick n Pay reaches, so its rules are tested
 * with nothing running and nothing sent (BE-09, BE-14). No value here is a
 * real person's, a real client secret or a real token.
 */
export const KEY = randomBytes(32);
export const NOW = new Date('2026-10-12T10:00:00Z');
export const UID = 'uid-sam';

export const CLIENT: PnpClient = {
  clientId: 'test-client',
  clientSecret: 'test-secret',
  authorizeEndpoint: 'https://login.pnp.co.za/authorize',
  tokenEndpoint: 'https://login.pnp.co.za/token',
};

/** `pnpLinks` in memory, with the same one-use claim as Firestore's. */
export class MemoryPnpLinks implements PnpLinkStore {
  readonly links: Record<string, PnpLink> = {};

  read(uid: string): Promise<PnpLink | null> {
    return Promise.resolve(this.links[uid] ?? null);
  }

  savePending(uid: string, pending: PendingPnpLink): Promise<void> {
    this.links[uid] = { pending, session: this.links[uid]?.session ?? null };
    return Promise.resolve();
  }

  claimPending(uid: string, now: Date): Promise<PendingPnpLink | null> {
    const link = this.links[uid];
    const pending = link?.pending ?? null;
    if (link === undefined || pending === null) return Promise.resolve(null);
    this.links[uid] = { ...link, pending: null };
    return Promise.resolve(pending.expiresAt > now ? pending : null);
  }

  saveSession(uid: string, session: PnpSessionLink): Promise<void> {
    this.links[uid] = { pending: null, session };
    return Promise.resolve();
  }

  replaceSession(uid: string, expectedSealed: string, next: PnpSessionLink): Promise<SessionSwap> {
    const link = this.links[uid];
    if (link?.session == null) return Promise.resolve('gone');
    if (link.session.sealed !== expectedSealed) return Promise.resolve('changed');
    this.links[uid] = { ...link, session: next };
    return Promise.resolve('replaced');
  }

  remove(uid: string): Promise<void> {
    Reflect.deleteProperty(this.links, uid);
    return Promise.resolve();
  }
}

/** A login that answers from a script and remembers what it was asked. */
export class ScriptedPnpLogin implements PnpLogin {
  readonly exchanged: { code: string; verifier: string }[] = [];
  readonly refreshed: string[] = [];
  /** PnP rotates: a refresh token used once is refused after (the race ADR-0003 guards). */
  readonly spent = new Set<string>();
  failWith: Error | null = null;
  refuseRefresh = false;
  rotate = true;
  giveRefresh = true;
  private issued = 0;

  client(): Promise<PnpClient> {
    return this.failWith === null ? Promise.resolve(CLIENT) : Promise.reject(this.failWith);
  }

  exchangeCode(code: string, verifier: string): Promise<PnpTokens> {
    if (this.failWith !== null) return Promise.reject(this.failWith);
    this.exchanged.push({ code, verifier });
    if (code !== 'good-code') return Promise.reject(new PnpRefused());
    return Promise.resolve(this.tokens(this.giveRefresh ? 'refresh-0' : null));
  }

  refresh(refreshToken: string): Promise<PnpTokens> {
    this.refreshed.push(refreshToken);
    if (this.refuseRefresh || this.spent.has(refreshToken)) {
      return Promise.reject(new PnpSessionExpired());
    }
    if (this.rotate) this.spent.add(refreshToken);
    return Promise.resolve(this.tokens(this.rotate ? `refresh-${String(this.issued + 1)}` : null));
  }

  private tokens(refreshToken: string | null): PnpTokens {
    this.issued += 1;
    return { accessToken: `access-${String(this.issued)}`, refreshToken, expiresInSeconds: 300 };
  }
}

export function pnpProduct(code: string, overrides: Partial<PnpProduct> = {}): PnpProduct {
  return {
    code,
    name: `Product ${code.slice(-7, -3)}`,
    priceCents: 4899,
    isInStock: true,
    isWeighed: false,
    maxOrderQuantity: null,
    ...overrides,
  };
}

export const EMPTY_CART: PnpCart = {
  code: '0379085864',
  storeCode: 'GC13',
  maxItems: 45,
  itemCount: 0,
  totalCents: 0,
  entries: [],
};

/** A cart and a catalogue in memory, recording every write it was sent. */
export class ScriptedPnpShop implements PnpShop {
  readonly catalogue: Record<string, PnpProduct> = {};
  readonly writes: string[] = [];
  readonly tokensSeen: string[] = [];
  cart: PnpCart = EMPTY_CART;
  /** Access tokens refused as expired. */
  readonly refused = new Set<string>();
  failWith: Error | null = null;
  /** What PnP answers short on each write of a product, by code. */
  readonly shortOn: Record<string, CartWriteShortfall> = {};
  /** Product lookups running at once, at most. */
  lookupsAtOnce = 0;
  private lookupsNow = 0;

  readCart(accessToken: string): Promise<PnpCart> {
    this.tokensSeen.push(accessToken);
    if (this.refused.has(accessToken)) return Promise.reject(new PnpSessionExpired());
    if (this.failWith !== null) return Promise.reject(this.failWith);
    return Promise.resolve(this.cart);
  }

  async findProduct(_token: string, _store: string, code: string): Promise<PnpProduct | null> {
    this.lookupsNow += 1;
    this.lookupsAtOnce = Math.max(this.lookupsAtOnce, this.lookupsNow);
    await new Promise((resolve) => setTimeout(resolve, 1));
    this.lookupsNow -= 1;
    return this.catalogue[code] ?? null;
  }

  addEntry(
    _token: string,
    _cart: string,
    code: string,
    quantity: number,
  ): Promise<CartWriteShortfall | null> {
    this.writes.push(`add ${code} ${String(quantity)}`);
    const short = this.shortOn[code];
    if (short !== undefined) return Promise.resolve(short);
    this.cart = {
      ...this.cart,
      itemCount: this.cart.itemCount + quantity,
      entries: [...this.cart.entries, { guid: `g-${code}`, productCode: code, quantity }],
    };
    return Promise.resolve(null);
  }

  setQuantity(
    _token: string,
    _cart: string,
    guid: string,
    quantity: number,
  ): Promise<CartWriteShortfall | null> {
    this.writes.push(`set ${guid} ${String(quantity)}`);
    const before = this.cart.entries.find((entry) => entry.guid === guid)?.quantity ?? 0;
    this.cart = {
      ...this.cart,
      itemCount: this.cart.itemCount + quantity - before,
      entries: this.cart.entries.map((entry) =>
        entry.guid === guid ? { ...entry, quantity } : entry,
      ),
    };
    return Promise.resolve(null);
  }
}

export function pnpPicked(itemId: string, code: string, isBought = false): GroceryLine {
  const [digits = '', unit = ''] = code.split('_');
  return {
    itemId,
    isBought,
    pick: { retailer: 'pickNPay', productId: code, articleCode: digits, unitOfMeasure: unit },
  };
}
