import { describe, expect, it } from 'vitest';

import { ideaBriefFrom } from '../../../src/plan_week/idea_brief';
import { openCompartments } from '../../../src/plan_week/open_compartments';
import type { SchoolDay } from '../../../src/plan_week/iso_week';
import type { PackingChoices } from '../../../src/plan_week/packing_preferences';
import {
  buildLunchWeekInput,
  draftLunchIdeasInput,
  type FoundIdea,
} from '../../../src/plan_week/schemas';
import { assembleWeek } from '../../../src/plan_week/week_assembly';
import { weekBriefFrom, type WeekBrief } from '../../../src/plan_week/week_brief';
import { COMPARTMENTS, type WeekDecisions } from '../../../src/plan_week/week_decisions';
import type { LunchPlanFacts } from '../../../src/plan_week/week_documents';
import { MONDAY, SCHOOL_WEEK, productOf, rulesOf, weekOf } from './fixtures';

/**
 * *Plan my week* plans a treat only on the school days the parent chose
 * (lunch-box ADR-0025); a phone that does not say gets Friday, as ADR-0003
 * always gave it. The server enforces the days — the phone only offers them.
 */

const WEDNESDAY = '2026-10-07';
const LEO = { memberId: 'leo', rules: rulesOf() };
const body = { householdId: 'h1', week: '2026-W41', childIds: ['leo'] };
const ideasBody = { ...body, ideas: [] };
const schemas = [
  { schema: draftLunchIdeasInput, base: body },
  { schema: buildLunchWeekInput, base: ideasBody },
] as const;

const treatsOnly = (treatDays: readonly SchoolDay[]): PackingChoices => ({
  slots: ['treat'],
  preferences: [],
  treatDays,
});

const TREAT_IDEA: FoundIdea = {
  id: 'treat-idea',
  slot: 'treat',
  childIds: ['leo'],
  fromAisle: false,
  products: [productOf({ productId: 'muffins', name: 'Mini muffins', packQuantity: 10 })],
};

const allFit = (brief: WeekBrief): WeekDecisions => ({
  fit: Object.fromEntries(brief.products.map((p) => [p.ref, 0.9])),
  boxes: {},
});

describe('the treat days at the edge', () => {
  it('default to Friday for a phone from before the choice', () => {
    for (const { schema, base } of schemas) {
      expect(schema.parse(base).treatDays).toEqual([5]);
    }
  });

  it('are deduplicated into Monday-first order', () => {
    for (const { schema, base } of schemas) {
      expect(schema.parse({ ...base, treatDays: [5, 1, 5, 3] }).treatDays).toEqual([1, 3, 5]);
    }
  });

  it('may be none at all, which plans no treat', () => {
    for (const { schema, base } of schemas) {
      expect(schema.parse({ ...base, treatDays: [] }).treatDays).toEqual([]);
    }
  });

  it('refuse a day that is not a school day, a fraction, text, and more days than a week has', () => {
    for (const { schema, base } of schemas) {
      for (const treatDays of [[0], [6], [7], [2.5], ['1'], [1, 2, 3, 4, 5, 1], 5]) {
        expect(schema.safeParse({ ...base, treatDays }).success).toBe(false);
      }
    }
  });
});

describe('the compartments a treat may be planned in', () => {
  it('are Friday only when the parent did not say', () => {
    expect(openCompartments(undefined, SCHOOL_WEEK, ['treat'])).toEqual(['5_treat']);
  });

  it('are exactly the chosen days', () => {
    expect(openCompartments(undefined, SCHOOL_WEEK, ['treat'], [1, 3])).toEqual([
      '1_treat',
      '3_treat',
    ]);
    expect(openCompartments(undefined, SCHOOL_WEEK, ['treat'], [1, 2, 3, 4, 5])).toHaveLength(5);
  });

  it('are none when the parent chose no treat days, and other compartments are untouched', () => {
    expect(openCompartments(undefined, SCHOOL_WEEK, ['fruit', 'treat'], [])).toEqual([
      '1_fruit',
      '2_fruit',
      '3_fruit',
      '4_fruit',
      '5_fruit',
    ]);
  });

  it('still skip a school day that has gone', () => {
    expect(
      openCompartments(undefined, { monday: MONDAY, today: WEDNESDAY }, ['treat'], [1, 2, 3, 4, 5]),
    ).toEqual(['4_treat', '5_treat']);
  });

  it('still skip a treat a person packed', () => {
    const packedTuesdayTreat: LunchPlanFacts = {
      childId: 'leo',
      weekStart: MONDAY,
      slots: { '2_treat': { itemId: 'x', name: 'Rusk', allergens: [] } },
      feedback: {},
    };
    expect(openCompartments(packedTuesdayTreat, SCHOOL_WEEK, ['treat'], [2, 4])).toEqual([
      '4_treat',
    ]);
  });
});

describe('the treat days through both briefs', () => {
  it('count one open treat per chosen day in the ideas brief', () => {
    const brief = ideaBriefFrom([LEO], [], SCHOOL_WEEK, null, [], treatsOnly([1, 2, 3, 4, 5]));
    expect(brief.children[0]?.open.treat).toBe(5);
    const none = ideaBriefFrom([LEO], [], SCHOOL_WEEK, null, [], treatsOnly([]));
    expect(none.children[0]?.open.treat).toBe(0);
  });

  it('place a treat only on the chosen days when the week is assembled', () => {
    const brief = weekBriefFrom([TREAT_IDEA], [LEO], weekOf([], null), treatsOnly([2, 4]));
    expect(brief.children[0]?.open).toEqual(['2_treat', '4_treat']);
    const week = assembleWeek(brief, allFit(brief));
    expect(week.lunches.map((lunch) => lunch.day)).toEqual([2, 4]);
  });

  it('leave a child with no open compartment when no treat day was chosen', () => {
    const brief = weekBriefFrom([TREAT_IDEA], [LEO], weekOf([], null), treatsOnly([]));
    expect(brief.children).toEqual([]);
  });

  it('are not described to Jev as a Friday treat', () => {
    expect(COMPARTMENTS.treat.toLowerCase()).not.toContain('friday');
  });
});
