import { describe, expect, it } from 'vitest';

import { ideaBriefFrom } from '../../../src/plan_week/idea_brief';
import { openCompartments } from '../../../src/plan_week/open_compartments';
import type { FoundIdea } from '../../../src/plan_week/schemas';
import { weekBriefFrom } from '../../../src/plan_week/week_brief';
import { MONDAY, productOf, rulesOf, weekOf } from './fixtures';

/**
 * *Plan my week* fills the week the board shows; on a Wednesday that is this
 * week, and Monday's to Wednesday's boxes have gone. A school day on or before
 * the household's today is never planned — the app's `LunchDay.hasHappened`
 * (lunch-box ADR-0019).
 */

const WEDNESDAY = '2026-10-07';
const SATURDAY_BEFORE = '2026-10-03';
const SATURDAY_AFTER = '2026-10-10';

describe('a school day that has gone', () => {
  it('is not open on a Wednesday — Thursday and Friday are, today is not', () => {
    expect(openCompartments(undefined, { monday: MONDAY, today: WEDNESDAY }, ['fruit'])).toEqual([
      '4_fruit',
      '5_fruit',
    ]);
  });

  it('leaves the whole week open from the Saturday before it', () => {
    expect(
      openCompartments(undefined, { monday: MONDAY, today: SATURDAY_BEFORE }, ['fruit']),
    ).toHaveLength(5);
  });

  it('leaves nothing open from the Saturday after it', () => {
    expect(openCompartments(undefined, { monday: MONDAY, today: SATURDAY_AFTER })).toEqual([]);
  });

  it('is not counted in the ideas brief', () => {
    const brief = ideaBriefFrom(
      [{ memberId: 'leo', rules: rulesOf() }],
      [],
      { monday: MONDAY, today: WEDNESDAY },
      null,
    );
    expect(brief.children[0]?.open).toEqual({ main: 2, fruit: 2, veg: 2, snack: 2, treat: 1 });
  });

  it('is not offered to Jev in the week brief', () => {
    const idea: FoundIdea = {
      id: 'fruit',
      slot: 'fruit',
      childIds: ['leo'],
      fromAisle: false,
      products: [productOf()],
    };
    const brief = weekBriefFrom(
      [idea],
      [{ memberId: 'leo', rules: rulesOf() }],
      weekOf([], null, { today: WEDNESDAY }),
      { slots: ['fruit'], preferences: [], treatDays: [5] },
    );
    expect(brief.children[0]?.open).toEqual(['4_fruit', '5_fruit']);
  });
});
