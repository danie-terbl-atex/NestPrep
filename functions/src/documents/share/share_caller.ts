import type { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { householdRef } from '../../household/documents';
import { claimedMemberId } from '../vault_refs';
import { mayShare, type Sharer, type ShareScope } from './share_policy';

const householdShape = z.object({
  name: z.string(),
  timeZone: z.string(),
  members: z.record(z.string(), z.string()),
});

export type SharingHousehold = z.infer<typeof householdShape>;

/**
 * Who [uid] is in a household, re-derived from its membership map and the
 * profile they claimed — never from the request (`BE-03`). Read when a link
 * is made and again every time it is served, so a parent removed from the
 * household stops being able to share, and their links stop working.
 */
export async function sharerIn(
  store: Firestore,
  householdId: string,
  uid: string,
): Promise<{ household: SharingHousehold | null; sharer: Sharer }> {
  const snapshot = await householdRef(store, householdId).get();
  const parsed = householdShape.safeParse(snapshot.data());
  if (!parsed.success) return { household: null, sharer: { role: undefined, memberId: undefined } };
  const role = parsed.data.members[uid];
  const memberId = role === undefined ? undefined : await claimedMemberId(store, householdId, uid);
  return { household: parsed.data, sharer: { role, memberId } };
}

/** Whether [uid] may, right now, share this document outside the household. */
export async function stillMayShare(
  store: Firestore,
  address: { householdId: string; scope: ShareScope; ownerMemberId: string | null },
  uid: string,
): Promise<{ household: SharingHousehold | null; allowed: boolean }> {
  const { household, sharer } = await sharerIn(store, address.householdId, uid);
  return { household, allowed: mayShare(sharer, address.scope, address.ownerMemberId) };
}
