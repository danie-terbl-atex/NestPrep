import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way a chore-points call can refuse (todos ADR-0003).
 *
 * Same contract as the household refusals (BE-04): each carries its own
 * `reason` and the client maps that to a sentence. `notAMember` reuses the
 * household's name because it is the same fact; the client already has copy
 * for it.
 */
export const CHORE_POINT_REFUSALS = {
  notAMember: ['permission-denied', 'You are not in this household.'],
  // Stars are a parent's to give and to hand over, whatever a grant says.
  notFamily: ['permission-denied', 'Only a parent can do that.'],
  claimNotFound: ['not-found', 'That chore is not waiting for anybody.'],
  requestNotFound: ['not-found', 'That reward request no longer exists.'],
  // Somebody got there first: approved, sent back, handed over or declined
  // already, or unticked by the child.
  alreadySettled: ['failed-precondition', 'That has already been dealt with.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type ChorePointRefusal = keyof typeof CHORE_POINT_REFUSALS;

/** The one place a chore-points refusal becomes the error the client receives. */
export function refusePoints(reason: ChorePointRefusal): HttpsError {
  const [code, message] = CHORE_POINT_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
