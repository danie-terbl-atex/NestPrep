import { describe, expect, it } from 'vitest';

import type {
  HouseholdCohort,
  HouseholdWeek,
} from '../../src/product_analytics/analytics_documents';
import {
  INVITE_WINDOW_MS,
  invitedAnAdultInWeekOne,
  isActiveFamily,
  isChildRole,
} from '../../src/product_analytics/metric_definitions';
import { isInviteCohortComplete, weeksToRollUp } from '../../src/product_analytics/weekly_rollup';
import { summariseWeek } from '../../src/product_analytics/weekly_summary';

/**
 * The counting logic against fixtures (phase 1 definition of done): the three
 * numbers for a seeded set of households, each of which is here because it is
 * the case a wrong rule would count wrongly.
 */

const WEEK = '2026-W40';
const MONDAY = new Date('2026-09-28T08:00:00Z');
const DAY_MS = 24 * 60 * 60 * 1000;

function householdWeek(
  householdId: string,
  activeMemberIds: string[],
  lunchPlanIds: string[] = [],
): HouseholdWeek {
  return { householdId, week: WEEK, activeMemberIds, lunchPlanIds };
}

function cohortEntry(
  householdId: string,
  invitedAfterDays: number | null,
  role = 'member',
): HouseholdCohort {
  return {
    householdId,
    cohortWeek: WEEK,
    createdAt: MONDAY,
    firstAdultInviteAt:
      invitedAfterDays === null ? null : new Date(MONDAY.getTime() + invitedAfterDays * DAY_MS),
    firstAdultInviteRole: invitedAfterDays === null ? null : role,
  };
}

describe('an active family', () => {
  it('is two or more distinct members', () => {
    expect(isActiveFamily(['m-sam'])).toBe(false);
    expect(isActiveFamily(['m-sam', 'm-alex'])).toBe(true);
    expect(isActiveFamily(['m-sam', 'm-alex', 'm-thandi'])).toBe(true);
  });

  it('is not one member counted twice', () => {
    expect(isActiveFamily(['m-sam', 'm-sam'])).toBe(false);
  });

  it('is nobody at all only when nobody opened it', () => {
    expect(isActiveFamily([])).toBe(false);
  });
});

describe('an invite in week one', () => {
  it('counts on day one and on day seven', () => {
    expect(invitedAnAdultInWeekOne(cohortEntry('h', 0))).toBe(true);
    expect(invitedAnAdultInWeekOne(cohortEntry('h', 6.99))).toBe(true);
  });

  it('does not count on day eight, nor at the exact end of the seventh day', () => {
    expect(invitedAnAdultInWeekOne(cohortEntry('h', 7))).toBe(false);
    expect(invitedAnAdultInWeekOne(cohortEntry('h', 8))).toBe(false);
    expect(INVITE_WINDOW_MS).toBe(7 * DAY_MS);
  });

  it('does not count when nobody was invited', () => {
    expect(invitedAnAdultInWeekOne(cohortEntry('h', null))).toBe(false);
  });

  it('treats kid and child as the only roles that are not an adult', () => {
    expect(isChildRole('kid')).toBe(true);
    expect(isChildRole('child')).toBe(true);
    for (const adult of ['admin', 'member', 'helper', 'parent', 'carer']) {
      expect(isChildRole(adult), adult).toBe(false);
    }
  });
});

describe('a week summarised from its ledgers', () => {
  // Five households, and the hand count beside each.
  const ledgers = {
    week: WEEK,
    householdWeeks: [
      householdWeek('h-alone', ['m-1']), // seen, not active
      householdWeek('h-pair', ['m-2', 'm-3'], ['plan-a', 'plan-b']), // active, 2 plans
      householdWeek('h-trio', ['m-4', 'm-5', 'm-6'], ['plan-c']), // active, 1 plan
      householdWeek('h-echo', ['m-7', 'm-7']), // one member twice: not active
      householdWeek('h-quiet', [], ['plan-d', 'plan-d']), // a plan counted twice is one
    ],
    cohort: [
      cohortEntry('h-alone', null), // never invited
      cohortEntry('h-pair', 2), // day 3: counts
      cohortEntry('h-trio', 8), // day 8: does not
      cohortEntry('h-helper', 1, 'helper'), // a helper is an adult
    ],
    conversions: [{ trigger: 'additionalChild' as const }, { trigger: 'direct' as const }],
    isInviteCohortComplete: true,
  };
  const numbers = summariseWeek(ledgers);

  it('counts active families as the households with two or more members', () => {
    expect(numbers.activeFamilies).toBe(2);
    expect(numbers.familiesSeen).toBe(4);
  });

  it('counts each lunch plan once, and the families making them', () => {
    expect(numbers.lunchPlansCreated).toBe(4);
    expect(numbers.familiesPlanningLunches).toBe(3);
  });

  it('counts the invite cohort, leaving out the day-8 invite', () => {
    expect(numbers.newFamilies).toBe(4);
    expect(numbers.newFamiliesInvitingAnAdult).toBe(2);
    expect(numbers.adultInvitesByRole).toEqual({ member: 1, helper: 1 });
  });

  it('carries conversions by trigger, zero where there were none', () => {
    expect(numbers.premiumConversions).toBe(2);
    expect(numbers.premiumConversionsByTrigger).toEqual({
      additionalChild: 1,
      lunchLearning: 0,
      prepList: 0,
      aiPlanning: 0,
      budgetMode: 0,
      direct: 1,
    });
  });

  it('names its week and its Monday, and the definition it was counted under', () => {
    expect(numbers.week).toBe(WEEK);
    expect(numbers.weekStart).toBe('2026-09-28');
    expect(numbers.definitionVersion).toBe(1);
    expect(numbers.isInviteCohortComplete).toBe(true);
  });

  it('is all zeros for a week with nothing in it, never a division by zero', () => {
    const empty = summariseWeek({
      week: WEEK,
      householdWeeks: [],
      cohort: [],
      conversions: [],
      isInviteCohortComplete: false,
    });
    expect(empty.activeFamilies).toBe(0);
    expect(empty.newFamilies).toBe(0);
    expect(empty.newFamiliesInvitingAnAdult).toBe(0);
    expect(empty.adultInvitesByRole).toEqual({});
  });
});

describe('which weeks a nightly run recounts', () => {
  // Wednesday 7 October 2026, 03:00 in Johannesburg.
  const now = new Date('2026-10-07T01:00:00Z');

  it('is this week and the two before it', () => {
    expect(weeksToRollUp(now)).toEqual(['2026-W39', '2026-W40', '2026-W41']);
  });

  it('calls a cohort final only once all of it has had a full week', () => {
    // W40's last household could have been made on Sunday 4 October and has
    // until Sunday 11 October.
    expect(isInviteCohortComplete('2026-W41', now)).toBe(false);
    expect(isInviteCohortComplete('2026-W40', now)).toBe(false);
    expect(isInviteCohortComplete('2026-W39', now)).toBe(true);
  });
});
