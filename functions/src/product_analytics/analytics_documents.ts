import { Timestamp, type DocumentReference, type Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { LEDGER_RETENTION_MS } from './metric_definitions';

/**
 * Where the beta numbers live, and the only shapes they are stored in
 * (product-analytics ADR-0001). No client reads or writes any of these except
 * `analyticsWeeks`, which a holder of the reader claim may read.
 *
 * Every field here is an opaque id, a role name, a week key, a count or a time.
 * `test/unit/product_analytics_payloads.test.ts` holds the allow-list, so a
 * name or an email added to one of these fails the build rather than a review.
 */

/** One household's week: who opened the app, and which lunch plans were made. */
export const HOUSEHOLD_WEEKS = 'analyticsHouseholdWeeks';

/** One household's cohort facts: when it was made, and its first adult invite. */
export const HOUSEHOLD_COHORTS = 'analyticsHouseholds';

/** One premium purchase and the feature that prompted it (V2). */
export const CONVERSIONS = 'analyticsConversions';

/** One week's totals — counts only. What the readout and the screen show. */
export const WEEKLY_TOTALS = 'analyticsWeeks';

/**
 * The custom claim that lets an account read `analyticsWeeks`. Set by
 * `tools/grant-analytics-reader.mjs`; read by `firestore.rules` and by the
 * app to decide whether to offer the Beta numbers screen at all.
 */
export const READER_CLAIM = 'analyticsReader';

/**
 * The collection lunch-box writes a week's plan into. The contract is the path
 * alone: the trigger never reads the document, so nothing about a child or
 * their food can reach analytics (product-analytics ADR-0001).
 */
export const LUNCH_PLANS = 'lunchPlans';

export function householdWeekRef(
  store: Firestore,
  week: string,
  householdId: string,
): DocumentReference {
  return store.collection(HOUSEHOLD_WEEKS).doc(`${week}_${householdId}`);
}

export function householdCohortRef(store: Firestore, householdId: string): DocumentReference {
  return store.collection(HOUSEHOLD_COHORTS).doc(householdId);
}

export function conversionRef(store: Firestore, conversionId: string): DocumentReference {
  return store.collection(CONVERSIONS).doc(conversionId);
}

export function weeklyTotalsRef(store: Firestore, week: string): DocumentReference {
  return store.collection(WEEKLY_TOTALS).doc(week);
}

/** When the TTL policy may delete a ledger document that describes [from]. */
export function expiryFor(from: Date): Timestamp {
  return Timestamp.fromMillis(from.getTime() + LEDGER_RETENTION_MS);
}

/** A stored field that should be a string, or undefined when it is anything else. */
export function stringField(value: unknown): string | undefined {
  return typeof value === 'string' ? value : undefined;
}

const timestamp = z.instanceof(Timestamp).transform((value) => value.toDate());
const ids = z.array(z.string()).default([]);

/** A household-week ledger as read back by the rollup. */
export const storedHouseholdWeek = z.object({
  householdId: z.string(),
  week: z.string(),
  activeMemberIds: ids,
  lunchPlanIds: ids,
});
export type HouseholdWeek = z.infer<typeof storedHouseholdWeek>;

/** A household's cohort facts as read back by the rollup. */
export const storedHouseholdCohort = z.object({
  householdId: z.string(),
  cohortWeek: z.string(),
  createdAt: timestamp,
  firstAdultInviteAt: timestamp.nullable().default(null),
  firstAdultInviteRole: z.string().nullable().default(null),
});
export type HouseholdCohort = z.infer<typeof storedHouseholdCohort>;
