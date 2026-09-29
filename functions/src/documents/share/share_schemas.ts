import { Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';

import { SHARE_LIFETIME_HOURS } from './share_policy';

/**
 * The shared-link callables' input, parsed at the edge and never cast
 * (`ENG-09`, `BE-03`). Every field is required, and the optional ones are
 * required-and-nullable, so the app always says what it means.
 */
const id = z.string().trim().min(1).max(64);

export const createDocumentShareInput = z
  .object({
    householdId: id,
    // `null` for a household document; the vault's member for a vault one.
    ownerMemberId: id.nullable(),
    documentId: id,
    // Exactly one of these two: a chosen lifetime, or an open shift.
    lifetimeHours: z
      .number()
      .int()
      .refine((hours) => (SHARE_LIFETIME_HOURS as readonly number[]).includes(hours))
      .nullable(),
    shiftId: id.nullable(),
    pin: z
      .string()
      .regex(/^[0-9]{4,8}$/)
      .nullable(),
  })
  .refine((input) => (input.lifetimeHours === null) !== (input.shiftId === null));
export type CreateDocumentShareInput = z.infer<typeof createDocumentShareInput>;

export const revokeDocumentShareInput = z.object({
  householdId: id,
  shareId: id,
});
export type RevokeDocumentShareInput = z.infer<typeof revokeDocumentShareInput>;

/** What a link's secrets look like when read back (`ENG-09`). */
export const storedToken = z.object({
  householdId: z.string(),
  shareId: z.string(),
  pinHash: z.string().nullable(),
  pinSalt: z.string().nullable(),
  failedPinAttempts: z.number().int().nonnegative(),
});
export type StoredToken = z.infer<typeof storedToken>;

/** What the family sees of a link, as the serving side needs it. */
export const storedShare = z.object({
  scope: z.enum(['household', 'vault']),
  ownerMemberId: z.string().nullable(),
  documentId: z.string(),
  createdByUid: z.string(),
  expiresAt: z.instanceof(Timestamp),
  shiftId: z.string().nullable(),
  hasPin: z.boolean(),
  status: z.enum(['active', 'revoked', 'ended', 'locked']),
});
export type StoredShare = z.infer<typeof storedShare>;
