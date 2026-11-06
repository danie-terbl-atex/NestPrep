import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import {
  pushToCheckersCart,
  type CartPushDeps,
  type CheckersPushCall,
} from '../../../src/checkers/cart_push';
import {
  CheckersSessionExpired,
  CheckersUnavailable,
  type Cart,
} from '../../../src/checkers/checkers_api';
import { requireGroceryReader } from '../../../src/checkers/checkers_caller';
import { groceryLineOf } from '../../../src/cart_push/grocery_lines';
import { sealSession } from '../../../src/checkers/sealed_values';
import { ROLE_DEFAULTS, uniformGrant } from '../../../src/household/access';
import {
  ACCOUNT,
  KEY,
  MemoryGroceries,
  MemoryLinkStore,
  NOW,
  STORE,
  ScriptedShop,
  picked,
  product,
} from './fakes';

/**
 * "Add to Checkers" (the Checkers build contract): the matched, unbought items
 * into the member's own cart, re-read at their stores, never doubled on a
 * retry, each skip given its reason — and only for somebody who may see the
 * list, with a live link (BE-14).
 */

const UID = 'uid-sam';
const MILK = '5d3af63bf434cf8420737dd6';
const BREAD = '5d3af63bf434cf8420737aa1';
const GONE = 'deaddeaddeaddeaddeaddead';

async function linked(
  options: { expiresAt?: Date; stores?: boolean } = {},
): Promise<MemoryLinkStore> {
  const links = new MemoryLinkStore();
  await links.saveSession(UID, 'device-1', {
    sealed: await sealSession(KEY, UID, ACCOUNT.session),
    expiresAt: options.expiresAt ?? new Date(NOW.getTime() + 30 * 60_000),
    storeContexts: options.stores === false ? [] : [STORE],
    mobileMasked: '+27 ** *** 4567',
  });
  return links;
}

function run(
  links: MemoryLinkStore,
  groceries: MemoryGroceries,
  shop = new ScriptedShop(),
): CartPushDeps & { shop: ScriptedShop } {
  shop.catalogue[MILK] = product(MILK, { name: 'Clover Fresh Full Cream Milk 2L' });
  shop.catalogue[BREAD] = product(BREAD, { priceCents: 1899 });
  return { links, shop, groceries, key: KEY, now: NOW };
}

async function refusal(promise: Promise<unknown>): Promise<unknown> {
  try {
    await promise;
  } catch (error) {
    if (error instanceof HttpsError) return (error.details as { reason: string }).reason;
    throw error;
  }
  throw new Error('expected a refusal');
}

const call = (itemIds: string[], quantities: Record<string, number> = {}): CheckersPushCall => ({
  uid: UID,
  householdId: 'h1',
  itemIds,
  quantities,
});

function cartHolding(lines: { lineId: string; productId: string; quantity: number }[]): Cart {
  return { cartId: 'cart-1', deliveryAddressId: 'addr-1', lines, totalCents: 0 };
}

