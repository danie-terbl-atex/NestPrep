import { z } from 'zod';

import { memberLevelIn, type Level } from '../household/access';
import { ROLES } from '../household/documents';
import { refuseHomeCare } from './errors';

/**
 * Who is calling a home-care callable, re-derived from the household document
 * the rules read, never from the request (BE-03, BE-05).
 */
export interface HomeCareCaller {
  readonly uid: string;
  readonly level: Exclude<Level, 'none'>;
}

// `member` is household ADR-0001's family adult, still on households made
// before ADR-0003 and read as a parent.
const householdShape = z.object({
  members: z.record(z.string(), z.enum([...ROLES, 'member'])),
  access: z.record(z.string(), z.unknown()).optional(),
});

/**
 * The caller, refused unless the household's `homeCare` grant gives them
 * anything at all — what reading home care needs, in the rules and here
 * alike (household ADR-0003). Pure over the household data, so the decision
 * is tested without an emulator.
 */
export function homeCareReaderFrom(householdData: unknown, uid: string): HomeCareCaller {
  const household = householdShape.safeParse(householdData);
  if (!household.success) throw refuseHomeCare('notAMember');
  const role = household.data.members[uid];
  if (role === undefined) throw refuseHomeCare('notAMember');
  const level = memberLevelIn(role, household.data.access?.[uid], 'homeCare');
  if (level === 'none') throw refuseHomeCare('homeCareNotShared');
  return { uid, level };
}
