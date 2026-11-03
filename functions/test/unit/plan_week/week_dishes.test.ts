import { describe, expect, it } from 'vitest';

import { weekBasketCents, type InWeekItem } from '../../../src/plan_week/basket';
import type { FoundIdea, FoundProduct } from '../../../src/plan_week/schemas';
import { assembleWeek } from '../../../src/plan_week/week_assembly';
import { weekBriefFrom, type WeekBrief } from '../../../src/plan_week/week_brief';
import {
  weekDecisionRequest,
  weekDecisionsFrom,
  type WeekDecisions,
} from '../../../src/plan_week/week_decisions';
import { dishProductId } from '../../../src/plan_week/week_dishes';
import { everyPack, weekCostOf, weekPricing } from '../../../src/plan_week/week_pricing';
import { productOf, rulesOf, weekOf } from './fixtures';

/**
 * A dish in the week (lunch-box ADR-0021 §4): placed like a product, bought
 * as the first safe product per ingredient, and costed as its ingredients'
 * whole packs — so the basket and the budget carry the fillings too.
 */

const MIA = rulesOf({ allergyCodes: ['milk'] });
const LEO = rulesOf();
const twoKids = [
  { memberId: 'mia', rules: MIA },
  { memberId: 'leo', rules: LEO },
];

const tortillas = productOf({
  productId: 'tortillas',
  name: 'Wholewheat Tortillas 8 Pack',
  priceCents: 3000,
  allergens: ['wheat'],
  packQuantity: 8,
});
const chicken = productOf({ productId: 'chicken', name: 'Chicken Strips 400g', priceCents: 6000 });
const cheese = productOf({
  productId: 'cheese',
  name: 'Grated Cheddar 250g',
  priceCents: 4500,
  allergens: ['milk'],
});
const vegan = productOf({ productId: 'vegan-cheese', name: 'Plant Shreds 200g', priceCents: 5000 });

function wrapIdea(
  ingredients: { name: string; searchTerm?: string; products: FoundProduct[] }[],
  childIds = ['leo'],
): FoundIdea {
  return {
    id: 'idea-1',
    slot: 'main',
    childIds,
    fromAisle: false,
    products: [],
    dish: { name: 'Chicken wrap', ingredients },
  };
}

const WRAP_INGREDIENTS = [
  { name: 'Wholewheat tortillas', products: [tortillas] },
  { name: 'Chicken strips', products: [chicken] },
  { name: 'Grated cheese', products: [cheese, vegan] },
  { name: 'Salsa', products: [] },
];
const BUYABLE = WRAP_INGREDIENTS.slice(0, 3);

function wrapBrief(budgetCents: number | null = null, already: InWeekItem[] = []): WeekBrief {
  const brief = weekBriefFrom([wrapIdea(BUYABLE)], twoKids, weekOf([], budgetCents), {
    slots: ['main'],
    preferences: [],
    treatDays: [5],
  });
  return { ...brief, alreadyInWeek: already };
}

const sure = (brief: WeekBrief, boxes: Record<string, number> = {}): WeekDecisions => ({
  fit: Object.fromEntries(brief.products.map((p) => [p.ref, 0.9])),
  boxes,
});

