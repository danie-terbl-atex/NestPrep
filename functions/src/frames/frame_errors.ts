import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way a photo frame call can refuse that the household vocabulary has
 * no word for (photo-frames ADR-0001).
 *
 * Same contract as the household and kid sign-in refusals (`BE-04`): each
 * carries its own `reason` in the error's details, and the client maps that
 * string to a sentence. "You are not in this household", "that household no
 * longer exists" and "a kid sign-in cannot do that" are the household's
 * `refuse()`, because they are the same sentence whichever callable said them.
 */
export const FRAME_REFUSALS = {
  notFamily: ['permission-denied', 'Only a parent can link a frame.'],
  framesOff: ['failed-precondition', 'Photo frames are switched off.'],
  frameCodeNotFound: ['not-found', 'That is not a code a frame is showing.'],
  frameCodeExpired: ['deadline-exceeded', 'That frame code has expired.'],
  tooManyFrames: ['resource-exhausted', 'This household already has as many frames as it may.'],
  helperNotFound: ['not-found', 'That person is no longer in the household.'],
  tooManyAttempts: ['resource-exhausted', 'Too many tries. Wait and try again.'],
  monthOutOfRange: ['out-of-range', 'A frame shows months within a year of this one.'],
  itemNotFound: ['not-found', 'That is not something this frame shows.'],
  itemOutOfReach: ['out-of-range', 'A frame ticks off today and the last week only.'],
  whoNeeded: ['failed-precondition', 'Say who did it.'],
  addingOff: ['failed-precondition', 'This frame does not add events.'],
  notAllowedToAdd: ['permission-denied', 'That person may not add to the calendar.'],
  eventOutOfReach: ['out-of-range', 'A frame adds events from today to a year ahead.'],
  frameNotFound: ['not-found', 'That frame is no longer linked.'],
  sharingOff: ['failed-precondition', 'This frame does not open shared pages.'],
  badLink: ['invalid-argument', 'A frame opens public web pages only.'],
  frameCantOpen: ['failed-precondition', 'This frame needs an update to open that.'],
  recipeNotFound: ['not-found', 'That recipe is no longer available.'],
  badRecipe: ['invalid-argument', 'That recipe could not be sent as it is.'],
  groceriesOff: ['failed-precondition', 'This frame does not add groceries.'],
  notAllowedToAddGroceries: ['permission-denied', 'That person may not add to the grocery list.'],
  shopUnavailable: ['unavailable', 'The shop is not answering right now.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type FrameRefusal = keyof typeof FRAME_REFUSALS;

/** The one place a photo frame refusal becomes the error the client receives. */
export function refuseFrame(reason: FrameRefusal): HttpsError {
  const [code, message] = FRAME_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
