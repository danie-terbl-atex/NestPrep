import type { Firestore } from 'firebase-admin/firestore';

import { type HouseholdDocument, householdRef, roleOf, userRef } from '../household/documents';

/**
 * The claim Storage Security Rules read: `{ householdId: role }` for every
 * household this account is actually a member of (documents ADR-0001).
 *
 * Storage rules have no `get()`, so the uid→role map on the household document
 * — the one lookup every Firestore rule performs — is unreachable from them.
 * This is that map, projected onto the caller's token.
 *
 * It is a **cache, not a second source of truth**. Nothing here trusts what a
 * client sent, and nothing here decides membership: it reads the account's list
 * of households and then re-reads each household document to confirm the uid is
 * still in its map (BE-03). A household the account has been removed from
 * simply does not come back.
 */
export const CLAIM_NAME = 'households';

/**
 * How many households fit. Custom claims are capped at 1000 bytes in total, and
 * a household id is 20 characters, so ten of them with their roles is a few
 * hundred bytes with room to spare. Ten is far past household ADR-0002's case:
 * co-parenting across two homes and a helper who works for two families.
 */
export const CLAIM_HOUSEHOLD_LIMIT = 10;

export type HouseholdClaim = Record<string, string>;

export async function householdClaimFor(store: Firestore, uid: string): Promise<HouseholdClaim> {
  const account = await userRef(store, uid).get();
  const listed = account.get('householdIds') as unknown;
  if (!Array.isArray(listed)) return {};

  const ids = listed
    .filter((id): id is string => typeof id === 'string' && id.length > 0)
    .slice(0, CLAIM_HOUSEHOLD_LIMIT);
  if (ids.length === 0) return {};

  const households = await store.getAll(...ids.map((id) => householdRef(store, id)));

  const claim: HouseholdClaim = {};
  for (const snapshot of households) {
    const data = snapshot.data() as HouseholdDocument | undefined;
    if (data === undefined) continue;
    const role = roleOf(data, uid);
    if (role === undefined) continue;
    claim[snapshot.id] = role;
  }
  return claim;
}
