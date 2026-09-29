import type { DocumentReference, Firestore } from 'firebase-admin/firestore';

import { HOUSEHOLDS } from '../household/documents';

/** What the household knows about a member (family-profiles ADR-0001). */
export const FAMILY_PROFILES = 'familyProfiles';

/** A member's medication — a document of its own so fewer people read it. */
export const MEMBER_HEALTH = 'memberHealth';

/**
 * Every document that describes one member beyond the member itself, keyed by
 * the member's id. They go with the member: `removeMember` deletes them in the
 * same transaction, so a removed child's allergies and medication do not
 * outlive them — no client may delete them (family-profiles ADR-0001).
 */
export function memberDetailRefs(
  store: Firestore,
  householdId: string,
  memberId: string,
): DocumentReference[] {
  const household = store.collection(HOUSEHOLDS).doc(householdId);
  return [
    household.collection(FAMILY_PROFILES).doc(memberId),
    household.collection(MEMBER_HEALTH).doc(memberId),
  ];
}
