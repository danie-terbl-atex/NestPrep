import { Timestamp, type Firestore, type Transaction } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { householdRef, memberRef } from '../household/documents';
import { expiryFor, householdCohortRef, stringField } from './analytics_documents';
import { countingZoneFor, weekKeyOf } from './iso_week';
import { isChildRole } from './metric_definitions';

/**
 * The cohort ledger behind invite rate: when each household was made, and when
 * — and for which role — its first invite for an adult was created
 * (product-analytics ADR-0001).
 *
 * Whether that invite was inside week one is *not* decided here. The ledger
 * records facts; `metric_definitions.ts` judges them, so the rule is in one
 * place and a day-8 invite is still on record if the window is ever argued.
 */

interface CohortSeed {
  readonly householdId: string;
  readonly createdAt: Date;
  readonly timeZone: string | undefined;
}

function cohortDocument(seed: CohortSeed): Record<string, unknown> {
  return {
    householdId: seed.householdId,
    createdAt: Timestamp.fromDate(seed.createdAt),
    cohortWeek: weekKeyOf(seed.createdAt, countingZoneFor(seed.timeZone)),
    firstAdultInviteAt: null,
    firstAdultInviteRole: null,
    expireAt: expiryFor(seed.createdAt),
  };
}

/**
 * A household was created. Safe to run twice and safe to run after an invite
 * already seeded the entry: an existing entry is left as it is.
 */
export async function recordHouseholdCreated(store: Firestore, seed: CohortSeed): Promise<void> {
  await store.runTransaction(async (transaction) => {
    const cohort = householdCohortRef(store, seed.householdId);
    if ((await transaction.get(cohort)).exists) return;
    transaction.set(cohort, cohortDocument(seed));
  });
}

export interface InviteCreated {
  readonly householdId: string;
  readonly memberId: string;
  readonly invitedAt: Date;
}

/** What recording an invite did, for the log and the tests. */
export type InviteOutcome = 'firstAdultInvite' | 'notFirst' | 'childProfile' | 'householdGone';

/**
 * An invite was created. Keeps the *earliest* adult invite, so trigger
 * deliveries arriving out of order still leave the right one.
 */
export async function recordInviteCreated(
  store: Firestore,
  invite: InviteCreated,
): Promise<InviteOutcome> {
  return store.runTransaction(async (transaction) => {
    const household = await transaction.get(householdRef(store, invite.householdId));
    if (!household.exists) return 'householdGone';
    const member = await transaction.get(memberRef(store, invite.householdId, invite.memberId));
    const role = stringField(member.get('role'));

    const cohort = await existingOrSeeded(transaction, store, {
      householdId: invite.householdId,
      createdAt: createdAtOf(household.get('createdAt'), invite.invitedAt),
      timeZone: stringField(household.get('timeZone')),
    });
    if (role === undefined || isChildRole(role)) return 'childProfile';

    const earlier = cohort.firstAdultInviteAt;
    if (earlier !== null && earlier.getTime() <= invite.invitedAt.getTime()) return 'notFirst';

    transaction.set(
      householdCohortRef(store, invite.householdId),
      { firstAdultInviteAt: Timestamp.fromDate(invite.invitedAt), firstAdultInviteRole: role },
      { merge: true },
    );
    return 'firstAdultInvite';
  });
}

/**
 * The cohort entry, creating it from the household when a household made
 * before this feature existed sends its first invite. Such a household falls
 * in the cohort of the week it was really created, which is long past, so it
 * never distorts a beta cohort.
 */
async function existingOrSeeded(
  transaction: Transaction,
  store: Firestore,
  seed: CohortSeed,
): Promise<{ firstAdultInviteAt: Date | null }> {
  const ref = householdCohortRef(store, seed.householdId);
  const snapshot = await transaction.get(ref);
  if (snapshot.exists) {
    const invitedAt: unknown = snapshot.get('firstAdultInviteAt');
    return { firstAdultInviteAt: invitedAt instanceof Timestamp ? invitedAt.toDate() : null };
  }
  logger.info('cohort entry seeded from an invite', { householdId: seed.householdId });
  transaction.set(ref, cohortDocument(seed));
  return { firstAdultInviteAt: null };
}

function createdAtOf(value: unknown, fallback: Date): Date {
  return value instanceof Timestamp ? value.toDate() : fallback;
}
