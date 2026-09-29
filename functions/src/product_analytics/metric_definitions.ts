/**
 * What the three beta numbers *mean*, written once (product-analytics ADR-0001).
 * Every count reads its rule from here; nothing else in the feature decides
 * what "active" or "invited in week one" is.
 */

/** How many distinct members must have opened the app in a week for their family to count. */
export const ACTIVE_MEMBERS_FOR_AN_ACTIVE_FAMILY = 2;

/** A family's first week: the 7 × 24 hours after its household was created. */
export const INVITE_WINDOW_MS = 7 * 24 * 60 * 60 * 1000;

/**
 * Roles that are children. "A second adult" is written as *not one of these*
 * rather than as a list of adult roles, because household phase 2 renames the
 * roles and a new adult role missing from an allow-list would silently stop
 * counting.
 */
export const CHILD_ROLES: readonly string[] = ['kid', 'child'];

/**
 * How long a per-household ledger document is kept before the TTL policy
 * deletes it. The weekly totals carry no identifier and are kept.
 */
export const LEDGER_RETENTION_MS = 400 * 24 * 60 * 60 * 1000;

/**
 * Bumped whenever a rule above changes meaning, and stored on every weekly
 * total, so a number computed under an old definition is never compared with a
 * new one without somebody noticing.
 */
// 2 (product-analytics ADR-0002): a conversion's trigger is the household's
// last paywall opening within seven days, no longer the phone's word alone.
export const DEFINITION_VERSION = 2;

/** Whether one household's week of activity makes it an active family. */
export function isActiveFamily(activeMemberIds: readonly string[]): boolean {
  return new Set(activeMemberIds).size >= ACTIVE_MEMBERS_FOR_AN_ACTIVE_FAMILY;
}

/** Whether anybody in the household opened the app that week. */
export function wasSeen(activeMemberIds: readonly string[]): boolean {
  return activeMemberIds.length > 0;
}

export function isChildRole(role: string): boolean {
  return CHILD_ROLES.includes(role);
}

/** Whether the first adult invite landed inside the household's first week. */
export function invitedAnAdultInWeekOne(household: {
  readonly createdAt: Date;
  readonly firstAdultInviteAt: Date | null;
}): boolean {
  const invitedAt = household.firstAdultInviteAt;
  if (invitedAt === null) return false;
  const elapsed = invitedAt.getTime() - household.createdAt.getTime();
  return elapsed >= 0 && elapsed < INVITE_WINDOW_MS;
}
