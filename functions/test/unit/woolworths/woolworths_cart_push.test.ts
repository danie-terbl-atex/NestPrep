import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { WoolworthsRejected, WoolworthsUnavailable } from '../../../src/woolworths/woolworths_api';
import {
  pushToWoolworthsCart,
  type WoolworthsCartPushDeps,
} from '../../../src/woolworths/woolworths_cart_push';
import { planWoolworthsPush } from '../../../src/woolworths/woolworths_push_plan';
import { sealSessionTokens } from '../../../src/woolworths/woolworths_sealed_values';
import type { GroceryLine } from '../../../src/cart_push/grocery_lines';
import { MemoryGroceries } from '../checkers/fakes';
import {
  EMPTY_CART,
  KEY,
  MemoryWoolworthsLinks,
  NOW,
  ScriptedWoolworthsLogin,
  ScriptedWoolworthsShop,
  UID,
  woolworthsPicked,
  woolworthsProduct,
} from './fakes';

const MILK = '20011697';
const BREAD = '6009204330856';

interface SetUp {
  readonly deps: WoolworthsCartPushDeps;
  readonly shop: ScriptedWoolworthsShop;
  readonly links: MemoryWoolworthsLinks;
}

async function setUp(
  lines: Record<string, GroceryLine> = { i1: woolworthsPicked('i1', MILK) },
): Promise<SetUp> {
  const links = new MemoryWoolworthsLinks();
  links.links[UID] = {
    session: {
      sealed: await sealSessionTokens(KEY, UID, { refreshToken: 'refresh-0', idToken: 'id-0' }),
      idExpiresAt: new Date(NOW.getTime() + 600_000),
      linkedAt: NOW,
      emailMasked: null,
    },
  };
  const shop = new ScriptedWoolworthsShop();
  shop.catalogue[MILK] = woolworthsProduct(MILK, {
    name: 'Fresh Full Cream Milk 2 L',
    priceCents: 4099,
  });
  shop.catalogue[BREAD] = woolworthsProduct(BREAD);
  const deps = {
    links,
    login: new ScriptedWoolworthsLogin(),
    shop,
    groceries: new MemoryGroceries(lines),
    key: KEY,
    now: NOW,
  };
  return { deps, shop, links };
}

function reasonOf(error: unknown): unknown {
  return error instanceof HttpsError ? (error.details as { reason?: string }).reason : error;
}

const call = { uid: UID, householdId: 'h1', itemIds: ['i1'], quantities: { i1: 3 } };

