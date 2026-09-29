import { z } from 'zod';

/**
 * Every kid sign-in callable's input, parsed at the edge and never cast
 * (`ENG-09`, `BE-03`). Who is calling, and which profile a code belongs to,
 * are re-derived on the server — a kid's device sends nothing but the code.
 */

const id = z.string().trim().min(1).max(64);

export const createKidPairingInput = z.object({
  householdId: id,
  memberId: id,
  // What the parent calls this device on their list — "Mia's tablet". Optional:
  // an unnamed device is listed by when it was paired.
  label: z.string().trim().max(40).default(''),
});
export type CreateKidPairingInput = z.infer<typeof createKidPairingInput>;

export const cancelKidPairingInput = z.object({
  householdId: id,
  code: z
    .string()
    .trim()
    .min(4)
    .max(16)
    .transform((value) => value.toUpperCase()),
});
export type CancelKidPairingInput = z.infer<typeof cancelKidPairingInput>;

export const redeemKidPairingInput = z.object({
  // Shown in upper case and typed however a child types it; accept either.
  code: z
    .string()
    .trim()
    .min(4)
    .max(16)
    .transform((value) => value.toUpperCase()),
});
export type RedeemKidPairingInput = z.infer<typeof redeemKidPairingInput>;

export const revokeKidDeviceInput = z.object({
  householdId: id,
  deviceUid: z.string().trim().min(1).max(128),
});
export type RevokeKidDeviceInput = z.infer<typeof revokeKidDeviceInput>;

export const resetKidSignInInput = z.object({
  householdId: id,
  memberId: id,
});
export type ResetKidSignInInput = z.infer<typeof resetKidSignInInput>;
