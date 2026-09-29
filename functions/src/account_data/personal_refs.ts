import type { DocumentReference, Firestore } from 'firebase-admin/firestore';

import { memberDetailRefs } from '../family_profiles/member_details';
import { householdRef } from '../household/documents';

/** Where live location keeps a member's last position (live-location ADR-0001). */
export const MEMBER_LOCATIONS = 'memberLocations';

/** A child's card for a carer, keyed by the child's member id (nanny-hub ADR-0003). */
export const NANNY_CHILD_CARDS = 'nannyChildCards';

/**
 * Every document in a household that is *about one person* rather than a
 * record of what the household did: their family profile and medication,
 * their last shared position and — for a child — the card a carer reads.
 * Erasing an account removes these for the profile it claimed; the profile
 * itself stays, unclaimed, so tasks, events and shifts still say who they were
 * for (household ADR-0001, accounts ADR-0006).
 *
 * Built on `memberDetailRefs` so removing a member and erasing an account can
 * never disagree about what a person's details are (`ENG-01`).
 */
export function personalRefs(
  store: Firestore,
  householdId: string,
  memberId: string,
): DocumentReference[] {
  const household = householdRef(store, householdId);
  return [
    ...memberDetailRefs(store, householdId, memberId),
    household.collection(MEMBER_LOCATIONS).doc(memberId),
    household.collection(NANNY_CHILD_CARDS).doc(memberId),
  ];
}

/** Where a vault's bytes live in Storage (`rules/storage/paths/document_vaults.rules`). */
export function vaultObjectPrefix(householdId: string, memberId: string): string {
  return `households/${householdId}/vaults/${memberId}/`;
}

/** Every object a household owns in Storage: documents, vaults, photos. */
export function householdObjectPrefix(householdId: string): string {
  return `households/${householdId}/`;
}

/** Where an account's data exports are written (accounts ADR-0006). */
export function exportObjectPrefix(uid: string): string {
  return `accountExports/${uid}/`;
}
