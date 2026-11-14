import type { DocumentReference, Firestore } from 'firebase-admin/firestore';

import { householdRef } from '../household/documents';

/**
 * Where kid routines live under a household (kid-routines ADR-0001). The
 * routine and its ticks are the client's to write; the award is written by
 * Functions and nothing else.
 */
export const KID_ROUTINES = 'kidRoutines';
export const KID_ROUTINE_TICKS = 'kidRoutineTicks';
export const KID_ROUTINE_AWARDS = 'kidRoutineAwards';

export function kidRoutineRef(
  store: Firestore,
  householdId: string,
  routineId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(KID_ROUTINES).doc(routineId);
}

export function routineTickRef(
  store: Firestore,
  householdId: string,
  tickId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(KID_ROUTINE_TICKS).doc(tickId);
}

/** Keyed like the tick it is about, so there is one per child per day. */
export function routineAwardRef(
  store: Firestore,
  householdId: string,
  tickId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(KID_ROUTINE_AWARDS).doc(tickId);
}
