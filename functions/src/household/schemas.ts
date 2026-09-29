import { z } from 'zod';

import { AREAS, AREA_LEVELS, LEVELS, type Area } from './access';
import { ROLES, type AssignableRole } from './documents';

/**
 * Every callable's input, parsed at the edge and never cast (ENG-09, BE-03).
 * Anything the server can derive — who the caller is, what role they hold, when
 * it happened — is absent here on purpose: it is re-derived, not trusted.
 */

const trimmedName = z.string().trim().min(1).max(60);

/** The colour is one of the fixed member palette's names (design-system ADR-0001). */
const memberColor = z.string().trim().min(1).max(20);

/**
 * An IANA zone name. The exact list is the client's business; the server checks
 * only that it is the right shape, so a zone added to tzdata later is not
 * refused by a Function deployed today.
 */
const timeZone = z
  .string()
  .trim()
  .min(1)
  .max(64)
  .regex(/^[A-Za-z0-9+_\-/]+$/, 'not an IANA time zone name');

export const createHouseholdInput = z.object({
  name: trimmedName,
  timeZone,
  adminDisplayName: trimmedName,
  adminColor: memberColor,
});
export type CreateHouseholdInput = z.infer<typeof createHouseholdInput>;

export const createInviteInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  memberId: z.string().trim().min(1).max(64),
});
export type CreateInviteInput = z.infer<typeof createInviteInput>;

export const redeemInviteInput = z.object({
  // Codes are shown and typed in upper case; accept either and normalise.
  code: z
    .string()
    .trim()
    .min(4)
    .max(16)
    .transform((value) => value.toUpperCase()),
});
export type RedeemInviteInput = z.infer<typeof redeemInviteInput>;

export const leaveHouseholdInput = z.object({
  householdId: z.string().trim().min(1).max(64),
});
export type LeaveHouseholdInput = z.infer<typeof leaveHouseholdInput>;

export const removeMemberInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  memberId: z.string().trim().min(1).max(64),
});
export type RemoveMemberInput = z.infer<typeof removeMemberInput>;

/**
 * An app installed before household ADR-0003 still sends `member` for a family
 * adult. It is accepted and written as `parent`, so the old app keeps working
 * and the old name stops spreading (BE-10, BE-17).
 */
const assignableRole = z
  .enum([...ROLES, 'member'])
  .transform((role): AssignableRole => (role === 'member' ? 'parent' : role));

export const setMemberRoleInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  memberId: z.string().trim().min(1).max(64),
  role: assignableRole,
});
export type SetMemberRoleInput = z.infer<typeof setMemberRoleInput>;

/**
 * A whole grant: every area named exactly once, each at a level that area
 * accepts (household ADR-0003). A partial grant is refused rather than filled
 * in, because "the parent did not say" and "none" are different answers and
 * only the client knows which it meant.
 */
const level = z.enum(LEVELS);
const grant = z
  .object({
    calendar: level,
    groceries: level,
    todos: level,
    meals: level,
    documents: level,
    lunch: level,
    familyProfiles: level,
    medical: level,
    homeCare: level,
    nannyHub: level,
  } satisfies Record<Area, typeof level>)
  .strict()
  .refine((value) => AREAS.every((area) => AREA_LEVELS[area].includes(value[area])));

export const setMemberAccessInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  memberId: z.string().trim().min(1).max(64),
  access: grant,
});
export type SetMemberAccessInput = z.infer<typeof setMemberAccessInput>;
