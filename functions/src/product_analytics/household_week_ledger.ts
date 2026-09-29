import { FieldValue, type Firestore, type Transaction } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { householdRef } from '../household/documents';
import { expiryFor, householdWeekRef, stringField } from './analytics_documents';
import type { ConversionTrigger } from './conversion_ledger';
import { countingZoneFor, mondayOf, weekKeyOf } from './iso_week';

/**
 * The household-week ledger: which members opened the app and which lunch
 * plans were made, as sets of opaque ids.
 *
 * Sets rather than counters because a trigger is delivered at least once and a
 * callable can be retried: `arrayUnion` of an id already there changes nothing,
 * so a repeat is harmless and the rollup's count is a recount, never a running
 * total that a retry could push up (`BE-15`, product-analytics ADR-0001).
 */

export interface HouseholdWeekEntry {
  readonly householdId: string;
  readonly week: string;
}

/** The fields every write to a household-week carries, so the first one creates it whole. */
function identity(entry: HouseholdWeekEntry): Record<string, unknown> {
  return {
    householdId: entry.householdId,
    week: entry.week,
    expireAt: expiryFor(mondayOf(entry.week)),
  };
}

/** Stages "this member opened the app this week" on the caller's transaction. */
export function stageMemberActive(
  transaction: Transaction,
  store: Firestore,
  entry: HouseholdWeekEntry & { readonly memberId: string },
): void {
  transaction.set(
    householdWeekRef(store, entry.week, entry.householdId),
    { ...identity(entry), activeMemberIds: FieldValue.arrayUnion(entry.memberId) },
    { merge: true },
  );
}

/**
 * Stages "somebody in this household met the paywall on [trigger] this week"
 * on the caller's transaction — a set, so the household counts once per
 * trigger however often it looks (product-analytics ADR-0002).
 */
export function stagePaywallOpened(
  transaction: Transaction,
  store: Firestore,
  entry: HouseholdWeekEntry & { readonly trigger: ConversionTrigger },
): void {
  transaction.set(
    householdWeekRef(store, entry.week, entry.householdId),
    { ...identity(entry), paywallTriggers: FieldValue.arrayUnion(entry.trigger) },
    { merge: true },
  );
}

export interface LunchPlanCreated {
  readonly householdId: string;
  readonly planId: string;
  readonly createdAt: Date;
}

/**
 * Records one lunch plan against the week it was made in, in its household's
 * timezone. Returns the week, or null when the household no longer exists — a
 * plan written as its household was deleted is not a plan anybody will use.
 */
export async function recordLunchPlanCreated(
  store: Firestore,
  plan: LunchPlanCreated,
): Promise<string | null> {
  return store.runTransaction(async (transaction) => {
    const household = await transaction.get(householdRef(store, plan.householdId));
    if (!household.exists) {
      logger.warn('lunch plan not counted: household gone', { householdId: plan.householdId });
      return null;
    }
    const zone = countingZoneFor(stringField(household.get('timeZone')));
    const week = weekKeyOf(plan.createdAt, zone);
    transaction.set(
      householdWeekRef(store, week, plan.householdId),
      {
        ...identity({ householdId: plan.householdId, week }),
        lunchPlanIds: FieldValue.arrayUnion(plan.planId),
      },
      { merge: true },
    );
    return week;
  });
}
