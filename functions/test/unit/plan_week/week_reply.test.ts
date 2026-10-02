import { describe, expect, it } from 'vitest';

import {
  isProductAllowedFor,
  weekBriefFrom,
  type WeekBrief,
} from '../../../src/plan_week/week_brief';
import { weekFrom } from '../../../src/plan_week/week_reply';
import type { FoundIdea } from '../../../src/plan_week/schemas';
import type { LunchPlanFacts } from '../../../src/plan_week/week_documents';
import { productOf, rulesOf } from './fixtures';

const MONDAY = '2026-10-05';
const MIA = rulesOf({ allergyCodes: ['milk'] });
const LEO = rulesOf();

const IDEAS: FoundIdea[] = [
  {
    id: 'fruit-idea',
    slot: 'fruit',
    childIds: ['mia', 'leo'],
    fromAisle: false,
    products: [productOf({ productId: 'apples', packQuantity: 6 })],
  },
  {
    id: 'snack-idea',
    slot: 'snack',
    childIds: ['mia', 'leo'],
    fromAisle: false,
    products: [productOf({ productId: 'yoghurt', name: 'Yoghurt 6 x 100g', allergens: ['milk'] })],
  },
  {
    id: 'treat-idea',
    slot: 'treat',
    childIds: ['leo'],
    fromAisle: false,
    products: [productOf({ productId: 'muffins', name: 'Mini muffins', allergensKnown: false })],
  },
];

const PACKED_MONDAY_FRUIT: LunchPlanFacts = {
  childId: 'leo',
  weekStart: MONDAY,
  slots: { '1_fruit': { itemId: 'x', name: 'Pear', allergens: [] } },
  feedback: {},
};

function brief(): WeekBrief {
  return weekBriefFrom(
    IDEAS,
    [
      { memberId: 'mia', rules: MIA },
      { memberId: 'leo', rules: LEO },
    ],
    [PACKED_MONDAY_FRUIT],
    MONDAY,
    20000,
  );
}

describe('a product the phone found, checked again before the model sees it', () => {
  it('is not offered to a child who must avoid what it contains', () => {
    const yoghurt = brief().products.find((p) => p.product.productId === 'yoghurt');
    expect(yoghurt?.childRefs).toEqual(['child-2']);
  });

  it('is not offered to a child with any allergy when the store did not say what is in it', () => {
    const unknown = productOf({ allergensKnown: false });
    expect(isProductAllowedFor(MIA, unknown)).toBe(false);
    expect(isProductAllowedFor(rulesOf({ otherAllergies: ['kiwi'] }), unknown)).toBe(false);
    expect(isProductAllowedFor(LEO, unknown)).toBe(true);
  });

  it('reads allergens from the name too, whatever the phone sent', () => {
    expect(isProductAllowedFor(MIA, productOf({ name: 'Cheddar cheese slices' }))).toBe(false);
  });

  it('drops a product no child may have, and counts it', () => {
    const milkIdea: FoundIdea = {
      id: 'snack-idea',
      slot: 'snack',
      childIds: ['mia'],
      fromAisle: false,
      products: [productOf({ name: 'Yoghurt 6 x 100g', allergens: ['milk'] })],
    };
    const onlyMilk = weekBriefFrom([milkIdea], [{ memberId: 'mia', rules: MIA }], [], MONDAY, null);
    expect(onlyMilk.products).toEqual([]);
    expect(onlyMilk.removed).toBe(1);
  });
});

describe("the model's week, checked choice by choice", () => {
  const lunch = (
    child: string,
    day: number,
    slot: string,
    product: string,
  ): Record<string, unknown> => ({ child, day, slot, product });

  it('keeps a choice that fits and maps it back to ids', () => {
    const week = weekFrom({ packs: [], lunches: [lunch('child-1', 2, 'fruit', 'p-1')] }, brief());
    expect(week.lunches).toEqual([
      { childId: 'mia', day: 2, slot: 'fruit', ideaId: 'fruit-idea', productId: 'apples' },
    ]);
    expect(week.dropped).toBe(0);
  });

  it('drops the wrong slot, an unknown product, a closed compartment, a weekday treat, a child not allowed', () => {
    const week = weekFrom(
      {
        packs: [],
        lunches: [
          lunch('child-1', 2, 'snack', 'p-1'),
          lunch('child-1', 2, 'fruit', 'p-99'),
          lunch('child-2', 1, 'fruit', 'p-1'),
          lunch('child-2', 3, 'treat', 'p-3'),
          lunch('child-1', 2, 'snack', 'p-2'),
          lunch('child-3', 2, 'fruit', 'p-1'),
        ],
      },
      brief(),
    );
    expect(week.lunches).toEqual([]);
    expect(week.dropped).toBe(6);
  });

  it('takes a compartment once', () => {
    const week = weekFrom(
      {
        packs: [],
        lunches: [lunch('child-2', 5, 'treat', 'p-3'), lunch('child-2', 5, 'treat', 'p-3')],
      },
      brief(),
    );
    expect(week.lunches).toHaveLength(1);
    expect(week.dropped).toBe(1);
  });

  it("sizes each used pack from the model, else the pack's own count, else one, within 1..100", () => {
    const week = weekFrom(
      {
        packs: [
          { product: 'p-2', boxesPerPack: 500 },
          { product: 'p-3', boxesPerPack: 0 },
        ],
        lunches: [
          lunch('child-1', 1, 'fruit', 'p-1'),
          lunch('child-2', 2, 'snack', 'p-2'),
          lunch('child-2', 5, 'treat', 'p-3'),
        ],
      },
      brief(),
    );
    expect(week.packs).toEqual([
      { productId: 'apples', boxesPerPack: 6 },
      { productId: 'yoghurt', boxesPerPack: 100 },
      { productId: 'muffins', boxesPerPack: 1 },
    ]);
  });
});
