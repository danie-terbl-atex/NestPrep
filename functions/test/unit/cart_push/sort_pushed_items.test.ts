import { describe, expect, it } from 'vitest';

import { mayReadGroceries } from '../../../src/cart_push/grocery_reader';
import { sortPushedItems } from '../../../src/cart_push/sort_pushed_items';
import { pnpPicked } from '../pnp/fakes';

/** What every shop's push leaves out before asking the shop anything. */
const PNP = { retailer: 'pickNPay', isWeighedUnit: (unit: string): boolean => unit === 'KGM' };

describe('sorting the items a push names', () => {
  it('wants an unbought item picked at this shop', () => {
    const sorted = sortPushedItems(['i1'], { i1: pnpPicked('i1', '000000000000838685_EA') }, PNP);
    expect(sorted.wanted.map((want) => want.itemId)).toEqual(['i1']);
    expect(sorted.skipped).toEqual([]);
  });

  it('leaves out what is gone or bought, picked elsewhere, unpicked or weighed', () => {
    const checkers = {
      itemId: 'c',
      isBought: false,
      pick: {
        retailer: 'checkers',
        productId: 'a'.repeat(24),
        articleCode: '1EA',
        unitOfMeasure: 'EA',
      },
    };
    const sorted = sortPushedItems(
      ['gone', 'bought', 'c', 'none', 'kg'],
      {
        bought: pnpPicked('bought', '000000000000838685_EA', true),
        c: checkers,
        none: { itemId: 'none', isBought: false, pick: null },
        kg: pnpPicked('kg', '000000000000123456_KGM'),
      },
      PNP,
    );
    expect(sorted.skipped).toEqual([
      { itemId: 'gone', reason: 'not-found' },
      { itemId: 'bought', reason: 'not-found' },
      { itemId: 'c', reason: 'no-match' },
      { itemId: 'none', reason: 'no-match' },
      { itemId: 'kg', reason: 'weighed-item' },
    ]);
  });
});

describe('who may push a household’s list', () => {
  it('a member who can see groceries may', () => {
    expect(mayReadGroceries({ members: { u1: 'parent' } }, 'u1')).toBe(true);
  });

  it('a stranger, or a household that does not read, may not', () => {
    expect(mayReadGroceries({ members: { u1: 'parent' } }, 'u2')).toBe(false);
    expect(mayReadGroceries({ nothing: true }, 'u1')).toBe(false);
  });
});
