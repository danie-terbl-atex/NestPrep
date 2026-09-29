import {
  FieldPath,
  FieldValue,
  type Firestore,
  type QueryDocumentSnapshot,
} from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import type { z } from 'zod';

import {
  CONVERSIONS,
  HOUSEHOLD_COHORTS,
  HOUSEHOLD_WEEKS,
  storedHouseholdCohort,
  storedHouseholdWeek,
  weeklyTotalsRef,
} from './analytics_documents';
import { storedConversion } from './conversion_ledger';
import { LAUNCH_TIME_ZONE, shiftWeek, weekKeyOf } from './iso_week';
import { summariseWeek, type WeeklyNumbers } from './weekly_summary';

/**
 * Recounts a week from its ledgers and overwrites its totals. A recount rather
 * than an increment, so it is safe to run twice, safe to run late, and the fix
 * for a wrong total is to run it again (`BE-15`, product-analytics ADR-0001).
 */

/** How many ledger documents one read takes, and how many reads one collection may take. */
export const PAGE_SIZE = 500;
export const MAX_PAGES = 20;

/**
 * The weeks one run recounts: this one, so far; last week, which a late
 * trigger may still have touched; and the one before, whose invite cohort has
 * just finished its first week.
 */
export function weeksToRollUp(now: Date): string[] {
  const current = weekKeyOf(now, LAUNCH_TIME_ZONE);
  return [shiftWeek(current, -2), shiftWeek(current, -1), current];
}

/**
 * A cohort is final once its last household has had its full seven days: a
 * household made late on the cohort's Sunday is still inside its first week
 * until the Sunday after. So the cohort two weeks back is the newest final one.
 */
export function isInviteCohortComplete(week: string, now: Date): boolean {
  return week <= shiftWeek(weekKeyOf(now, LAUNCH_TIME_ZONE), -2);
}

export async function rollupWeek(
  store: Firestore,
  week: string,
  now: Date,
): Promise<WeeklyNumbers> {
  const [householdWeeks, cohort, conversions] = await Promise.all([
    readWhere(store, { collection: HOUSEHOLD_WEEKS, field: 'week', week }, storedHouseholdWeek),
    readWhere(
      store,
      { collection: HOUSEHOLD_COHORTS, field: 'cohortWeek', week },
      storedHouseholdCohort,
    ),
    readWhere(store, { collection: CONVERSIONS, field: 'week', week }, storedConversion),
  ]);
  const numbers = summariseWeek({
    week,
    householdWeeks,
    cohort,
    conversions,
    isInviteCohortComplete: isInviteCohortComplete(week, now),
  });

  const batch = store.batch();
  batch.set(weeklyTotalsRef(store, week), {
    ...numbers,
    computedAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();

  logger.info('beta numbers rolled up', {
    week,
    activeFamilies: numbers.activeFamilies,
    lunchPlansCreated: numbers.lunchPlansCreated,
    newFamilies: numbers.newFamilies,
  });
  return numbers;
}

interface WeekQuery {
  readonly collection: string;
  readonly field: string;
  readonly week: string;
}

/**
 * Every ledger document for one week, a bounded page at a time (`BE-08`). A
 * document that does not parse is skipped and logged rather than failing the
 * whole week — one bad row must not blank the number Daniel reads.
 */
async function readWhere<T extends z.ZodType>(
  store: Firestore,
  query: WeekQuery,
  schema: T,
): Promise<z.infer<T>[]> {
  const rows: z.infer<T>[] = [];
  let last: QueryDocumentSnapshot | undefined;
  for (let page = 0; page < MAX_PAGES; page += 1) {
    let request = store
      .collection(query.collection)
      .where(query.field, '==', query.week)
      .orderBy(FieldPath.documentId())
      .limit(PAGE_SIZE);
    if (last !== undefined) request = request.startAfter(last);
    const snapshot = await request.get();
    for (const document of snapshot.docs) rows.push(...parsed(schema, document, query));
    if (snapshot.size < PAGE_SIZE) return rows;
    last = snapshot.docs[snapshot.docs.length - 1];
  }
  logger.error('beta numbers truncated: ledger larger than one run reads', {
    collection: query.collection,
    week: query.week,
    limit: PAGE_SIZE * MAX_PAGES,
  });
  return rows;
}

function parsed<T extends z.ZodType>(
  schema: T,
  document: QueryDocumentSnapshot,
  query: WeekQuery,
): z.infer<T>[] {
  const result = schema.safeParse(document.data());
  if (result.success) return [result.data];
  logger.error('ledger entry skipped: unreadable', {
    collection: query.collection,
    week: query.week,
    documentId: document.id,
  });
  return [];
}
