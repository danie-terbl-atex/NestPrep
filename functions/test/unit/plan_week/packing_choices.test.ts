import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { describe, expect, it } from 'vitest';

import {
  hasOpenCompartments,
  ideaBriefForModel,
  ideaBriefFrom,
} from '../../../src/plan_week/idea_brief';
import { IDEAS_SYSTEM } from '../../../src/plan_week/idea_prompt';
import { openCompartments } from '../../../src/plan_week/open_compartments';
import {
  PACKING_INSTRUCTIONS,
  PACKING_PREFERENCES,
} from '../../../src/plan_week/packing_preferences';
import {
  buildLunchWeekInput,
  draftLunchIdeasInput,
  type AisleShelf,
  type FoundIdea,
} from '../../../src/plan_week/schemas';
import { weekBriefFrom } from '../../../src/plan_week/week_brief';
import { weekDecisionRequest } from '../../../src/plan_week/week_decisions';
import type { LunchPlanFacts } from '../../../src/plan_week/week_documents';
import { productOf, rulesOf } from './fixtures';

const MONDAY = '2026-10-05';
const MIA = {
  memberId: 'mia',
  rules: rulesOf({
    allergyCodes: ['peanut'],
    otherAllergies: ['kiwi'],
    diet: ['halal'],
    schoolIsNutFree: true,
    likes: ['apples'],
  }),
};
const body = { householdId: 'h1', week: '2026-W40', childIds: ['mia'] };
const ideasBody = { ...body, ideas: [] };

describe('the packing choices at the edge', () => {
  it('default, for a phone that sends neither, to every compartment and no preference', () => {
    for (const parsed of [draftLunchIdeasInput.parse(body), buildLunchWeekInput.parse(ideasBody)]) {
      expect(parsed.slots).toEqual(['main', 'fruit', 'veg', 'snack', 'treat']);
      expect(parsed.preferences).toEqual([]);
    }
  });

  it('are deduplicated into canonical order', () => {
    const parsed = draftLunchIdeasInput.parse({
      ...body,
      slots: ['snack', 'fruit', 'snack'],
      preferences: ['healthier', 'readyMade', 'healthier'],
    });
    expect(parsed.slots).toEqual(['fruit', 'snack']);
    expect(parsed.preferences).toEqual(['readyMade', 'healthier']);
  });

  it('refuse an unknown preference or compartment, and no compartment at all', () => {
    for (const schema of [draftLunchIdeasInput, buildLunchWeekInput]) {
      const base = schema === draftLunchIdeasInput ? body : ideasBody;
      expect(schema.safeParse({ ...base, preferences: ['gourmet'] }).success).toBe(false);
      expect(schema.safeParse({ ...base, slots: ['drink'] }).success).toBe(false);
      expect(schema.safeParse({ ...base, slots: [] }).success).toBe(false);
    }
  });

  it('refuse more preferences than exist', () => {
    const tooMany = [...PACKING_PREFERENCES, 'readyMade'];
    expect(draftLunchIdeasInput.safeParse({ ...body, preferences: tooMany }).success).toBe(false);
  });
});

describe('the preference names the app mirrors', () => {
  it('stay one parsable single-quoted literal', () => {
    const source = readFileSync(
      join(__dirname, '../../../src/plan_week/packing_preferences.ts'),
      'utf8',
    );
    const literal = /export const PACKING_PREFERENCES = \[([^\]]*)\] as const;/.exec(source);
    const names = [...(literal?.[1] ?? '').matchAll(/'([A-Za-z]+)'/g)].map((m) => m[1]);
    expect(names).toEqual([...PACKING_PREFERENCES]);
  });

  it('each have an instruction', () => {
    for (const preference of PACKING_PREFERENCES) {
      expect(PACKING_INSTRUCTIONS[preference].length).toBeGreaterThan(20);
    }
  });
});

