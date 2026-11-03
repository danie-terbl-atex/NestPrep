import type { DocumentReference, Firestore } from 'firebase-admin/firestore';

import { householdRef } from '../household/documents';

export const LOCATION_TRAILS = 'locationTrails';
export const TRAIL_DAYS = 'trailDays';
export const PLACE_EVENTS = 'placeEvents';
export const PLACES = 'places';

/** A member's history and place events live under this document (live-location ADR-0004). */
export function trailRef(
  store: Firestore,
  householdId: string,
  memberId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(LOCATION_TRAILS).doc(memberId);
}

export function placeRef(
  store: Firestore,
  householdId: string,
  placeId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(PLACES).doc(placeId);
}
