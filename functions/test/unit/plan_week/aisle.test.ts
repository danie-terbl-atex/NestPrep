import { describe, expect, it } from 'vitest';

import { ideaBriefForModel, ideaBriefFrom } from '../../../src/plan_week/idea_brief';
import {
  MAX_AISLE_NAMES,
  MAX_AISLE_SHELVES,
  buildLunchWeekInput,
  draftLunchIdeasInput,
  type AisleShelf,
  type FoundIdea,
} from '../../../src/plan_week/schemas';
import { weekBriefForModel, weekBriefFrom } from '../../../src/plan_week/week_brief';
import type { LunchPlanFacts } from '../../../src/plan_week/week_documents';
import { productOf, rulesOf } from './fixtures';

const MONDAY = '2026-10-05';
const MIA = { memberId: 'mia', rules: rulesOf({ allergyCodes: ['milk'] }) };
const LEO = { memberId: 'leo', rules: rulesOf() };

const YOGHURTS: AisleShelf = {
  slot: 'snack',
  title: 'Yoghurt snack time',
  products: ['NutriDay Yoghurt 6 x 100g', 'Rice cakes 30g'],
};

/** Every snack compartment of a week packed, so nobody has a snack open. */
function snacksPacked(childId: string): LunchPlanFacts {
  const slots = Object.fromEntries(
    [1, 2, 3, 4, 5].map((day) => [
      `${String(day)}_snack`,
      { itemId: 'x', name: 'Pear', allergens: [] },
    ]),
  );
  return { childId, weekStart: MONDAY, slots, feedback: {} };
}

describe("the store's lunchbox shelves the model hears (lunch-box ADR-0013)", () => {
  it('drops a name that names the allergen of the only child it could go to', () => {
    const brief = ideaBriefFrom([MIA], [], MONDAY, null, [YOGHURTS]);
    expect(brief.aisle).toEqual([{ ...YOGHURTS, products: ['Rice cakes 30g'] }]);
  });

  it('keeps that name when another child with the compartment open may have it', () => {
    const brief = ideaBriefFrom([MIA, LEO], [], MONDAY, null, [YOGHURTS]);
    expect(brief.aisle[0]?.products).toEqual(YOGHURTS.products);
  });

  it('drops the name when the child who may have it has no room for it', () => {
    const brief = ideaBriefFrom([MIA, LEO], [snacksPacked('leo')], MONDAY, null, [YOGHURTS]);
    expect(brief.aisle[0]?.products).toEqual(['Rice cakes 30g']);
  });

  it('drops a shelf for a compartment nobody has open, and a shelf left with no names', () => {
    const packed = ideaBriefFrom([LEO], [snacksPacked('leo')], MONDAY, null, [YOGHURTS]);
    expect(packed.aisle).toEqual([]);
    const allMilk = ideaBriefFrom([MIA], [], MONDAY, null, [
      { slot: 'snack', title: 'Cheese', products: ['Cheese wedges'] },
    ]);
    expect(allMilk.aisle).toEqual([]);
  });

  it('reaches the model only when there is a shelf to tell it about', () => {
    const without = ideaBriefForModel(ideaBriefFrom([LEO], [], MONDAY, null));
    expect(without).not.toHaveProperty('aisle');
    const withShelf = ideaBriefForModel(ideaBriefFrom([LEO], [], MONDAY, null, [YOGHURTS]));
    expect(withShelf).toHaveProperty('aisle', [YOGHURTS]);
  });
});

describe('a shelf sent back with its products is marked for the model', () => {
  const idea = (id: string, fromAisle: boolean): FoundIdea => ({
    id,
    slot: 'snack',
    childIds: ['leo'],
    fromAisle,
    products: [productOf({ productId: id })],
  });

  it('as "aisle": true, and a model idea is not', () => {
    const brief = weekBriefFrom(
      [idea('aisle-1', true), idea('idea-1', false)],
      [LEO],
      [],
      MONDAY,
      null,
    );
    const model = weekBriefForModel(brief) as { ideas: Record<string, unknown>[] };
    expect(model.ideas[0]).toHaveProperty('aisle', true);
    expect(model.ideas[1]).not.toHaveProperty('aisle');
  });
});

describe('the shelves at the edge', () => {
  const body = { householdId: 'h1', week: '2026-W40', childIds: ['m-kid'] };

  it('are optional, and none is an empty list', () => {
    expect(draftLunchIdeasInput.parse(body).aisle).toEqual([]);
    expect(draftLunchIdeasInput.parse({ ...body, aisle: [YOGHURTS] }).aisle).toEqual([YOGHURTS]);
  });

  it(`refuse more than ${String(MAX_AISLE_SHELVES)} shelves or ${String(MAX_AISLE_NAMES)} names on one`, () => {
    const tooMany = Array.from({ length: MAX_AISLE_SHELVES + 1 }, () => YOGHURTS);
    expect(draftLunchIdeasInput.safeParse({ ...body, aisle: tooMany }).success).toBe(false);
    const crowded = {
      ...YOGHURTS,
      products: Array.from({ length: MAX_AISLE_NAMES + 1 }, () => 'Rice cakes'),
    };
    expect(draftLunchIdeasInput.safeParse({ ...body, aisle: [crowded] }).success).toBe(false);
  });

  it('refuse a shelf for a compartment that does not exist', () => {
    const drinks = { ...YOGHURTS, slot: 'drink' };
    expect(draftLunchIdeasInput.safeParse({ ...body, aisle: [drinks] }).success).toBe(false);
  });

  it('let the week take the model ideas and every shelf together', () => {
    const ideas = Array.from({ length: 37 }, (_, index) => ({
      id: `idea-${String(index)}`,
      slot: 'snack',
      childIds: ['m-kid'],
      products: [],
    }));
    const parsed = buildLunchWeekInput.safeParse({ ...body, ideas });
    expect(parsed.success).toBe(true);
    expect(parsed.data?.ideas[0]?.fromAisle).toBe(false);
    expect(buildLunchWeekInput.safeParse({ ...body, ideas: [...ideas, ideas[0]] }).success).toBe(
      false,
    );
  });
});