describe('compartments the parent chose not to plan', () => {
  it('are never open', () => {
    expect(openCompartments(undefined, ['fruit'])).toEqual([
      '1_fruit',
      '2_fruit',
      '3_fruit',
      '4_fruit',
      '5_fruit',
    ]);
    expect(openCompartments(undefined, ['treat'])).toEqual(['5_treat']);
  });

  it('count nothing in the idea brief, and their shelves are dropped', () => {
    const shelf = (slot: AisleShelf['slot']): AisleShelf => ({
      slot,
      title: slot,
      products: ['Rice cakes 30g'],
    });
    const brief = ideaBriefFrom([MIA], [], MONDAY, null, [shelf('snack'), shelf('fruit')], {
      slots: ['fruit', 'veg'],
      preferences: [],
    });
    expect(brief.children[0]?.open).toEqual({ main: 0, fruit: 5, veg: 5, snack: 0, treat: 0 });
    expect(brief.aisle.map((s) => s.slot)).toEqual(['fruit']);
  });

  it('leave nothing to plan when every chosen compartment is packed', () => {
    const fruitPacked: LunchPlanFacts = {
      childId: 'mia',
      weekStart: MONDAY,
      slots: Object.fromEntries(
        [1, 2, 3, 4, 5].map((day) => [
          `${String(day)}_fruit`,
          { itemId: 'x', name: 'Pear', allergens: [] },
        ]),
      ),
      feedback: {},
    };
    const choices = { slots: ['fruit'] as const, preferences: [] };
    expect(
      hasOpenCompartments(ideaBriefFrom([MIA], [fruitPacked], MONDAY, null, [], choices)),
    ).toBe(false);
    const idea: FoundIdea = {
      id: 'fruit',
      slot: 'fruit',
      childIds: ['mia'],
      fromAisle: false,
      products: [productOf()],
    };
    const week = weekBriefFrom([idea], [MIA], [fruitPacked], MONDAY, null, choices);
    expect(week.children).toEqual([]);
  });

  it('take their products out of the week brief, uncounted as removed', () => {
    const idea = (slot: FoundIdea['slot']): FoundIdea => ({
      id: slot,
      slot,
      childIds: ['mia'],
      fromAisle: false,
      products: [productOf({ productId: slot })],
    });
    const brief = weekBriefFrom([idea('snack'), idea('fruit')], [MIA], [], MONDAY, null, {
      slots: ['fruit'],
      preferences: [],
    });
    expect(brief.products.map((p) => p.slot)).toEqual(['fruit']);
    expect(brief.removed).toBe(0);
    expect(brief.children[0]?.open.every((key) => key.endsWith('_fruit'))).toBe(true);
  });
});

describe('the packing preferences the model reads', () => {
  const choices = { slots: ['fruit'] as const, preferences: ['readyMade', 'favourPrice'] as const };
  const idea: FoundIdea = {
    id: 'fruit',
    slot: 'fruit',
    childIds: ['mia'],
    fromAisle: false,
    products: [productOf()],
  };
  const briefs = [
    ideaBriefForModel(ideaBriefFrom([MIA], [], MONDAY, null, [], choices)),
    weekDecisionRequest(weekBriefFrom([idea], [MIA], [], MONDAY, null, choices)).state,
  ];

  it('are the instructions for only what the parent chose', () => {
    for (const brief of briefs) {
      expect(brief).toHaveProperty('packing', [
        PACKING_INSTRUCTIONS.readyMade,
        PACKING_INSTRUCTIONS.favourPrice,
      ]);
    }
  });

  it('are absent when none was chosen', () => {
    expect(ideaBriefForModel(ideaBriefFrom([MIA], [], MONDAY, null))).not.toHaveProperty('packing');
    expect(
      weekDecisionRequest(weekBriefFrom([idea], [MIA], [], MONDAY, null)).state,
    ).not.toHaveProperty('packing');
  });

  it('carry nothing about the child', () => {
    for (const brief of briefs) {
      const text = JSON.stringify(brief);
      for (const secret of ['mia', 'peanut', 'kiwi', 'halal', 'nutFree', 'school']) {
        expect(text.toLowerCase()).not.toContain(secret.toLowerCase());
      }
    }
  });

  it('are explained to the idea model, and asked of every product Jev judges', () => {
    expect(IDEAS_SYSTEM).toContain('"packing"');
    const request = weekDecisionRequest(weekBriefFrom([idea], [MIA], [], MONDAY, null, choices));
    expect(JSON.stringify(request.questions)).toContain('every line in `packing`');
  });
});
