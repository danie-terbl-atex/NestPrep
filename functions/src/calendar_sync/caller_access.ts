import type { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { memberLevelIn, type Level } from '../household/access';
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

/** How much of the calendar a call needs (household ADR-0003). */
export type CalendarNeed = 'view' | 'edit';

// `member` is household ADR-0001's family adult, still stored on households
// made before ADR-0003 and read as a parent — without it here, the one real
// household would be refused every call.
const householdShape = z.object({
  timeZone: z.string(),
  members: z.record(z.string(), z.enum([...ROLES, 'member'])),
  access: z.record(z.string(), z.unknown()).optional(),
});

function allows(level: Level, need: CalendarNeed): boolean {
  return need === 'view' ? level === 'view' || level === 'edit' : level === 'edit';
}

/**
 * The caller, refused unless the household's `calendar` grant gives them
 * [need] — `view` to see the providers or the feed link, `edit` to bring a
 * calendar into the family week or change one (household ADR-0003, calendar
 * ADR-0003). A kid device never gets here: `requireUid` refuses it.
 */
export async function callerIn(
  store: Firestore,
  householdId: string,
  uid: string,
  need: CalendarNeed,
): Promise<Caller> {
  const snapshot = await householdRef(store, householdId).get();
  const household = householdShape.safeParse(snapshot.data());
  if (!snapshot.exists || !household.success) throw refuseCalendarSync('notAMember');
  const role = household.data.members[uid];
  if (role === undefined) throw refuseCalendarSync('notAMember');
  const level = memberLevelIn(role, household.data.access?.[uid], 'calendar');
  if (!allows(level, need)) throw refuseCalendarSync('calendarNotShared');

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
