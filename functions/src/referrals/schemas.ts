import { z } from 'zod';

import { isReadableCode } from '../shared/readable_code';
import { REFERRAL_CODE_LENGTH } from './referral_policy';

/**
 * The referrals callables' input, parsed at the edge and never cast (`ENG-09`,
 * `BE-03`). Who the caller is, which household a code belongs to and whether
 * anything qualifies are all re-derived on the server.
 */
const id = z.string().trim().min(1).max(64);

export const ensureReferralCodeInput = z.object({ householdId: id });

export const redeemReferralCodeInput = z.object({
  householdId: id,
  /** Typed by a person: spaces and case forgiven, anything else refused. */
  code: z
    .string()
    .transform((value) => value.replace(/\s+/g, '').toUpperCase())
    .refine((value) => isReadableCode(value, REFERRAL_CODE_LENGTH)),
});
export type RedeemReferralCodeInput = z.infer<typeof redeemReferralCodeInput>;
