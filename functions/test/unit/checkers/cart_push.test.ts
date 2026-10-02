import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { pushToCheckersCart, type CartPushDeps } from '../../../src/checkers/cart_push';
import { CheckersSessionExpired, CheckersUnavailable } from '../../../src/checkers/checkers_api';
import { requireGroceryReader } from '../../../src/checkers/checkers_caller';
import { groceryLineOf } from '../../../src/checkers/grocery_lines';
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

const call = (itemIds: string[]): { uid: string; householdId: string; itemIds: string[] } => ({
  uid: UID,
  householdId: 'h1',
  itemIds,
});

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
        { productId: MILK, storeId: STORE.storeId, priceCents: 3799, quantity: 1 },
        { productId: BREAD, storeId: STORE.storeId, priceCents: 1899, quantity: 1 },
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

  it('never doubles the cart: a product already in it is left alone and counted as added', async () => {
    const shop = new ScriptedShop();
    shop.cart = {
      cartId: 'cart-1',
      deliveryAddressId: 'addr-1',
      lines: [{ lineId: 'l1', productId: MILK, quantity: 1 }],
      totalCents: 3799,
    };
    const deps = run(await linked(), new MemoryGroceries({ milk: picked('milk', MILK) }), shop);
    const result = await pushToCheckersCart(deps, call(['milk']));
    expect(result.added.map((line) => line.itemId)).toEqual(['milk']);
    expect(deps.shop.sent).toEqual([]);
    expect(result.cartItemCount).toBe(1);
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
