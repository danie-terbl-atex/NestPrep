import { z } from 'zod';

import { ROLES } from './documents';

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

export const setMemberRoleInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  memberId: z.string().trim().min(1).max(64),
  role: z.enum(ROLES),
});
export type SetMemberRoleInput = z.infer<typeof setMemberRoleInput>;