describe('pushing to a Dash cart', () => {
  it('adds the asked packs in one POST, re-priced by Woolworths, and answers the cart after', async () => {
    const { deps, shop } = await setUp();
    const result = await pushToWoolworthsCart(deps, call);
    expect(shop.posts).toEqual([[{ sku: MILK, quantity: 3 }]]);
    expect(result.added).toEqual([
      { itemId: 'i1', productId: MILK, name: 'Fresh Full Cream Milk 2 L', priceCents: 4099 },
    ]);
    expect(result.cartItemCount).toBe(3);
    expect(result.cartTotalCents).toBe(3 * 4099);
  });

  it('adds only what the cart is short of, and a second push adds nothing', async () => {
    const { deps, shop } = await setUp();
    shop.cart = { ...EMPTY_CART, lines: [{ sku: MILK, quantity: 1 }], itemCount: 1 };
    await pushToWoolworthsCart(deps, call);
    const again = await pushToWoolworthsCart(deps, call);
    expect(shop.posts).toEqual([[{ sku: MILK, quantity: 2 }]]);
    expect(again.added.map((line) => line.itemId)).toEqual(['i1']);
  });

  it('never lowers a line the member already has more of', async () => {
    const { deps, shop } = await setUp();
    shop.cart = { ...EMPTY_CART, lines: [{ sku: MILK, quantity: 6 }], itemCount: 6 };
    const result = await pushToWoolworthsCart(deps, call);
    expect(shop.posts).toEqual([]);
    expect(result.cartItemCount).toBe(6);
  });

  it('two items on one SKU add their packs together, all in the one POST', async () => {
    const { deps, shop } = await setUp({
      i1: woolworthsPicked('i1', MILK),
      i2: woolworthsPicked('i2', MILK),
      i3: woolworthsPicked('i3', BREAD),
    });
    await pushToWoolworthsCart(deps, {
      ...call,
      itemIds: ['i1', 'i2', 'i3'],
      quantities: { i1: 2 },
    });
    expect(shop.posts).toEqual([
      [
        { sku: MILK, quantity: 3 },
        { sku: BREAD, quantity: 1 },
      ],
    ]);
  });

  it('skips a weighed pick without asking Woolworths, and a product Woolworths weighs', async () => {
    const AVG = '2000000123456';
    const { deps, shop } = await setUp({
      meat: woolworthsPicked('meat', AVG, 'KG'),
      steak: woolworthsPicked('steak', '20099999'),
    });
    shop.catalogue['20099999'] = woolworthsProduct('20099999', { isWeighed: true });
    const result = await pushToWoolworthsCart(deps, {
      ...call,
      itemIds: ['meat', 'steak'],
      quantities: {},
    });
    expect(result.skipped).toEqual([
      { itemId: 'meat', reason: 'weighed-item' },
      { itemId: 'steak', reason: 'weighed-item' },
    ]);
    expect(shop.posts).toEqual([]);
  });

  it('a product Woolworths does not answer for is not-found, an unmatched item no-match', async () => {
    const { deps } = await setUp({
      gone: woolworthsPicked('gone', '99900000'),
      typed: { itemId: 'typed', isBought: false, pick: null },
    });
    const result = await pushToWoolworthsCart(deps, {
      ...call,
      itemIds: ['gone', 'typed', 'missing'],
      quantities: {},
    });
    expect(result.skipped).toEqual([
      { itemId: 'typed', reason: 'no-match' },
      { itemId: 'missing', reason: 'not-found' },
      { itemId: 'gone', reason: 'not-found' },
    ]);
  });

  it('a product the cart took none of is out-of-stock, one it took some of low-stock', async () => {
    const { deps, shop } = await setUp({
      i1: woolworthsPicked('i1', MILK),
      i2: woolworthsPicked('i2', BREAD),
    });
    shop.takesAtMost[MILK] = 0;
    shop.takesAtMost[BREAD] = 1;
    const result = await pushToWoolworthsCart(deps, {
      ...call,
      itemIds: ['i1', 'i2'],
      quantities: { i1: 2, i2: 4 },
    });
    expect(result.added).toEqual([]);
    expect(result.skipped).toEqual([
      { itemId: 'i1', reason: 'out-of-stock' },
      { itemId: 'i2', reason: 'low-stock' },
    ]);
    expect(result.cartItemCount).toBe(1);
  });

  it('a cart with no delivery store asks for an address, and adds nothing', async () => {
    const { deps, shop } = await setUp();
    shop.cart = { ...EMPTY_CART, storeId: null };
    await expect(pushToWoolworthsCart(deps, call)).rejects.toSatisfy(
      (e) => reasonOf(e) === 'woolworths-no-delivery-address',
    );
    expect(shop.posts).toEqual([]);
  });

  it('Woolworths refusing the add is woolworths-rejected; not answering is woolworths-unavailable', async () => {
    const refused = await setUp();
    refused.shop.addFailsWith = new WoolworthsRejected(400);
    await expect(pushToWoolworthsCart(refused.deps, call)).rejects.toSatisfy(
      (e) => reasonOf(e) === 'woolworths-rejected',
    );
    const down = await setUp();
    down.shop.failWith = new WoolworthsUnavailable('status 503');
    await expect(pushToWoolworthsCart(down.deps, call)).rejects.toSatisfy(
      (e) => reasonOf(e) === 'woolworths-unavailable',
    );
  });

  it('a member never linked is told to link', async () => {
    const { deps, links } = await setUp();
    Reflect.deleteProperty(links.links, UID);
    await expect(pushToWoolworthsCart(deps, call)).rejects.toSatisfy(
      (e) => reasonOf(e) === 'woolworths-not-linked',
    );
  });

  it('an IdToken the cart refuses is refreshed once and the push carries on', async () => {
    const { deps, shop } = await setUp();
    shop.refused.add('id-0');
    const result = await pushToWoolworthsCart(deps, call);
    expect(result.added).toHaveLength(1);
    expect(shop.posts).toHaveLength(1);
  });

  it('looks products up four at a time', async () => {
    const skus = Array.from({ length: 9 }, (_, i) => `2001000${String(i)}`);
    const lines = Object.fromEntries(
      skus.map((sku, i) => [`i${String(i)}`, woolworthsPicked(`i${String(i)}`, sku)]),
    );
    const { deps, shop } = await setUp(lines);
    for (const sku of skus) shop.catalogue[sku] = woolworthsProduct(sku);
    await pushToWoolworthsCart(deps, { ...call, itemIds: Object.keys(lines), quantities: {} });
    expect(shop.lookupsAtOnce).toBe(4);
  });
});

describe('the push plan', () => {
  it('asks for max(0, wanted − already in the cart) per SKU', () => {
    const plan = planWoolworthsPush(
      [
        { itemId: 'a', pick: woolworthsPicked('a', MILK).pick ?? fail() },
        { itemId: 'b', pick: woolworthsPicked('b', BREAD).pick ?? fail() },
      ],
      (itemId) => (itemId === 'a' ? 4 : 1),
      { [MILK]: woolworthsProduct(MILK), [BREAD]: woolworthsProduct(BREAD) },
      {
        ...EMPTY_CART,
        lines: [
          { sku: MILK, quantity: 1 },
          { sku: BREAD, quantity: 3 },
        ],
      },
    );
    expect(plan.adds).toEqual([{ sku: MILK, quantity: 3 }]);
    expect(plan.added.map((line) => line.itemId)).toEqual(['a', 'b']);
  });
});

function fail(): never {
  throw new Error('no pick');
}
