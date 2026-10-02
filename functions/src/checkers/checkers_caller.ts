import { z } from 'zod';

import { memberLevelIn } from '../household/access';
import { ROLES } from '../household/documents';
import { refuseCheckers } from './errors';

// `member` is household ADR-0001's family adult, still on households made
// before ADR-0003 and read as a parent.
const householdShape = z.object({
  members: z.record(z.string(), z.enum([...ROLES, 'member'])),
  access: z.record(z.string(), z.unknown()).optional(),
});

/**
 * Refuses unless the caller may see the household's grocery list — what
 * reading the items a push names needs, in the rules and here alike
 * (household ADR-0003). Re-derived from the household document, never the
 * request (BE-03, BE-05). Pure over the household data, so it is tested
 * without an emulator.
 */
export function requireGroceryReader(householdData: unknown, uid: string): void {
  const household = householdShape.safeParse(householdData);
  if (!household.success) throw refuseCheckers('not-a-member');
  const role = household.data.members[uid];
  if (role === undefined) throw refuseCheckers('not-a-member');
  if (memberLevelIn(role, household.data.access?.[uid], 'groceries') === 'none') {
    throw refuseCheckers('not-a-member');
  }
}