describe('a dish in the brief', () => {
  it('stands under its own id, for the children its every word passes', () => {
    const brief = weekBriefFrom([wrapIdea(BUYABLE, ['mia', 'leo'])], twoKids, weekOf([], null));
    const [wrap] = brief.products;
    expect(wrap?.product.productId).toBe(dishProductId('idea-1'));
    // "cheese" in an ingredient keeps the milk-allergic child out.
    expect(wrap?.childRefs).toEqual(['child-2']);
  });

  it('buys each ingredient as the first product in the store’s order every child may have', () => {
    const lactoseFree = rulesOf({ dislikes: ['cheddar'] });
    const brief = weekBriefFrom(
      [
        wrapIdea([
          { name: 'Wholewheat tortillas', products: [tortillas] },
          { name: 'Shredded topping', products: [cheese, vegan] },
        ]),
      ],
      [{ memberId: 'leo', rules: lactoseFree }],
      weekOf([], null),
    );
    expect(brief.products[0]?.parts?.map((part) => part.product.productId)).toEqual([
      'tortillas',
      'vegan-cheese',
    ]);
  });

  it('is never planned with an ingredient the store had nothing for (ADR-0023 §2)', () => {
    const brief = weekBriefFrom([wrapIdea(WRAP_INGREDIENTS)], twoKids, weekOf([], null));
    expect(brief.products).toEqual([]);
    expect(brief.removed).toBe(1);
  });

  it('goes only to a child every ingredient has a safe product for (ADR-0023 §2)', () => {
    // The only cheese is dairy: the milk-allergic child loses the dish, the other keeps it.
    const brief = weekBriefFrom(
      [
        wrapIdea(
          [
            { name: 'Wholewheat tortillas', products: [tortillas] },
            { name: 'Topping', products: [cheese] },
          ],
          ['mia', 'leo'],
        ),
      ],
      twoKids,
      weekOf([], null),
    );
    expect(brief.products[0]?.childRefs).toEqual(['child-2']);
    expect(brief.products[0]?.parts?.map((part) => part.product.productId)).toEqual([
      'tortillas',
      'cheese',
    ]);
  });

  it('is read on its ingredients’ search words (ADR-0023 §1)', () => {
    const peanutChild = rulesOf({ allergyCodes: ['peanut'] });
    const brief = weekBriefFrom(
      [
        {
          ...wrapIdea([{ name: 'Spread', searchTerm: 'peanut butter', products: [chicken] }]),
          childIds: ['mia'],
        },
      ],
      [{ memberId: 'mia', rules: peanutChild }],
      weekOf([], null),
    );
    expect(brief.products).toEqual([]);
  });

  it('is dropped and counted when no child may have it', () => {
    const brief = weekBriefFrom(
      [wrapIdea(BUYABLE, ['mia'])],
      [{ memberId: 'mia', rules: MIA }],
      weekOf([], null),
    );
    expect(brief.products).toEqual([]);
    expect(brief.removed).toBe(1);
  });

  it('is only ever a main — a dish sent on a snack is read as its products', () => {
    const snack = { ...wrapIdea(WRAP_INGREDIENTS), slot: 'snack' as const, products: [chicken] };
    const brief = weekBriefFrom([snack], twoKids, weekOf([], null));
    expect(brief.products.map((p) => p.product.productId)).toEqual(['chicken']);
  });
});

describe('what Jev is asked about a dish', () => {
  it('scores the dish by what it is made with, and asks pack counts only for ingredients without one', () => {
    const request = weekDecisionRequest(wrapBrief());
    expect(Object.keys(request.questions).sort()).toEqual(
      ['fit|p-1', 'boxes|i-2', 'boxes|i-3'].sort(),
    );
    const fit = JSON.stringify(request.questions['fit|p-1']);
    expect(fit).toContain('Chicken wrap');
    expect(fit).toContain('Grated cheese');
    expect(JSON.stringify(request.questions['boxes|i-2'])).toContain('lunch boxes of `dish`');
  });

  it('reads an ingredient’s pack count back under its own ref', () => {
    const brief = wrapBrief();
    const decisions = weekDecisionsFrom(
      { 'fit|p-1': { type: 'noul', noul: 0.8 }, 'boxes|i-2': { type: 'choice', choice: '6' } },
      brief,
    );
    expect(decisions.boxes).toEqual({ 'i-2': 6 });
  });
});

