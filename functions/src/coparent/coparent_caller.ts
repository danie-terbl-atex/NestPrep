import type { Firestore, Transaction } from 'firebase-admin/firestore';
import { z } from 'zod';

import { isFamilyRole } from '../household/access';
import { householdRef, ROLES } from '../household/documents';
import { refuseCoParent } from './errors';

/**
 * Who is calling a co-parenting callable in their own household, re-derived
 * from the household document the rules read and never from the request
 * (BE-03, BE-05, household ADR-0004).
 *
 * `admin` makes, accepts, confirms and ends a link; `family` — admin or
 * parent, and the old `member` — writes handovers and proposes and answers
 * requests. A kid, helper or carer does neither, whatever their calendar
 * grant says: the other home is talking to the adults who run this one.
 */
export type Need = 'admin' | 'family';

const householdShape = z.object({
  members: z.record(z.string(), z.enum([...ROLES, 'member'])),
});

/** Pure over the household data, so the decision is tested without an emulator. */
export function requireRoleFrom(householdData: unknown, uid: string, need: Need): void {
  const household = householdShape.safeParse(householdData);
  if (!household.success) throw refuseCoParent('notAMember');
  const role = household.data.members[uid];
  if (role === undefined) throw refuseCoParent('notAMember');
  if (need === 'admin' && role !== 'admin') throw refuseCoParent('notAnAdmin');
  if (need === 'family' && !isFamilyRole(role)) throw refuseCoParent('notFamily');
}

export async function requireRole(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  uid: string,
  need: Need,
): Promise<void> {
  const snapshot = await transaction.get(householdRef(store, householdId));
  if (!snapshot.exists) throw refuseCoParent('notAMember');
  requireRoleFrom(snapshot.data(), uid, need);
}
