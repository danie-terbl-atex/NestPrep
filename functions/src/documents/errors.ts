import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way a documents call can refuse.
 *
 * Same contract as the household refusals (BE-04): the gRPC code alone cannot
 * choose copy, so each carries its own `reason` in the error's details and the
 * client maps that string to a sentence. The message here is for a log; it
 * never reaches a person.
 *
 * `notAMember` and `notAnAdmin` deliberately reuse the household feature's
 * names, because that is what they are about — being in a household, and with
 * what role. The client maps them to the copy it already has rather than
 * inventing a second way of saying the same thing.
 */
export const DOCUMENT_REFUSALS = {
  notAMember: ['permission-denied', 'You are not in this household.'],
  notAnAdmin: ['permission-denied', 'Only an admin can do that.'],
  folderNotFound: ['not-found', 'That folder no longer exists.'],
  folderNotEmpty: ['failed-precondition', 'That folder still holds documents.'],
  // A personal vault the caller is neither the owner of, an admin of, nor
  // granted (documents ADR-0002).
  vaultNotShared: ['permission-denied', 'That vault has not been shared with you.'],
  documentNotFound: ['not-found', 'That document no longer exists.'],
  // Shared links (documents ADR-0006).
  featureOff: ['failed-precondition', 'That is switched off for now.'],
  notAllowedToShare: ['permission-denied', 'Only the family or its owner can share that.'],
  shiftNotOpen: ['failed-precondition', 'That shift has already ended.'],
  tooManyShares: ['resource-exhausted', 'Too many links are live at once.'],
  shareNotFound: ['not-found', 'That link no longer exists.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type DocumentRefusal = keyof typeof DOCUMENT_REFUSALS;

/** The one place a documents refusal becomes the error the client receives. */
export function refuseDocument(reason: DocumentRefusal): HttpsError {
  const [code, message] = DOCUMENT_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
