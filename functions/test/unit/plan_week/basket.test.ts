import { describe, expect, it } from 'vitest';

import { weekBasketCents, type NewBox } from '../../../src/plan_week/basket';

const box = (productId: string, name = productId): NewBox => ({ productId, slot: 'snack', name });

describe('the basket is what the till charges, in whole packs (lunch-box ADR-0012)', () => {
  it('rounds boxes up to whole packs, for every child together', () => {
    const boxes = Array.from({ length: 10 }, () => box('yoghurt'));
    expect(weekBasketCents([], boxes, () => ({ boxesPerPack: 6, priceCents: 4599 }))).toBe(9198);
  });

  it('sums every product, each rounded on its own', () => {
    const packs: Record<string, { boxesPerPack: number; priceCents: number }> = {
      apples: { boxesPerPack: 1, priceCents: 800 },
      wraps: { boxesPerPack: 8, priceCents: 3299 },
    };
    const cents = weekBasketCents([], [box('apples'), box('wraps')], (id) => {
      const pack = packs[id];
      if (pack === undefined) throw new Error(id);
      return pack;
    });
    expect(cents).toBe(4099);
  });
});
