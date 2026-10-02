import type { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { ROLES, householdRef } from '../household/documents';
import { refuse } from '../household/errors';
import { levelNow } from '../household/shift_window';
import { refuseLunchPhoto } from './errors';

/**
 * Who is asking for a box's picture, in the household they named —
 * re-derived from Firestore, never taken from the request (BE-03, BE-05).
 */
export interface PhotoCaller {
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

/**
 * The caller, refused unless the household's `lunch` grant lets them see
 * every child's plans — `view` or `edit`, what the rules ask of a plan read.
 * `own` sees only the holder's own plans, so it is not enough to picture a
 * child's box. A shift-only carer off shift holds nothing (nanny-hub ADR-0006).
 */
export async function photoCallerIn(
  store: Firestore,
  householdId: string,
  uid: string,
): Promise<PhotoCaller> {
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
    area: 'lunch',
  });
  if (level !== 'view' && level !== 'edit') throw refuseLunchPhoto('lunchNotShared');
  return { uid, timeZone: household.data.timeZone };
}
