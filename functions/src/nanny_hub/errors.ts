import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way a nanny-hub call can refuse (nanny-hub ADR-0002).
 *
 * Same contract as the household refusals (BE-04): the gRPC code alone cannot
 * choose copy, so each carries its own `reason` in the error's details and the
 * client maps that string to a sentence. `notAMember` keeps the household
 * feature's name, because that is what it is about, and the client already has
 * words for it. The app's `NannyHubProblem` is the other half, and
 * `nanny_refusal_contract_test.dart` reads this file to hold the two together.
 */
export const NANNY_REFUSALS = {
  notAMember: ['permission-denied', 'You are not in this household.'],
  // The household's `nannyHub` grant is not `edit` for this caller.
  hubNotShared: ['permission-denied', 'The nanny hub is not open to you for writing.'],
  shiftNotFound: ['not-found', 'That shift does not exist.'],
  shiftAlreadyEnded: ['failed-precondition', 'That shift has already ended.'],
  // A carer ends their own shift; family ends anybody's.
  notYourShift: ['permission-denied', 'That shift is somebody else’s.'],
  // Marking a carer shift-only (nanny-hub ADR-0006). The first two keep the
  // household feature's names, which the client already has words for.
  notAnAdmin: ['permission-denied', 'Only an admin can change what somebody may see.'],
  memberNotFound: ['not-found', 'That person is not in this household.'],
  // Only a carer is ever shift-only: family sees everything, and a helper or
  // kid is not somebody a parent books by the shift.
  notACarer: ['failed-precondition', 'Only a carer can be limited to their booked shifts.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type NannyRefusal = keyof typeof NANNY_REFUSALS;

/** The one place a nanny-hub refusal becomes the error the client receives. */
export function refuseNanny(reason: NannyRefusal): HttpsError {
  const [code, message] = NANNY_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
