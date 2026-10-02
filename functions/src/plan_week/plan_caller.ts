import type { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { memberLevelIn } from '../household/access';
import { ROLES, householdRef } from '../household/documents';
import { refuse } from '../household/errors';
import { refusePlanWeek } from './errors';
import { isOffShift } from '../household/shift_window';

/**
 * Who is planning, in the household they named — re-derived from Firestore,
 * never taken from the request (BE-03, BE-05). Planning is the `lunch` grant
 * at `edit`, the same the rules ask of a lunch plan write.
 */
export interface PlanCaller {
  readonly uid: string;
  readonly timeZone: string;
}

// `member` is household ADR-0001's family adult, still stored on households
// made before ADR-0003 and read as a parent.
const householdShape = z.object({
  timeZone: z.string(),
  members: z.record(z.string(), z.enum([...ROLES, 'member'])),
  access: z.record(z.string(), z.unknown()).optional(),
});

export async function planCallerIn(
  store: Firestore,
  householdId: string,
  uid: string,
): Promise<PlanCaller> {
  const snapshot = await householdRef(store, householdId).get();
  const household = householdShape.safeParse(snapshot.data());
  if (!snapshot.exists || !household.success) throw refuse('notAMember');
  const role = household.data.members[uid];
  if (role === undefined) throw refuse('notAMember');
  const grant = household.data.access?.[uid];
  if (memberLevelIn(role, grant, 'lunch') !== 'edit') throw refusePlanWeek('lunchNotShared');
  // A shift-only carer off shift holds nothing (nanny-hub ADR-0006).
  if (await isOffShift(store, householdId, snapshot.data(), uid, new Date())) {
    throw refusePlanWeek('lunchNotShared');
  }
  return { uid, timeZone: household.data.timeZone };
}
