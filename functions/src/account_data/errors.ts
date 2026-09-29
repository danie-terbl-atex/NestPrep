import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way an account-data call can refuse that the household vocabulary has
 * no word for (accounts ADR-0006). Same contract as the household refusals
 * (`BE-04`): the reason travels in the error's details and the client maps it
 * to a sentence; the message is for a log.
 */
export const ACCOUNT_DATA_REFUSALS = {
  // The households the person agreed to end are not the ones deleting would
  // end now — somebody joined or left since the preview was read.
  deletionPlanChanged: ['failed-precondition', 'What deleting would do has changed.'],
  // The typed confirmation did not match; the client never sends one that
  // does not, so this is a guard, not a conversation.
  deletionNotConfirmed: ['invalid-argument', 'Deleting an account needs its confirmation.'],
  tooManyRequests: ['resource-exhausted', 'Too many requests. Wait a little and try again.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type AccountDataRefusal = keyof typeof ACCOUNT_DATA_REFUSALS;

export function refuseAccountData(reason: AccountDataRefusal): HttpsError {
  const [code, message] = ACCOUNT_DATA_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