describe('filling the cart', () => {
  it('adds each matched item once, at today’s price, and answers the cart after', async () => {
    const groceries = new MemoryGroceries({
      milk: picked('milk', MILK),
      bread: picked('bread', BREAD),
    });
    const deps = run(await linked(), groceries);
    const result = await pushToCheckersCart(deps, call(['milk', 'bread']));
    expect(result.added).toEqual([
      {
        itemId: 'milk',
        productId: MILK,
        name: 'Clover Fresh Full Cream Milk 2L',
        priceCents: 3799,
      },
      { itemId: 'bread', productId: BREAD, name: 'Product 7aa1', priceCents: 1899 },
    ]);
    expect(result.skipped).toEqual([]);
    expect(result.cartItemCount).toBe(2);
    expect(result.cartTotalCents).toBe(3799 + 1899);
    expect(deps.shop.sent).toEqual([
      [
        { lineId: null, productId: MILK, storeId: STORE.storeId, priceCents: 3799, quantity: 1 },
        { lineId: null, productId: BREAD, storeId: STORE.storeId, priceCents: 1899, quantity: 1 },
      ],
    ]);
  });

  it('makes two items of one product one line of two', async () => {
    const groceries = new MemoryGroceries({ a: picked('a', MILK), b: picked('b', MILK) });
    const deps = run(await linked(), groceries);
    const result = await pushToCheckersCart(deps, call(['a', 'b']));
    expect(result.added).toHaveLength(2);
    expect(deps.shop.sent[0]).toEqual([expect.objectContaining({ productId: MILK, quantity: 2 })]);
  });

  it('asks for each item’s packs, and two items of one product add up', async () => {
    const groceries = new MemoryGroceries({
      a: picked('a', MILK),
      b: picked('b', MILK),
      bread: picked('bread', BREAD),
    });
    const deps = run(await linked(), groceries);
    const result = await pushToCheckersCart(deps, call(['a', 'b', 'bread'], { a: 3, bread: 2 }));
    expect(result.added.map((line) => line.itemId)).toEqual(['a', 'b', 'bread']);
    expect(deps.shop.sent[0]).toEqual([
      expect.objectContaining({ lineId: null, productId: MILK, quantity: 4 }),
      expect.objectContaining({ lineId: null, productId: BREAD, quantity: 2 }),
    ]);
    expect(result.cartItemCount).toBe(6);
  });

  it('never doubles the cart: a product already held is counted as added and not sent', async () => {
    const shop = new ScriptedShop();
    shop.cart = cartHolding([{ lineId: 'l1', productId: MILK, quantity: 3 }]);
    const deps = run(await linked(), new MemoryGroceries({ milk: picked('milk', MILK) }), shop);
    const result = await pushToCheckersCart(deps, call(['milk'], { milk: 2 }));
    expect(result.added.map((line) => line.itemId)).toEqual(['milk']);
    expect(deps.shop.sent).toEqual([]);
    expect(result.cartItemCount).toBe(3);
  });

  it('adds only what the cart is short of, on the line it already has', async () => {
    const shop = new ScriptedShop();
    shop.cart = cartHolding([{ lineId: 'l1', productId: MILK, quantity: 1 }]);
    const deps = run(await linked(), new MemoryGroceries({ milk: picked('milk', MILK) }), shop);
    const result = await pushToCheckersCart(deps, call(['milk'], { milk: 3 }));
    expect(deps.shop.sent).toEqual([
      [expect.objectContaining({ lineId: 'l1', productId: MILK, quantity: 3 })],
    ]);
    expect(result.added.map((line) => line.itemId)).toEqual(['milk']);
    expect(result.cartItemCount).toBe(3);
    const again = await pushToCheckersCart(deps, call(['milk'], { milk: 3 }));
    expect(again.cartItemCount).toBe(3);
    expect(deps.shop.sent).toHaveLength(1);
  });

  it('says low stock when Checkers takes fewer packs, and out of stock when it takes none', async () => {
    const groceries = new MemoryGroceries({
      milk: picked('milk', MILK),
      bread: picked('bread', BREAD),
    });
    const deps = run(await linked(), groceries);
    deps.shop.stockOf[MILK] = 2;
    deps.shop.stockOf[BREAD] = 0;
    const result = await pushToCheckersCart(deps, call(['milk', 'bread'], { milk: 5, bread: 1 }));
    expect(result.added).toEqual([]);
    expect(result.skipped).toEqual([
      { itemId: 'milk', reason: 'low-stock' },
      { itemId: 'bread', reason: 'out-of-stock' },
    ]);
    expect(result.cartItemCount).toBe(2);
  });

  it('gives every skip its reason', async () => {
    const shop = new ScriptedShop();
    const groceries = new MemoryGroceries({
      typed: { itemId: 'typed', isBought: false, pick: null },
      bought: { ...picked('bought', MILK), isBought: true },
      steak: picked('steak', BREAD, 'KG'),
      gone: picked('gone', GONE),
      empty: picked('empty', '0000aaaa0000aaaa0000aaaa'),
      other: {
        itemId: 'other',
        isBought: false,
        pick: { retailer: 'pnp', productId: MILK, articleCode: 'x', unitOfMeasure: 'EA' },
      },
    });
    const deps = run(await linked(), groceries, shop);
    shop.catalogue['0000aaaa0000aaaa0000aaaa'] = product('0000aaaa0000aaaa0000aaaa', {
      isInStock: false,
    });
    const ids = ['typed', 'bought', 'steak', 'gone', 'empty', 'other', 'missing'];
    const result = await pushToCheckersCart(deps, call(ids));
    expect(result.added).toEqual([]);
    expect(Object.fromEntries(result.skipped.map((skip) => [skip.itemId, skip.reason]))).toEqual({
      typed: 'no-match',
      bought: 'not-found',
      steak: 'weighed-item',
      gone: 'not-found',
      empty: 'out-of-stock',
      other: 'no-match',
      missing: 'not-found',
    });
    expect(deps.shop.sent).toEqual([]);
  });

  it('skips a product Checkers now sells by weight, whatever the pick said', async () => {
    const deps = run(await linked(), new MemoryGroceries({ milk: picked('milk', MILK) }));
    deps.shop.catalogue[MILK] = product(MILK, { isSoldByWeight: true });
    const result = await pushToCheckersCart(deps, call(['milk']));
    expect(result.skipped).toEqual([{ itemId: 'milk', reason: 'weighed-item' }]);
  });

  it('finds a product by article code when its id is no longer known', async () => {
    const deps = run(await linked(), new MemoryGroceries({ gone: picked('gone', GONE) }));
    const reissued = product('aaaaaaaaaaaaaaaaaaaaaaaa');
    deps.shop.byArticle['12345678EA'] = reissued;
    const result = await pushToCheckersCart(deps, call(['gone']));
    expect(result.added).toEqual([expect.objectContaining({ productId: reissued.productId })]);
  });
});

