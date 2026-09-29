import { z } from 'zod';

/**
 * Every account-data input, parsed at the edge and never cast (`ENG-09`,
 * `BE-03`). Whose account it is comes from the token, never the body — which
 * is why previewing a deletion and exporting data take no body at all.
 */

/** The word a person types to say they mean it; the client shows it in capitals. */
export const DELETION_CONFIRMATION = 'DELETE';

export const deleteAccountInput = z
  .object({
    confirmation: z.string().trim().max(20),
    // The households the preview said would end, which the person read and
    // accepted. The server recomputes the plan and refuses if it now differs
    // (accounts ADR-0006), so this is agreement, never instruction.
    endingHouseholdIds: z.array(z.string().trim().min(1).max(64)).max(20),
  })
  .strict();
export type DeleteAccountInput = z.infer<typeof deleteAccountInput>;

/** The public deletion-request form's body (hosting `/delete-account`). */
export const accountDeletionRequestInput = z
  .object({
    email: z.string().trim().toLowerCase().max(254).pipe(z.email()),
    message: z.string().trim().max(1000).optional(),
  })
  .strict();
export type AccountDeletionRequestInput = z.infer<typeof accountDeletionRequestInput>;
