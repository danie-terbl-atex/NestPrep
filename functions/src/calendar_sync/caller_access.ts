import type { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { HOUSEHOLDS, MEMBERS, ROLES, type Role, householdRef } from '../household/documents';
import { refuseCalendarSync } from './errors';

/**
 * Who is calling, in the household they named — re-derived from Firestore,
 * never taken from the request (BE-03, BE-05).
 */
export interface Caller {
  readonly uid: string;
  readonly role: Role;
  /** The profile this account claimed; what a connection is filed under. */
  readonly memberId: string;
  readonly timeZone: string;
}

const householdShape = z.object({
  timeZone: z.string(),
  members: z.record(z.string(), z.enum(ROLES)),
});

export async function callerIn(
  store: Firestore,
  householdId: string,
  uid: string,
): Promise<Caller> {
  const snapshot = await householdRef(store, householdId).get();
  const household = householdShape.safeParse(snapshot.data());
  if (!snapshot.exists || !household.success) throw refuseCalendarSync('notAMember');
  const role = household.data.members[uid];
  if (role === undefined) throw refuseCalendarSync('notAMember');

  const claimed = await store
    .collection(HOUSEHOLDS)
    .doc(householdId)
    .collection(MEMBERS)
    .where('claimedBy', '==', uid)
    .limit(1)
    .get();
  const member = claimed.docs[0];
  if (member === undefined) throw refuseCalendarSync('notAMember');
  return { uid, role, memberId: member.id, timeZone: household.data.timeZone };
}

/** The person who connected it, or an admin (calendar ADR-0003). */
export function mayManage(caller: Caller, connection: { readonly ownerUid: string }): boolean {
  return caller.uid === connection.ownerUid || caller.role === 'admin';
}
