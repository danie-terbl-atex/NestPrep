import type { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { ROLES, householdRef } from '../household/documents';
import { refuse } from '../household/errors';
import { levelNow } from '../household/shift_window';
import { refuseListScan } from './errors';

export interface ListCaller {
  readonly uid: string;
  readonly timeZone: string;
}

// `member` is household ADR-0001's family adult, still stored on older households.
const householdShape = z.object({
  timeZone: z.string(),
  members: z.record(z.string(), z.enum([...ROLES, 'member'])),
  access: z.record(z.string(), z.unknown()).optional(),
});

/**
 * The caller, refused unless the household's `groceries` grant lets them add
 * to the list — `edit`, what the rules ask of a grocery write. Re-derived from
 * Firestore, never taken from the request (BE-03, BE-05).
 */
export async function listCallerIn(
  store: Firestore,
  householdId: string,
  uid: string,
): Promise<ListCaller> {
  const snapshot = await householdRef(store, householdId).get();
  const household = householdShape.safeParse(snapshot.data());
  if (!snapshot.exists || !household.success) throw refuse('notAMember');
  const role = household.data.members[uid];
  if (role === undefined) throw refuse('notAMember');
  const level = await levelNow(store, {
    householdId,
    householdData: snapshot.data(),
    uid,
    role,
    storedGrant: household.data.access?.[uid],
    area: 'groceries',
  });
  if (level !== 'edit') throw refuseListScan('groceriesNotShared');
  return { uid, timeZone: household.data.timeZone };
}
