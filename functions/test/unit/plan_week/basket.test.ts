import { describe, expect, it } from 'vitest';

import { basketCents, basketLines } from '../../../src/plan_week/basket';

describe('the basket is what the till charges, in whole packs (lunch-box ADR-0012)', () => {
  it('rounds boxes up to whole packs, for every child together', () => {
    const lunches = Array.from({ length: 10 }, () => ({ productId: 'yoghurt' }));
    const lines = basketLines(lunches, [
      { productId: 'yoghurt', boxesPerPack: 6, priceCents: 4599 },
    ]);
    expect(lines).toEqual([{ productId: 'yoghurt', boxes: 10, packs: 2, cents: 9198 }]);
  });

  it('leaves out a pack nobody uses, and sums the rest', () => {
    const lines = basketLines(
      [{ productId: 'apples' }, { productId: 'wraps' }],
      [
        { productId: 'apples', boxesPerPack: 1, priceCents: 800 },
        { productId: 'wraps', boxesPerPack: 8, priceCents: 3299 },
        { productId: 'unused', boxesPerPack: 1, priceCents: 999 },
      ],
    );
    expect(lines.map((line) => line.productId)).toEqual(['apples', 'wraps']);
    expect(basketCents(lines)).toBe(4099);
  });
});
