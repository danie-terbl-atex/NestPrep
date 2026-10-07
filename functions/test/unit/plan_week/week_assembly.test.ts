import { describe, expect, it } from 'vitest';

import {
  isProductAllowedFor,
  weekBriefFrom,
  type WeekBrief,
} from '../../../src/plan_week/week_brief';
import { MAX_DAYS_PER_PRODUCT, assembleWeek } from '../../../src/plan_week/week_assembly';
import {
  weekDecisionRequest,
  weekDecisionsFrom,
  type WeekDecisions,
} from '../../../src/plan_week/week_decisions';
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

describe('a product the phone found, checked again before Jev sees it', () => {
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

const fits = (brief: WeekBrief, fit: Record<string, number>, boxes = {}): WeekDecisions => ({
  fit: Object.fromEntries(brief.products.map((p) => [p.ref, fit[p.ref] ?? 0.9])),
  boxes,
});

const twoKids = [
  { memberId: 'mia', rules: MIA },
  { memberId: 'leo', rules: LEO },
];

function fruitIdea(...products: Parameters<typeof productOf>[0][]): FoundIdea {
  return {
    id: 'fruit-idea',
    slot: 'fruit',
    childIds: ['mia', 'leo'],
    fromAisle: false,
    products: products.map((fields) => productOf(fields)),
  };
}

describe('what Jev is asked about the week', () => {
  it('is one fit question per product, and a pack question only when the shop gave no count', () => {
    const request = weekDecisionRequest(brief());
    expect(Object.keys(request.questions).sort()).toEqual(
      ['fit|p-1', 'fit|p-2', 'fit|p-3', 'boxes|p-2', 'boxes|p-3'].sort(),
    );
    expect(request.questions['fit|p-1']?.type).toBe('noul');
    expect(request.questions['boxes|p-2']?.type).toBe('choice');
  });

  it('carries the packing lines only when the parent chose some', () => {
    expect(weekDecisionRequest(brief()).state).not.toHaveProperty('packing');
    const packed = weekBriefFrom(IDEAS, twoKids, [], MONDAY, null, {
      slots: ['fruit', 'snack', 'treat'],
      preferences: ['noFridge'],
    });
    expect(weekDecisionRequest(packed).state).toHaveProperty('packing');
  });

  it('carries nothing about a child', () => {
    const text = JSON.stringify(weekDecisionRequest(brief())).toLowerCase();
    for (const secret of ['mia', 'leo', 'milk', 'child-']) expect(text).not.toContain(secret);
  });

  it('reads an unanswered fit as no, and a pack count only when it is a whole number', () => {
    const decisions = weekDecisionsFrom(
      {
        'fit|p-1': { type: 'noul', noul: 0.7 },
        'boxes|p-2': { type: 'choice', choice: '6' },
        'boxes|p-3': { type: 'choice', choice: 'lots' },
      },
      brief(),
    );
    expect(decisions.fit).toEqual({ 'p-1': 0.7, 'p-2': 0, 'p-3': 0 });
    expect(decisions.boxes).toEqual({ 'p-2': 6 });
  });
});

describe('the week NestPrep builds from what Jev said', () => {
  it('fills only open compartments, a treat on Friday only, and never a product a child may not have', () => {
    const b = brief();
    const week = assembleWeek(b, fits(b, {}));
    expect(week.lunches.some((l) => l.childId === 'leo' && l.day === 1 && l.slot === 'fruit')).toBe(
      false,
    );
    expect(week.lunches.filter((l) => l.slot === 'treat').every((l) => l.day === 5)).toBe(true);
    expect(week.lunches.some((l) => l.childId === 'mia' && l.productId === 'yoghurt')).toBe(false);
    expect(week.lunches.some((l) => l.childId === 'mia' && l.productId === 'muffins')).toBe(false);
  });

  it('leaves a compartment empty rather than use a product Jev says does not fit', () => {
    const b = brief();
    const week = assembleWeek(b, fits(b, { 'p-2': 0.2 }));
    expect(week.lunches.some((l) => l.productId === 'yoghurt')).toBe(false);
  });

  it('gives both children the same product on a day wherever they may both have it', () => {
    const b = weekBriefFrom(
      [fruitIdea({ productId: 'apples' }, { productId: 'pears', name: 'Pears 1kg' })],
      twoKids,
      [],
      MONDAY,
      null,
    );
    const week = assembleWeek(b, fits(b, {}));
    for (const day of [1, 2, 3, 4, 5]) {
      const both = week.lunches.filter((l) => l.day === day).map((l) => l.productId);
      expect(both).toHaveLength(2);
      expect(new Set(both).size).toBe(1);
    }
  });

  it(`uses one product on at most ${String(MAX_DAYS_PER_PRODUCT)} days for a child while another fits`, () => {
    const b = weekBriefFrom(
      [fruitIdea({ productId: 'apples' }, { productId: 'pears', name: 'Pears 1kg' })],
      [{ memberId: 'leo', rules: LEO }],
      [],
      MONDAY,
      null,
    );
    const week = assembleWeek(b, fits(b, { 'p-1': 0.95, 'p-2': 0.6 }));
    const apples = week.lunches.filter((l) => l.productId === 'apples').length;
    expect(apples).toBeLessThanOrEqual(MAX_DAYS_PER_PRODUCT);
    expect(week.lunches).toHaveLength(5);
  });

  it('repeats the only product that fits rather than leave a box empty', () => {
    const b = weekBriefFrom(
      [fruitIdea({ productId: 'apples' })],
      [{ memberId: 'leo', rules: LEO }],
      [],
      MONDAY,
      null,
    );
    expect(assembleWeek(b, fits(b, {})).lunches).toHaveLength(5);
  });

  it('swaps the dearest product for a cheaper fit while the basket is over budget', () => {
    const ideas = [
      fruitIdea(
        { productId: 'berries', name: 'Blueberries 125g', priceCents: 4999, packQuantity: 1 },
        { productId: 'apples', priceCents: 2999, packQuantity: 6 },
      ),
    ];
    const kids = [{ memberId: 'leo', rules: LEO }];
    const rich = weekBriefFrom(ideas, kids, [], MONDAY, null);
    const generous = assembleWeek(rich, fits(rich, { 'p-1': 0.99, 'p-2': 0.7 }));
    expect(generous.lunches.filter((l) => l.productId === 'berries')).toHaveLength(3);

    const tight = weekBriefFrom(ideas, kids, [], MONDAY, 5000);
    const week = assembleWeek(tight, fits(tight, { 'p-1': 0.99, 'p-2': 0.7 }));
    expect(week.lunches.every((l) => l.productId === 'apples')).toBe(true);
  });

  it("sizes each used pack from the shop's count, else Jev's, else one, within 1..100", () => {
    const b = brief();
    const week = assembleWeek(b, fits(b, {}, { 'p-2': 500 }));
    expect(week.packs).toEqual(
      expect.arrayContaining([
        { productId: 'apples', boxesPerPack: 6 },
        { productId: 'yoghurt', boxesPerPack: 100 },
        { productId: 'muffins', boxesPerPack: 1 },
      ]),
    );
  });
});
