import { describe, expect, it } from 'vitest';

import type { Wanted } from '../../../src/cart_push/push_outcome';
import { DEFAULT_CART_CAP, planPnpPush } from '../../../src/pnp/pnp_push_plan';
import { EMPTY_CART, pnpPicked, pnpProduct } from './fakes';

/**
 * What a PnP push puts in the member's cart (add-to-pnp ADR-0004): at least
 * the week's packs, never less, within the cart's cap, and the reason for
 * every item it leaves out.
 */
const CHIPS = '000000000000838685_EA';
const CHEDDARS = '000000000000539078_EA';

function wanted(...entries: [string, string][]): Wanted[] {
  return entries.map(([itemId, code]) => {
    const line = pnpPicked(itemId, code);
    if (line.pick === null) throw new Error('no pick');
    return { itemId, pick: line.pick };
  });
}

const one = (): number => 1;

describe('planning a push', () => {
  it('adds a new line of the asked packs for a product not in the cart', () => {
    const plan = planPnpPush(
      wanted(['i1', CHIPS]),
      () => 3,
      { [CHIPS]: pnpProduct(CHIPS) },
      EMPTY_CART,
    );
    expect(plan.raises).toEqual([{ productCode: CHIPS, entryGuid: null, quantity: 3 }]);
    expect(plan.added.map((line) => line.itemId)).toEqual(['i1']);
  });

  it('sums the packs of two items of one product into one line', () => {
    const plan = planPnpPush(
      wanted(['i1', CHIPS], ['i2', CHIPS]),
      (id) => (id === 'i1' ? 2 : 3),
      { [CHIPS]: pnpProduct(CHIPS) },
      EMPTY_CART,
    );
    expect(plan.raises).toEqual([{ productCode: CHIPS, entryGuid: null, quantity: 5 }]);
  });

  it('raises a line already in the cart by its guid to the wanted quantity', () => {
    const cart = {
      ...EMPTY_CART,
      itemCount: 1,
      entries: [{ guid: 'g1', productCode: CHIPS, quantity: 1 }],
    };
    const plan = planPnpPush(wanted(['i1', CHIPS]), () => 4, { [CHIPS]: pnpProduct(CHIPS) }, cart);
    expect(plan.raises).toEqual([{ productCode: CHIPS, entryGuid: 'g1', quantity: 4 }]);
  });

  it('never lowers a line the member filled further themselves, and counts it as added', () => {
    const cart = {
      ...EMPTY_CART,
      itemCount: 6,
      entries: [{ guid: 'g1', productCode: CHIPS, quantity: 6 }],
    };
    const plan = planPnpPush(wanted(['i1', CHIPS]), () => 2, { [CHIPS]: pnpProduct(CHIPS) }, cart);
    expect(plan.raises).toEqual([]);
    expect(plan.added).toHaveLength(1);
  });

  it('a second push of the same week asks for nothing more', () => {
    const cart = {
      ...EMPTY_CART,
      itemCount: 3,
      entries: [{ guid: 'g1', productCode: CHIPS, quantity: 3 }],
    };
    const plan = planPnpPush(wanted(['i1', CHIPS]), () => 3, { [CHIPS]: pnpProduct(CHIPS) }, cart);
    expect(plan.raises).toEqual([]);
  });

  it('skips with a reason what is not ranged, out of stock or weighed', () => {
    const plan = planPnpPush(
      wanted(['gone', CHIPS], ['empty', CHEDDARS], ['meat', '000000000000111111_EA']),
      one,
      {
        [CHEDDARS]: pnpProduct(CHEDDARS, { isInStock: false }),
        '000000000000111111_EA': pnpProduct('000000000000111111_EA', { isWeighed: true }),
      },
      EMPTY_CART,
    );
    expect(plan.skipped).toEqual([
      { itemId: 'gone', reason: 'not-found' },
      { itemId: 'empty', reason: 'out-of-stock' },
      { itemId: 'meat', reason: 'weighed-item' },
    ]);
    expect(plan.raises).toEqual([]);
  });

  it('skips as cart-full the item whose raise would pass the cart’s cap, and keeps the rest', () => {
    const cart = { ...EMPTY_CART, maxItems: 10, itemCount: 7 };
    const plan = planPnpPush(
      wanted(['big', CHIPS], ['small', CHEDDARS]),
      (id) => (id === 'big' ? 5 : 2),
      { [CHIPS]: pnpProduct(CHIPS), [CHEDDARS]: pnpProduct(CHEDDARS) },
      cart,
    );
    expect(plan.skipped).toEqual([{ itemId: 'big', reason: 'cart-full' }]);
    expect(plan.raises).toEqual([{ productCode: CHEDDARS, entryGuid: null, quantity: 2 }]);
  });

  it('holds to the hub stores’ 45 when PnP does not say the cap', () => {
    const cart = { ...EMPTY_CART, maxItems: null, itemCount: DEFAULT_CART_CAP };
    const plan = planPnpPush(wanted(['i1', CHIPS]), one, { [CHIPS]: pnpProduct(CHIPS) }, cart);
    expect(plan.skipped).toEqual([{ itemId: 'i1', reason: 'cart-full' }]);
  });

  it('answers each added line at the cart store’s price, not the list’s', () => {
    const plan = planPnpPush(
      wanted(['i1', CHIPS]),
      one,
      { [CHIPS]: pnpProduct(CHIPS, { priceCents: 2199, name: 'Simba Chutney 120g' }) },
      EMPTY_CART,
    );
    expect(plan.added).toEqual([
      { itemId: 'i1', productId: CHIPS, name: 'Simba Chutney 120g', priceCents: 2199 },
    ]);
  });
});
