import type { Firestore } from 'firebase-admin/firestore';

import { logger } from 'firebase-functions/v2';

import { auth } from '../shared/auth';
import { CLAIM_NAME, householdClaimFor } from '../documents/household_claim';
import { type Area, type Level, readGrant, storageGrant, uniformGrant } from './access';
import { type HouseholdDocument, householdRef } from './documents';

/**
 * The second claim Storage Security Rules read (household ADR-0003):
 * `access: { householdId: { area: level } }`, for the households where this
 * account is **not** family, and only for the areas whose bytes live in
 * Storage. A family member's households are absent — their role on the
 * `households` claim already says they see everything.
 *
 * Like `households`, it is a projection of what Firestore says, never a second
 * source of truth: it is re-read from the household documents every time.
 */
export const ACCESS_CLAIM_NAME = 'access';

export type AccessClaim = Record<string, Partial<Record<Area, Level>>>;

export async function accessClaimFor(
  store: Firestore,
  uid: string,
  householdRoles: Record<string, string>,
): Promise<AccessClaim> {
  const restricted = Object.entries(householdRoles)
    .filter(([, role]) => role === 'kid' || role === 'helper' || role === 'carer')
    .map(([householdId]) => householdId);
  if (restricted.length === 0) return {};

  const snapshots = await store.getAll(...restricted.map((id) => householdRef(store, id)));
  const claim: AccessClaim = {};
  for (const snapshot of snapshots) {
    const data = snapshot.data() as HouseholdDocument | undefined;
    const role = data?.members[uid];
    if (data === undefined || role === undefined) continue;
    const stored = data.access?.[uid];
    // A helper claimed before ADR-0003 has no grant and keeps what it had.
    const grant =
      readGrant(stored) ?? (role === 'helper' ? uniformGrant('edit') : uniformGrant('none'));
    claim[snapshot.id] = storageGrant(grant);
  }
  return claim;
}

/**
 * Writes both claims onto the account's token, keeping any other claim it
 * carries. The account's next token refresh picks them up; until then the
 * token in hand still says what it said (documents ADR-0001).
 */
export async function writeAccountClaims(store: Firestore, uid: string): Promise<number> {
  const households = await householdClaimFor(store, uid);
  const access = await accessClaimFor(store, uid, households);
  const existing = (await auth().getUser(uid)).customClaims ?? {};
  await auth().setCustomUserClaims(uid, {
    ...existing,
    [CLAIM_NAME]: households,
    [ACCESS_CLAIM_NAME]: access,
  });
  return Object.keys(households).length;
}

/**
 * The same, for **somebody else's** account, after a parent changed what they
 * may do. The membership change has already committed, so a failure here does
 * not undo it and must not report it as failed: it is logged as an error for
 * the console and answered as `false`, and that account's own
 * `syncDocumentAccess` — which the documents screen calls on the way in — is
 * the path that catches up (BE-09).
 */
export async function pushAccountClaims(store: Firestore, uid: string): Promise<boolean> {
  try {
    await writeAccountClaims(store, uid);
    return true;
  } catch (error: unknown) {
    logger.error('could not refresh an account claim', {
      error: error instanceof Error ? error.message : String(error),
    });
    return false;
  }
}
