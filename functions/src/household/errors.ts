import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way a household call can refuse.
 *
 * The gRPC code alone is not enough to choose copy — three different refusals
 * are all `already-exists` — so each carries a `reason` in the error's details
 * and the client maps that to a sentence (BE-04). The message here is for a log
 * and a console; it never reaches a person.
 */
export const HOUSEHOLD_REFUSALS = {
  notAMember: ['permission-denied', 'You are not in this household.'],
  notAnAdmin: ['permission-denied', 'Only an admin can do that.'],
  householdNotFound: ['not-found', 'That household no longer exists.'],
  memberNotFound: ['not-found', 'That member no longer exists.'],
  inviteNotFound: ['not-found', 'That code is not a NestPrep invite.'],
  inviteExpired: ['deadline-exceeded', 'That invite has expired.'],
  inviteAlreadyUsed: ['already-exists', 'That invite has already been used.'],
  memberAlreadyClaimed: ['already-exists', 'Somebody has already claimed that profile.'],
  alreadyInHousehold: ['already-exists', 'You are already in that household.'],
  lastAdmin: ['failed-precondition', 'A household needs an admin.'],
  cannotRemoveSelf: ['failed-precondition', 'Leave the household instead of removing yourself.'],
  emailNotVerified: ['failed-precondition', 'Verify your email address first.'],
  familyHasFullAccess: ['failed-precondition', 'Family members already see everything.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type HouseholdRefusal = keyof typeof HOUSEHOLD_REFUSALS;

/** The one place a refusal becomes the error the client receives. */
export function refuse(reason: HouseholdRefusal): HttpsError {
  const [code, message] = HOUSEHOLD_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
