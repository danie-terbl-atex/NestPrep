import type { DocumentReference, Firestore, Query } from 'firebase-admin/firestore';

import { householdRef } from '../household/documents';

/**
 * Where the hub's records live (nanny-hub ADR-0002). The client spells the
 * same names in its Firestore repositories, and the rules name them in
 * `rules/firestore/household/nanny_hub.rules`.
 */
export const SHIFTS = 'nannyShifts';
export const ENTRIES = 'entries';
export const SUMMARIES = 'nannyShiftSummaries';
export const CHECKLISTS = 'nannyChecklists';

/** The five parts of a shift a checklist can be for (nanny-hub ADR-0001). */
export const MOMENTS = ['arrival', 'afterSchool', 'dinner', 'bedtime', 'beforeLeaving'] as const;

/**
 * As many entries as one shift's summary reads. A shift is an evening or a
 * day; two hundred things logged is far past one, and a bounded read is the
 * rule (BE-08).
 */
export const ENTRY_LIMIT = 200;

export function shiftRef(
  store: Firestore,
  householdId: string,
  shiftId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(SHIFTS).doc(shiftId);
}

export function summaryRef(
  store: Firestore,
  householdId: string,
  shiftId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(SUMMARIES).doc(shiftId);
}

export function entriesOf(store: Firestore, householdId: string, shiftId: string): Query {
  return shiftRef(store, householdId, shiftId).collection(ENTRIES).orderBy('at').limit(ENTRY_LIMIT);
}

export function checklistRef(
  store: Firestore,
  householdId: string,
  moment: string,
): DocumentReference {
  return householdRef(store, householdId).collection(CHECKLISTS).doc(moment);
}
