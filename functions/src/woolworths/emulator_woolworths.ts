import {
  WoolworthsSessionExpired,
  type WoolworthsCart,
  type WoolworthsCartLine,
  type WoolworthsLogin,
  type WoolworthsProduct,
  type WoolworthsShop,
  type WoolworthsTokens,
} from './woolworths_api';
import { idTokenClaims } from './woolworths_id_token';
import { isWeighedWoolworths } from './woolworths_wire';

export const EMULATOR_WOOLWORTHS_PREFIX = 'emulator-';
export const EMULATOR_WOOLWORTHS_EMAIL = 'parent@oakstreet.nest';
export const EMULATOR_WOOLWORTHS_STORE = 'EMU01';
export const EMULATOR_WOOLWORTHS_PRICE_CENTS = 2499;
export const EMULATOR_WOOLWORTHS_LIMITED = 2;

const ID_SECONDS = 24 * 60 * 60;

const carts: Record<string, Record<string, number>> = {};

function base64url(value: unknown): string {
  return Buffer.from(JSON.stringify(value), 'utf8').toString('base64url');
}

function idTokenFor(owner: string): string {
  const payload = {
    email: EMULATOR_WOOLWORTHS_EMAIL,
    exp: Math.floor(Date.now() / 1000) + ID_SECONDS,
    sub: owner,
    'custom:AtgId': owner,
  };
  return `${base64url({ alg: 'none' })}.${base64url(payload)}.emulator`;
}

function ownerOf(idToken: string): string {
  const owner = idTokenClaims(idToken)?.['custom:AtgId'];
  if (owner === undefined || !idToken.endsWith('.emulator')) throw new WoolworthsSessionExpired();
  return String(owner);
}

export class EmulatorWoolworths implements WoolworthsLogin, WoolworthsShop {
  refresh(refreshToken: string): Promise<WoolworthsTokens> {
    if (!refreshToken.startsWith(EMULATOR_WOOLWORTHS_PREFIX)) {
      return Promise.reject(new WoolworthsSessionExpired());
    }
    return Promise.resolve({
      idToken: idTokenFor(refreshToken.slice(EMULATOR_WOOLWORTHS_PREFIX.length)),
      refreshToken: null,
      expiresInSeconds: ID_SECONDS,
    });
  }

  readCart(idToken: string): Promise<WoolworthsCart> {
    const cart = carts[ownerOf(idToken)] ?? {};
    const lines = Object.entries(cart).map(([sku, quantity]) => ({ sku, quantity }));
    const itemCount = lines.reduce((total, line) => total + line.quantity, 0);
    return Promise.resolve({
      storeId: EMULATOR_WOOLWORTHS_STORE,
      itemCount,
      totalCents: itemCount * EMULATOR_WOOLWORTHS_PRICE_CENTS,
      lines,
    });
  }

  findProduct(idToken: string, sku: string): Promise<WoolworthsProduct | null> {
    ownerOf(idToken);
    if (!/^[0-9]{6,14}$/.test(sku) || sku.startsWith('999')) return Promise.resolve(null);
    const name = `Emulator product ${sku.slice(-4)}`;
    return Promise.resolve({
      sku,
      name,
      priceCents: EMULATOR_WOOLWORTHS_PRICE_CENTS,
      isWeighed: isWeighedWoolworths(sku, name),
    });
  }

  addItems(idToken: string, lines: readonly WoolworthsCartLine[]): Promise<void> {
    const owner = ownerOf(idToken);
    const cart = { ...(carts[owner] ?? {}) };
    for (const { sku, quantity } of lines) {
      // `0001…` is out of stock and takes nothing; `0002…` stops at two a cart.
      if (sku.startsWith('0001')) continue;
      const wanted = (cart[sku] ?? 0) + quantity;
      cart[sku] = sku.startsWith('0002') ? Math.min(wanted, EMULATOR_WOOLWORTHS_LIMITED) : wanted;
    }
    carts[owner] = cart;
    return Promise.resolve();
  }
}
