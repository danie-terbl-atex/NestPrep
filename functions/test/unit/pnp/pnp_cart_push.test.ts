import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { PnpUnavailable } from '../../../src/pnp/pnp_api';
import { pushToPnpCart, type PnpCartPushDeps } from '../../../src/pnp/pnp_cart_push';
import { sealSessionTokens } from '../../../src/pnp/pnp_sealed_values';
import { MemoryGroceries } from '../checkers/fakes';
import {
  KEY,
  MemoryPnpLinks,
  NOW,
  ScriptedPnpLogin,
  ScriptedPnpShop,
  UID,
  pnpPicked,
  pnpProduct,
} from './fakes';

/**
 * A push into the member's own PnP cart end to end, with PnP and Firestore
 * scripted (add-to-pnp ADR-0004): the server reads the list itself, re-prices
 * at the cart's store, raises lines absolutely, and a second push is a no-op.
 */
const CHIPS = '000000000000838685_EA';

interface SetUp {
  readonly deps: PnpCartPushDeps;
  readonly shop: ScriptedPnpShop;
  readonly links: MemoryPnpLinks;
}

async function setUp(lines = { i1: pnpPicked('i1', CHIPS) }): Promise<SetUp> {
  const links = new MemoryPnpLinks();
  links.links[UID] = {
    pending: null,
    session: {
      sealed: await sealSessionTokens(KEY, UID, {
        accessToken: 'access-0',
        refreshToken: 'refresh-0',
      }),
      accessExpiresAt: new Date(NOW.getTime() + 600_000),
      linkedAt: NOW,
    },
  };
  const shop = new ScriptedPnpShop();
  shop.catalogue[CHIPS] = pnpProduct(CHIPS, { priceCents: 2199 });
  const deps = {
    links,
    login: new ScriptedPnpLogin(),
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

describe('pushing to a PnP cart', () => {
  it('puts the asked packs in and answers the cart after', async () => {
    const { deps, shop } = await setUp();
    const result = await pushToPnpCart(deps, call);
    expect(shop.writes).toEqual([`add ${CHIPS} 3`]);
    expect(result.added).toEqual([
      { itemId: 'i1', productId: CHIPS, name: 'Product 8685', priceCents: 2199 },
    ]);
    expect(result.cartItemCount).toBe(3);
  });

  it('pushing the same week again writes nothing (BE-06)', async () => {
    const { deps, shop } = await setUp();
    await pushToPnpCart(deps, call);
    await pushToPnpCart(deps, call);
    expect(shop.writes).toEqual([`add ${CHIPS} 3`]);
  });

  it('pushing more packs later raises the line by guid', async () => {
    const { deps, shop } = await setUp();
    await pushToPnpCart(deps, call);
    await pushToPnpCart(deps, { ...call, quantities: { i1: 5 } });
    expect(shop.writes).toEqual([`add ${CHIPS} 3`, `set g-${CHIPS} 5`]);
  });

  it('one pack each when the phone does not say', async () => {
    const { deps, shop } = await setUp();
    await pushToPnpCart(deps, { ...call, quantities: {} });
    expect(shop.writes).toEqual([`add ${CHIPS} 1`]);
  });

  it('a product the cart’s store does not range is not-found, and nothing is written', async () => {
    const { deps, shop } = await setUp({ i1: pnpPicked('i1', '000000000000999999_EA') });
    const result = await pushToPnpCart(deps, call);
    expect(result.skipped).toEqual([{ itemId: 'i1', reason: 'not-found' }]);
    expect(shop.writes).toEqual([]);
  });

  it('an item the list no longer has is skipped without asking PnP about it', async () => {
    const { deps } = await setUp();
    const result = await pushToPnpCart(deps, { ...call, itemIds: ['missing'] });
    expect(result.skipped).toEqual([{ itemId: 'missing', reason: 'not-found' }]);
  });

  it('PnP not answering is pnp-down', async () => {
    const { deps, shop } = await setUp();
    shop.failWith = new PnpUnavailable('status 503');
    await expect(pushToPnpCart(deps, call)).rejects.toSatisfy((e) => reasonOf(e) === 'pnp-down');
  });

  it('a member never linked is told to link', async () => {
    const { deps, links } = await setUp();
    links.links[UID] = { pending: null, session: null };
    await expect(pushToPnpCart(deps, call)).rejects.toSatisfy(
      (e) => reasonOf(e) === 'pnp-link-expired',
    );
  });

  it('a cart with no store asks for a delivery address, and writes nothing', async () => {
    const { deps, shop } = await setUp();
    shop.cart = { ...shop.cart, storeCode: null };
    await expect(pushToPnpCart(deps, call)).rejects.toSatisfy(
      (e) => reasonOf(e) === 'pnp-no-delivery-address',
    );
    expect(shop.writes).toEqual([]);
  });

  it('a line PnP takes short is skipped with PnP’s reason, and the rest still go in', async () => {
    const OTHER = '000000000000111111_EA';
    const { deps, shop } = await setUp({
      i1: pnpPicked('i1', CHIPS),
      i2: pnpPicked('i2', OTHER),
    });
    shop.catalogue[OTHER] = pnpProduct(OTHER);
    shop.shortOn[CHIPS] = 'low-stock';
    const result = await pushToPnpCart(deps, { ...call, itemIds: ['i1', 'i2'] });
    expect(result.skipped).toEqual([{ itemId: 'i1', reason: 'low-stock' }]);
    expect(result.added.map((line) => line.itemId)).toEqual(['i2']);
    expect(shop.writes).toEqual([`add ${CHIPS} 3`, `add ${OTHER} 1`]);
  });

  it('a raise stops at the product’s order limit', async () => {
    const { deps, shop } = await setUp();
    shop.catalogue[CHIPS] = pnpProduct(CHIPS, { maxOrderQuantity: 2 });
    await pushToPnpCart(deps, { ...call, quantities: { i1: 5 } });
    expect(shop.writes).toEqual([`add ${CHIPS} 2`]);
  });

  it('looks products up four at a time, not one after another', async () => {
    const codes = Array.from({ length: 9 }, (_, i) => `00000000000010000${String(i)}_EA`);
    const lines = Object.fromEntries(
      codes.map((code, i) => [`i${String(i)}`, pnpPicked(`i${String(i)}`, code)]),
    );
    const { deps, shop } = await setUp(lines);
    for (const code of codes) shop.catalogue[code] = pnpProduct(code);
    await pushToPnpCart(deps, { ...call, itemIds: Object.keys(lines), quantities: {} });
    expect(shop.lookupsAtOnce).toBe(4);
  });
});