describe('a dish in the week', () => {
  it('is placed like a product and answers with the products it is bought as', () => {
    const brief = wrapBrief();
    const week = assembleWeek(brief, sure(brief, { 'i-2': 4, 'i-3': 10 }));
    expect(week.lunches).toHaveLength(5);
    expect(week.lunches.every((lunch) => lunch.productId === 'dish:idea-1')).toBe(true);
    expect(week.dishes).toEqual([
      {
        ideaId: 'idea-1',
        parts: [
          { ingredient: 'Wholewheat tortillas', productId: 'tortillas' },
          { ingredient: 'Chicken strips', productId: 'chicken' },
          { ingredient: 'Grated cheese', productId: 'cheese' },
        ],
      },
    ]);
    expect(week.packs).toEqual([
      { productId: 'tortillas', boxesPerPack: 8 },
      { productId: 'chicken', boxesPerPack: 4 },
      { productId: 'cheese', boxesPerPack: 10 },
    ]);
  });

  it('costs five wraps as their ingredients in whole packs — fillings included', () => {
    const brief = wrapBrief();
    const week = assembleWeek(brief, sure(brief, { 'i-2': 4, 'i-3': 10 }));
    // 1 pack of tortillas, 2 of chicken (5 boxes, 4 a pack), 1 of cheese.
    expect(week.weekCents).toBe(3000 + 2 * 6000 + 4500);
  });

  it('is swapped for a cheaper main when the week is over budget', () => {
    const bread = productOf({
      productId: 'bread',
      name: 'Bread rolls 6 Pack',
      priceCents: 2000,
      packQuantity: 6,
    });
    const brief = weekBriefFrom(
      [
        wrapIdea(BUYABLE),
        { id: 'idea-2', slot: 'main', childIds: ['leo'], fromAisle: false, products: [bread] },
      ],
      twoKids,
      weekOf([], 2500),
      { slots: ['main'], preferences: [], treatDays: [5] },
    );
    const decisions: WeekDecisions = {
      fit: { 'p-1': 0.95, 'p-2': 0.5 },
      boxes: { 'i-2': 4, 'i-3': 10 },
    };
    const week = assembleWeek(brief, decisions);
    expect(week.lunches.every((lunch) => lunch.productId === 'bread')).toBe(true);
    expect(week.dishes).toEqual([]);
    expect(week.weekCents).toBe(2000);
  });
});

describe('the basket prices a dish per dish, never as an item of the same name', () => {
  it('rounds each dish’s ingredient up to whole packs on its own', () => {
    const packOf = (): { boxesPerPack: number; priceCents: number } => ({
      boxesPerPack: 8,
      priceCents: 3000,
    });
    const cents = weekBasketCents(
      [],
      [
        { productId: 'tortillas', slot: 'main', name: 'Tortillas', forDish: 'dish:a' },
        { productId: 'tortillas', slot: 'main', name: 'Tortillas', forDish: 'dish:b' },
      ],
      packOf,
    );
    expect(cents).toBe(6000);
  });

  it('does not fold an ingredient into a packed item that happens to share its name', () => {
    const already: InWeekItem[] = [
      {
        itemId: 'rolls',
        slot: 'main',
        nameKey: 'tortillas',
        boxes: 2,
        price: { cents: 3000, portions: 8 },
      },
    ];
    const cents = weekBasketCents(
      already,
      [{ productId: 'tortillas', slot: 'main', name: 'Tortillas', forDish: 'dish:a' }],
      () => ({ boxesPerPack: 8, priceCents: 3000 }),
    );
    expect(cents).toBe(6000);
  });
});

describe('one pack size per product, for the total and the packs alike', () => {
  it('prices and lists a product found under two ideas with the same boxes per pack', () => {
    const yoghurt = productOf({ productId: 'yog', name: 'Yoghurt', priceCents: 1000 });
    const brief = weekBriefFrom(
      [
        { id: 'a', slot: 'snack', childIds: ['leo'], fromAisle: false, products: [yoghurt] },
        { id: 'b', slot: 'snack', childIds: ['leo'], fromAisle: false, products: [yoghurt] },
      ],
      [{ memberId: 'leo', rules: LEO }],
      weekOf([], null),
      { slots: ['snack'], preferences: [], treatDays: [5] },
    );
    const [first, second] = brief.products;
    if (first === undefined || second === undefined) throw new Error('two entries expected');
    // Jev reckoned the same product differently under each idea.
    const pricing = weekPricing({ fit: {}, boxes: { 'p-1': 6, 'p-2': 1 } }, [], brief.products);
    const placed = [{ product: first }, { product: second }];
    const [pack] = everyPack([first, second], pricing);
    expect(pack?.productId).toBe('yog');
    expect(weekCostOf(placed, pricing)).toBe(
      Math.ceil(placed.length / (pack?.boxesPerPack ?? 1)) * 1000,
    );
    // The smaller pack wins, whichever idea came first: never fewer packs than needed.
    expect(pack?.boxesPerPack).toBe(1);
  });
});
