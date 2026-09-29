import type { HouseholdCohort, HouseholdWeek } from './analytics_documents';
import { CONVERSION_TRIGGERS, type ConversionTrigger } from './conversion_ledger';
import type { ReferralCounts } from './referral_counts';
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
  /** Households that met the paywall at all this week — conversion's denominator. */
  readonly paywallFamilies: number;
  /** The same, per trigger: a household counts once for each trigger it met. */
  readonly paywallFamiliesByTrigger: Readonly<Record<ConversionTrigger, number>>;
  readonly premiumConversions: number;
  readonly premiumConversionsByTrigger: Readonly<Record<ConversionTrigger, number>>;
  /** Households that entered another's referral code this week (subscriptions ADR-0002). */
  readonly referralsRedeemed: number;
  /** Referrals that became a real family this week, whenever they were redeemed. */
  readonly referralsQualified: number;
  /** Free months those referrals gave, both sides together, less any past the cap. */
  readonly referralMonthsGiven: number;
  readonly definitionVersion: number;
}

export interface WeekLedgers {
  readonly week: string;
  readonly householdWeeks: readonly HouseholdWeek[];
  readonly cohort: readonly HouseholdCohort[];
  readonly conversions: readonly { readonly trigger: ConversionTrigger }[];
  readonly referrals: ReferralCounts;
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
    paywallFamilies: householdWeeks.filter((entry) => entry.paywallTriggers.length > 0).length,
    paywallFamiliesByTrigger: byTrigger(
      householdWeeks.flatMap((entry) => [...new Set(entry.paywallTriggers)]),
    ),
    premiumConversions: ledgers.conversions.length,
    premiumConversionsByTrigger: byTrigger(
      ledgers.conversions.map((conversion) => conversion.trigger),
    ),
    referralsRedeemed: ledgers.referrals.redeemed,
    referralsQualified: ledgers.referrals.qualified,
    referralMonthsGiven: ledgers.referrals.monthsGiven,
    definitionVersion: DEFINITION_VERSION,
  };
}

function tally(values: readonly string[]): Record<string, number> {
  const counts: Record<string, number> = {};
  for (const value of values) counts[value] = (counts[value] ?? 0) + 1;
  return counts;
}

/** How many of [triggers] are each trigger; one outside the closed list is not counted. */
function byTrigger(triggers: readonly string[]): Record<ConversionTrigger, number> {
  const counts = Object.fromEntries(CONVERSION_TRIGGERS.map((trigger) => [trigger, 0])) as Record<
    ConversionTrigger,
    number
  >;
  for (const trigger of triggers) {
    const known = CONVERSION_TRIGGERS.find((candidate) => candidate === trigger);
    if (known !== undefined) counts[known] += 1;
  }
  return counts;
}
