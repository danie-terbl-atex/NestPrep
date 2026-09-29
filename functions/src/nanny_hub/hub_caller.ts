import { z } from 'zod';

import { isFamilyRole, memberLevelIn } from '../household/access';
import { ROLES } from '../household/documents';
import { refuseNanny } from './errors';

/**
 * Who is calling a nanny-hub callable, re-derived from the household document
 * the rules read, never from the request (BE-03, BE-05).
 */
export interface HubCaller {
  readonly uid: string;
  readonly isFamily: boolean;
  /** The profile this account claimed; a shift's carer is compared with it. */
  readonly memberId: string | null;
}

// `member` is household ADR-0001's family adult, still on households made
// before ADR-0003 and read as a parent.
const householdShape = z.object({
  members: z.record(z.string(), z.enum([...ROLES, 'member'])),
  access: z.record(z.string(), z.unknown()).optional(),
  profiles: z.record(z.string(), z.string()).optional(),
});

/**
 * The caller, refused unless the household's `nannyHub` grant is `edit` for
 * them — what writing the hub needs, in the rules and here alike (household
 * ADR-0003, nanny-hub ADR-0003). Pure over the household data, so the
 * decision is tested without an emulator.
 */
export function hubEditorFrom(householdData: unknown, uid: string): HubCaller {
  const household = householdShape.safeParse(householdData);
  if (!household.success) throw refuseNanny('notAMember');
  const role = household.data.members[uid];
  if (role === undefined) throw refuseNanny('notAMember');
  if (memberLevelIn(role, household.data.access?.[uid], 'nannyHub') !== 'edit') {
    throw refuseNanny('hubNotShared');
  }
  return {
    uid,
    isFamily: isFamilyRole(role),
    memberId: household.data.profiles?.[uid] ?? null,
  };
}

/** A carer ends their own shift; family ends anybody's (nanny-hub ADR-0002). */
export function mayEndShift(caller: HubCaller, carerMemberId: string): boolean {
  return caller.isFamily || caller.memberId === carerMemberId;
}
