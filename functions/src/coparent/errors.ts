import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way a co-parenting call can refuse (household ADR-0004).
 *
 * Same contract as the household refusals (BE-04): each carries its own
 * `reason` and the client maps that to a sentence. `notAMember` and
 * `notAnAdmin` reuse the household's names because they are the same facts,
 * and the client already has words for them. The messages here are for a log;
 * the copy a person reads is calm and blames nobody.
 */
export const COPARENT_REFUSALS = {
  notAMember: ['permission-denied', 'You are not in this household.'],
  notAnAdmin: ['permission-denied', 'Only an admin can do that.'],
  // Handovers and requests are for the adults who run the week.
  notFamily: ['permission-denied', 'Only a parent can do that.'],
  linkInviteNotFound: ['not-found', 'That code is not a two-homes code.'],
  linkInviteExpired: ['deadline-exceeded', 'That code has expired.'],
  linkInviteUsed: ['already-exists', 'That code has already been used.'],
  // A household cannot be the other home of its own child.
  sameHousehold: ['failed-precondition', 'That code was made in this household.'],
  childNotFound: ['not-found', 'That child is not in this household.'],
  childAlreadyLinked: ['already-exists', 'That child is already linked with another home.'],
  linkNotFound: ['not-found', 'That link does not exist.'],
  // Pending, declined or ended: nothing new is shared until it is active.
  linkNotActive: ['failed-precondition', 'That link is not active.'],
  // The other home confirms, answers or withdraws — never the same one twice.
  notYourTurn: ['failed-precondition', 'That is for the other home to answer.'],
  requestNotFound: ['not-found', 'That request no longer exists.'],
  requestAlreadyAnswered: ['failed-precondition', 'That request has already been answered.'],
  tooManyRequests: ['resource-exhausted', 'There are already enough open requests.'],
  dateOutOfRange: ['out-of-range', 'That date is too far away.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type CoParentRefusal = keyof typeof COPARENT_REFUSALS;

/** The one place a co-parenting refusal becomes the error the client receives. */
export function refuseCoParent(reason: CoParentRefusal): HttpsError {
  const [code, message] = COPARENT_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
