import { onCall } from 'firebase-functions/v2/https';

import { parseInput, requireUid } from '../household/parse_input';
import { ERASURE_OPTIONS } from './account_data_options';
import { eraseAccount, liveErasureDeps } from './erase_account';
import { refuseAccountData } from './errors';
import { DELETION_CONFIRMATION, deleteAccountInput } from './schemas';

/**
 * Deletes the caller's account — the "Delete my account" both stores require
 * (accounts ADR-0006). The person has read `previewAccountDeletion`, typed the
 * confirmation and agreed to the households it ends; the plan is recomputed
 * here and nothing is deleted if it no longer matches what they agreed to.
 *
 * A kid device cannot call it (`requireUid`): a child's tablet is a parent's
 * to sign out, never an account to delete (accounts ADR-0003).
 */
export const deleteAccount = onCall(ERASURE_OPTIONS, async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(deleteAccountInput, request.data);
  if (input.confirmation !== DELETION_CONFIRMATION) {
    throw refuseAccountData('deletionNotConfirmed');
  }
  return eraseAccount(liveErasureDeps(), {
    uid,
    via: 'app',
    agreedEndings: input.endingHouseholdIds,
  });
});
