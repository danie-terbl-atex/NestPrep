import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import { LUNCH_ITEM_NAME_LIMIT, inWeekItems, weekBasketCents } from '../../../src/plan_week/basket';
import type { FoundIdea } from '../../../src/plan_week/schemas';
import { assembleWeek } from '../../../src/plan_week/week_assembly';
import { weekBriefFrom, type WeekBrief } from '../../../src/plan_week/week_brief';
import type { LunchPlanFacts, StoredPick } from '../../../src/plan_week/week_documents';
import type { WeekDecisions } from '../../../src/plan_week/week_decisions';
import { MONDAY, productOf, rulesOf, weekOf } from './fixtures';

/**
 * The bug Daniel saw (2026-10-07): a week already holding R300 of a R500
 * budget was planned as though the whole R500 were free, so *Plan my week*
 * said "within budget" and the budget screen then read R800. The household's
 * week is one basket (lunch-box ADR-0012 §4): what is packed already plus
 * what the plan adds, rounded to whole packs together.
 */

const LEO = { memberId: 'leo', rules: rulesOf() };

const pick = (itemId: string, name: string): StoredPick => ({ itemId, name, allergens: [] });

function planOf(childId: string, slots: Record<string, StoredPick>): LunchPlanFacts {
  return { childId, weekStart: MONDAY, slots, feedback: {} };
}

/** Mia (not being planned) already has five R60 crackers packed: R300 of the week. */
const MIAS_CRACKERS = planOf(
  'mia',
  Object.fromEntries(
    [1, 2, 3, 4, 5].map((day) => [`${String(day)}_snack`, pick('crackers', 'Crackers 200g')]),
  ),
);
const CRACKER_PRICE = { crackers: { cents: 6000, portions: 1 } };

const FRUIT: FoundIdea = {
  id: 'fruit-idea',
  slot: 'fruit',
  childIds: ['leo'],
  fromAisle: false,
  products: [
    productOf({
      productId: 'berries',
      name: 'Blueberries 125g',
      priceCents: 4999,
      packQuantity: 1,
    }),
    productOf({ productId: 'apples', priceCents: 2999, packQuantity: 6 }),
  ],
};

const fits = (brief: WeekBrief, fit: Record<string, number>): WeekDecisions => ({
  fit: Object.fromEntries(brief.products.map((p) => [p.ref, fit[p.ref] ?? 0.9])),
  boxes: {},
});

function weekCents(brief: WeekBrief, lunches: readonly { productId: string }[]): number {
  const products = new Map(brief.products.map((p) => [p.product.productId, p]));
  return weekBasketCents(
    brief.alreadyInWeek,
    lunches.map(({ productId }) => {
      const found = products.get(productId);
      return { productId, slot: found?.slot ?? 'fruit', name: found?.product.name ?? '' };
    }),
    (productId) => ({
      boxesPerPack: products.get(productId)?.product.packQuantity ?? 1,
      priceCents: products.get(productId)?.product.priceCents ?? 0,
    }),
  );
}

describe('a week that already holds some of its budget', () => {
  it('is assembled within what is left, not within the whole budget', () => {
    const brief = weekBriefFrom(
      [FRUIT],
      [LEO],
      weekOf([MIAS_CRACKERS], 45000, { prices: CRACKER_PRICE }),
    );
    const week = assembleWeek(brief, fits(brief, { 'p-1': 0.99, 'p-2': 0.7 }));

    // R300 packed + three punnets and a bag of apples (R179.96) is R479.96 —
    // over R450, so the berries go for apples.
    expect(week.lunches.every((l) => l.productId === 'apples')).toBe(true);
    expect(weekCents(brief, week.lunches)).toBeLessThanOrEqual(45000);
  });

  it('still keeps the better fit when the whole week has room for it', () => {
    const brief = weekBriefFrom(
      [FRUIT],
      [LEO],
      weekOf([MIAS_CRACKERS], 60000, { prices: CRACKER_PRICE }),
    );
    const week = assembleWeek(brief, fits(brief, { 'p-1': 0.99, 'p-2': 0.7 }));
    expect(week.lunches.filter((l) => l.productId === 'berries')).toHaveLength(5);
    expect(weekCents(brief, week.lunches)).toBeLessThanOrEqual(60000);
  });
});

describe('a product already in the week', () => {
  const yoghurt = 'Yoghurt 6 x 100g';
  const leosWeek = planOf('leo', {
    '1_snack': pick('item-yoghurt', yoghurt),
    '2_snack': pick('item-pear', 'Pear'),
  });
  const SNACKS: FoundIdea = {
    id: 'snack-idea',
    slot: 'snack',
    childIds: ['leo'],
    fromAisle: false,
    products: [
      productOf({ productId: 'yoghurt', name: yoghurt, priceCents: 4599, packQuantity: 6 }),
      productOf({ productId: 'rice-cakes', name: 'Rice cakes', priceCents: 1500, packQuantity: 6 }),
    ],
  };

  it('shares its packs with the boxes the plan adds — one six-pack, not two', () => {
    const already = inWeekItems([leosWeek], MONDAY, {
      'item-yoghurt': { cents: 4599, portions: 6 },
    });
    const threeMore = [3, 4, 5].map(() => ({
      productId: 'yoghurt',
      slot: 'snack' as const,
      name: yoghurt,
    }));
    expect(weekBasketCents(already, threeMore, () => ({ boxesPerPack: 6, priceCents: 4599 }))).toBe(
      4599,
    );
  });

  it('so the plan keeps it when the shared pack is within budget', () => {
    const brief = weekBriefFrom(
      [SNACKS],
      [LEO],
      weekOf([leosWeek], 5000, { prices: { 'item-yoghurt': { cents: 4599, portions: 6 } } }),
    );
    const week = assembleWeek(brief, fits(brief, { 'p-1': 0.99, 'p-2': 0.45 }));
    // Priced apart, the packed box and the three new ones are two six-packs
    // (R91.98, over R50) and the yoghurt would be swapped for rice cakes.
    expect(week.lunches.map((l) => l.productId)).toEqual(['yoghurt', 'yoghurt', 'yoghurt']);
  });

  it('leaves an unpriced item out of the sum, as the budget screen does', () => {
    const already = inWeekItems([leosWeek], MONDAY, {});
    expect(weekBasketCents(already, [], () => ({ boxesPerPack: 1, priceCents: 0 }))).toBe(0);
  });
});

describe('how a shop product becomes a library item', () => {
  it("cuts its name at the app's LunchItem.nameLimit, read from the Dart", () => {
    const source = readFileSync(
      resolve(import.meta.dirname, '../../../../app/lib/features/lunch_box/model/lunch_item.dart'),
      'utf8',
    );
    expect(/static const nameLimit = (\d+);/.exec(source)?.[1]).toBe(String(LUNCH_ITEM_NAME_LIMIT));
  });
});