describe('refusing to fill the cart', () => {
  const groceries = (): MemoryGroceries => new MemoryGroceries({ milk: picked('milk', MILK) });

  it('when the member never linked', async () => {
    const deps = run(new MemoryLinkStore(), groceries());
    expect(await refusal(pushToCheckersCart(deps, call(['milk'])))).toBe('checkers-link-expired');
  });

  it('when the hour is up', async () => {
    const deps = run(await linked({ expiresAt: NOW }), groceries());
    expect(await refusal(pushToCheckersCart(deps, call(['milk'])))).toBe('checkers-link-expired');
    expect(deps.shop.sent).toEqual([]);
  });

  it('when Checkers stops accepting the session mid-way', async () => {
    const deps = run(await linked(), groceries());
    deps.shop.failWith = new CheckersSessionExpired();
    expect(await refusal(pushToCheckersCart(deps, call(['milk'])))).toBe('checkers-link-expired');
  });

  it('when the session was sealed under another key', async () => {
    const deps = run(await linked(), groceries());
    const other = { ...deps, key: Buffer.alloc(32, 1) };
    expect(await refusal(pushToCheckersCart(other, call(['milk'])))).toBe('checkers-link-expired');
  });

  it('when no Sixty60 store delivers to the member', async () => {
    const deps = run(await linked({ stores: false }), groceries());
    expect(await refusal(pushToCheckersCart(deps, call(['milk'])))).toBe('no-checkers-store');
  });

  it('when Checkers cannot be reached', async () => {
    const deps = run(await linked(), groceries());
    deps.shop.failWith = new CheckersUnavailable('status 503');
    expect(await refusal(pushToCheckersCart(deps, call(['milk'])))).toBe('checkers-down');
  });
});

describe('who may fill a cart from a list', () => {
  const household = (role: string, access?: unknown): Record<string, unknown> => ({
    members: { [UID]: role },
    ...(access === undefined ? {} : { access: { [UID]: access } }),
  });

  it('a family member, or a helper who may see the groceries', () => {
    expect(() => {
      requireGroceryReader(household('parent'), UID);
    }).not.toThrow();
    expect(() => {
      requireGroceryReader(household('helper', ROLE_DEFAULTS.helper), UID);
    }).not.toThrow();
  });

  it('not somebody whose grant hides the groceries, nor a stranger', () => {
    const hidden = { ...uniformGrant('edit'), groceries: 'none' };
    const reasons = [household('carer', hidden), { members: {} }, 'not a household'].map((data) => {
      try {
        requireGroceryReader(data, UID);
        return 'allowed';
      } catch (error) {
        return (error as HttpsError).details;
      }
    });
    expect(reasons).toEqual([
      { reason: 'not-a-member' },
      { reason: 'not-a-member' },
      { reason: 'not-a-member' },
    ]);
  });
});

describe('a grocery item as a push reads it', () => {
  it('reads the pick and whether it is bought, and nothing it cannot trust', () => {
    expect(
      groceryLineOf('milk', {
        name: 'Milk',
        boughtBy: null,
        productMatch: {
          retailer: 'checkers',
          productId: MILK,
          articleCode: '10136729EA',
          unitOfMeasure: 'EA',
          priceCents: 1,
        },
      }),
    ).toEqual({
      itemId: 'milk',
      isBought: false,
      pick: {
        retailer: 'checkers',
        productId: MILK,
        articleCode: '10136729EA',
        unitOfMeasure: 'EA',
      },
    });
    expect(groceryLineOf('x', { boughtBy: 'm-sam', productMatch: { productId: 5 } })).toEqual({
      itemId: 'x',
      isBought: true,
      pick: null,
    });
  });
});
