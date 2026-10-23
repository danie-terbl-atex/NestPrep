import { z } from 'zod';

import { memberLevelIn } from '../household/access';
import { ROLES } from '../household/documents';

// `member` is household ADR-0001's family adult, still on households made
// before ADR-0003 and read as a parent.
const householdShape = z.object({
  members: z.record(z.string(), z.enum([...ROLES, 'member'])),
  access: z.record(z.string(), z.unknown()).optional(),
});

/**
 * Whether the caller may see the household's grocery list — what reading the
 * items a push names needs, in the rules and here alike (household ADR-0003).
 * Re-derived from the household document, never the request (BE-03, BE-05).
 * Each shop's push turns a no into its own refusal.
 */
export function mayReadGroceries(householdData: unknown, uid: string): boolean {
  const household = householdShape.safeParse(householdData);
  if (!household.success) return false;
  const role = household.data.members[uid];
  if (role === undefined) return false;
  return memberLevelIn(role, household.data.access?.[uid], 'groceries') !== 'none';
}
