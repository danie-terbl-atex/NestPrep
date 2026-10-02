import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way a lunch photo can refuse that is its own (lunch-box ADR-0015).
 * Membership refuses with the household's `notAMember`, premium with
 * subscriptions' `premiumRequired` (feature `lunchPhoto`), and the model with
 * the shared AI reasons (`aiLimitReached`…). Same contract as every refusal
 * (BE-04): the reason travels in the error's details.
 */
export const LUNCH_PHOTO_REFUSALS = {
  // The caller may not see the household's lunches.
  lunchNotShared: ['permission-denied', 'You cannot see lunches in this household.'],
  // Nothing packed that day, or a weekend: there is no box to picture.
  emptyBox: ['invalid-argument', 'There is no lunch box to picture that day.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type LunchPhotoRefusal = keyof typeof LUNCH_PHOTO_REFUSALS;

export function refuseLunchPhoto(reason: LunchPhotoRefusal): HttpsError {
  const [code, message] = LUNCH_PHOTO_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
