import type { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { FAMILY_ROLES } from '../household/access';
import { HOUSEHOLDS, MEMBERS, ROLES, type Role, householdRef } from '../household/documents';
import { refuseSubscription } from './errors';

/**
 * Who is asking about the household's plan, re-derived from Firestore and
 * never taken from the request (BE-03, BE-05; subscriptions ADR-0001).
 * Anybody in the household may see what is on offer; only family may buy,
 * because it is family who pays.
 */
export interface BillingCaller {
  readonly uid: string;
  readonly role: Role;
  /** The profile this account claimed: the person a purchase is recorded against. */
  readonly memberId: string;
  readonly isFamily: boolean;
}

// `member` is household ADR-0001's family adult, still stored on households
// made before ADR-0003 and read as a parent.
const householdShape = z.object({
  members: z.record(z.string(), z.enum([...ROLES, 'member'])),
});

export async function billingCallerIn(
  store: Firestore,
  householdId: string,
  uid: string,
): Promise<BillingCaller> {
  const snapshot = await householdRef(store, householdId).get();
  if (!snapshot.exists) throw refuseSubscription('householdNotFound');
  const household = householdShape.safeParse(snapshot.data());
  const role = household.success ? household.data.members[uid] : undefined;
  if (role === undefined) throw refuseSubscription('notAMember');

  const claimed = await store
    .collection(HOUSEHOLDS)
    .doc(householdId)
    .collection(MEMBERS)
    .where('claimedBy', '==', uid)
    .limit(1)
    .get();
  const member = claimed.docs[0];
  if (member === undefined) throw refuseSubscription('notAMember');
  return {
    uid,
    role,
    memberId: member.id,
    isFamily: (FAMILY_ROLES as readonly string[]).includes(role),
  };
}
