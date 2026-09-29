import type { HouseholdCohort, HouseholdWeek } from './analytics_documents';
import type { ConversionTrigger } from './conversion_ledger';
import { weekStartDate } from './iso_week';
import {
  DEFINITION_VERSION,
  invitedAnAdultInWeekOne,
  isActiveFamily,
  wasSeen,
} from './metric_definitions';

/**
 * One week's beta numbers, as counts (product-analytics ADR-0001). A rate is
 * never stored: the numerator and the denominator are, and whoever shows the
 * number divides — so "0 of 0" can be shown as *no new families* rather than as
 * a 0% that looks like a failure.
 *
 * Every key here is also read by the app's `WeeklyNumbers` model, and
 * `test/unit/product_analytics_contract.test.ts` reads both files so the two
 * cannot drift (the vault lesson on contracts between two languages).
 */
export interface WeeklyNumbers {
  readonly week: string;
  readonly weekStart: string;
  /** The north star: households with two or more members active this week. */
  readonly activeFamilies: number;
  /** Households with anybody active at all — the denominator the north star is read against. */
  readonly familiesSeen: number;
  readonly lunchPlansCreated: number;
  readonly familiesPlanningLunches: number;
  /** Households created this week: the invite cohort. */
  readonly newFamilies: number;
  readonly newFamiliesInvitingAnAdult: number;
  /** The same, by the role the first adult invite was for — partner or helper. */
  readonly adultInvitesByRole: Readonly<Record<string, number>>;
  /** False until every household in the cohort has had its whole first week. */
  readonly isInviteCohortComplete: boolean;
  readonly premiumConversions: number;
  readonly premiumConversionsByTrigger: Readonly<Record<ConversionTrigger, number>>;
  readonly definitionVersion: number;
}

export interface WeekLedgers {
  readonly week: string;
  readonly householdWeeks: readonly HouseholdWeek[];
  readonly cohort: readonly HouseholdCohort[];
  readonly conversions: readonly { readonly trigger: ConversionTrigger }[];
  readonly isInviteCohortComplete: boolean;
}

/** Counts one week's ledgers into its numbers. Pure: the rollup does the reading. */
export function summariseWeek(ledgers: WeekLedgers): WeeklyNumbers {
  const { householdWeeks, cohort } = ledgers;
  const inviting = cohort.filter(invitedAnAdultInWeekOne);
  return {
    week: ledgers.week,
    weekStart: weekStartDate(ledgers.week),
    activeFamilies: householdWeeks.filter((entry) => isActiveFamily(entry.activeMemberIds)).length,
    familiesSeen: householdWeeks.filter((entry) => wasSeen(entry.activeMemberIds)).length,
    lunchPlansCreated: householdWeeks.reduce(
      (total, entry) => total + new Set(entry.lunchPlanIds).size,
      0,
    ),
    familiesPlanningLunches: householdWeeks.filter((entry) => entry.lunchPlanIds.length > 0).length,
    newFamilies: cohort.length,
    newFamiliesInvitingAnAdult: inviting.length,
    adultInvitesByRole: tally(inviting.map((entry) => entry.firstAdultInviteRole ?? 'unknown')),
    isInviteCohortComplete: ledgers.isInviteCohortComplete,
    premiumConversions: ledgers.conversions.length,
    premiumConversionsByTrigger: conversionsByTrigger(ledgers.conversions),
    definitionVersion: DEFINITION_VERSION,
  };
}

function tally(values: readonly string[]): Record<string, number> {
  const counts: Record<string, number> = {};
  for (const value of values) counts[value] = (counts[value] ?? 0) + 1;
  return counts;
}

function conversionsByTrigger(
  conversions: readonly { readonly trigger: ConversionTrigger }[],
): Record<ConversionTrigger, number> {
  const count = (trigger: ConversionTrigger): number =>
    conversions.filter((conversion) => conversion.trigger === trigger).length;
  return {
    additionalChild: count('additionalChild'),
    lunchLearning: count('lunchLearning'),
    prepList: count('prepList'),
    aiPlanning: count('aiPlanning'),
    budgetMode: count('budgetMode'),
    direct: count('direct'),
  };
}
