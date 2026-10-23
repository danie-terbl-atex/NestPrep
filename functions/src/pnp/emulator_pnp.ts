import {
  PnpRefused,
  PnpSessionExpired,
  type CartWriteShortfall,
  type PnpCart,
  type PnpCartEntry,
  type PnpClient,
  type PnpLogin,
  type PnpProduct,
  type PnpShop,
  type PnpTokens,
} from './pnp_api';
import { PNP_LOGIN } from './pnp_request';

/**
 * Pick n Pay under the emulator (BE-09): a script, so no local run and no
 * test ever reaches PnP or touches a real cart.
 *
 * - The client is `emulator-client`; the authorize URL is still PnP's.
 * - The code `emulator-code` is accepted; any other is refused.
 * - Access tokens are `emulator-access-…`; a refresh token starting
 *   `emulator-refresh` refreshes, anything else is spent.
 * - A code `^[0-9]{6,20}_(EA|CK)$` is ranged, in stock, at R19.99; digits
 *   starting `999` are not ranged, `0001` out of stock, `0002` limited to two
 *   per order, `0003` refused on add as low stock; `_KGM` is weighed.
 * - One cart per access-token owner, capped at 45, in memory for the
 *   emulator's life.
 */
export const EMULATOR_PNP_CODE = 'emulator-code';
export const EMULATOR_PNP_STORE = 'EMU01';
export const EMULATOR_PNP_PRICE_CENTS = 1999;
export const EMULATOR_PNP_CAP = 45;

const CLIENT: PnpClient = {
  clientId: 'emulator-client',
  clientSecret: 'emulator-secret',
  authorizeEndpoint: `${PNP_LOGIN}/authorize`,
  tokenEndpoint: `${PNP_LOGIN}/token`,
};

// A record, not a Map: `writes_are_atomic.test.ts` reads a Map's setter as a Firestore write.
const carts: Record<string, PnpCartEntry[]> = {};
let issued = 0;

export class EmulatorPnp implements PnpLogin, PnpShop {
  client(): Promise<PnpClient> {
    return Promise.resolve(CLIENT);
  }

  exchangeCode(code: string): Promise<PnpTokens> {
    if (code !== EMULATOR_PNP_CODE) return Promise.reject(new PnpRefused());
    return Promise.resolve(tokens(`emulator-refresh-${String(++issued)}`));
  }

  refresh(refreshToken: string): Promise<PnpTokens> {
    if (!refreshToken.startsWith('emulator-refresh')) {
      return Promise.reject(new PnpSessionExpired());
    }
    return Promise.resolve(tokens(refreshToken));
  }

  readCart(accessToken: string): Promise<PnpCart> {
    return Promise.resolve(cartOf(ownerOf(accessToken)));
  }

  findProduct(_accessToken: string, _storeCode: string, code: string): Promise<PnpProduct | null> {
    const match = /^([0-9]{6,20})_(EA|CK|KGM)$/.exec(code);
    const digits = match?.[1];
    if (digits === undefined || digits.startsWith('999')) return Promise.resolve(null);
    return Promise.resolve({
      code,
      name: `Emulator product ${digits.slice(-4)}`,
      priceCents: EMULATOR_PNP_PRICE_CENTS,
      isInStock: !digits.startsWith('0001'),
      isWeighed: code.endsWith('_KGM'),
      maxOrderQuantity: digits.startsWith('0002') ? 2 : null,
    });
  }

  addEntry(
    accessToken: string,
    _cartCode: string,
    code: string,
    quantity: number,
  ): Promise<CartWriteShortfall | null> {
    // Digits starting `0003` are a product PnP has too little of: it refuses the add.
    if (code.startsWith('0003')) return Promise.resolve('low-stock');
    const owner = ownerOf(accessToken);
    const entries = carts[owner] ?? [];
    const existing = entries.find((entry) => entry.productCode === code);
    // PnP's own add increments a line already there; the twin does the same.
    carts[owner] =
      existing === undefined
        ? [
            ...entries,
            { guid: `guid-${owner}-${String(entries.length)}`, productCode: code, quantity },
          ]
        : entries.map((entry) =>
            entry === existing ? { ...entry, quantity: entry.quantity + quantity } : entry,
          );
    return Promise.resolve(null);
  }

  setQuantity(
    accessToken: string,
    _cartCode: string,
    entryGuid: string,
    quantity: number,
  ): Promise<CartWriteShortfall | null> {
    const owner = ownerOf(accessToken);
    carts[owner] = (carts[owner] ?? []).map((entry) =>
      entry.guid === entryGuid ? { ...entry, quantity } : entry,
    );
    return Promise.resolve(null);
  }
}

function tokens(refreshToken: string): PnpTokens {
  return {
    accessToken: `emulator-access-${refreshToken.slice('emulator-refresh-'.length)}`,
    refreshToken,
    expiresInSeconds: 3600,
  };
}

function ownerOf(accessToken: string): string {
  if (!accessToken.startsWith('emulator-access-')) throw new PnpSessionExpired();
  return accessToken.slice('emulator-access-'.length);
}

function cartOf(owner: string): PnpCart {
  const entries = carts[owner] ?? [];
  const itemCount = entries.reduce((total, entry) => total + entry.quantity, 0);
  return {
    code: `emulator-cart-${owner}`,
    storeCode: EMULATOR_PNP_STORE,
    maxItems: EMULATOR_PNP_CAP,
    itemCount,
    totalCents: itemCount * EMULATOR_PNP_PRICE_CENTS,
    entries,
  };
}
