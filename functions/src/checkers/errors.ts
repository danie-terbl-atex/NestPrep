import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way an Add to Checkers call can refuse (the Checkers build contract).
 *
 * Same contract as the other features' refusals (BE-04): each carries its
 * `reason` in the error's details and the app maps that string to a sentence.
 * The reasons are the contract's own kebab-case strings, which the app's
 * `add_to_checkers` feature keys on; the message is for a log.
 */
export const CHECKERS_REFUSALS = {
  // The `addToCheckers` switch is off (foundation ADR-0014).
  'checkers-switched-off': ['failed-precondition', 'Add to Checkers is switched off.'],
  'bad-mobile': ['invalid-argument', 'That is not a South African mobile number.'],
  'otp-rate-limited': ['resource-exhausted', 'Too many codes asked for; try again later.'],
  'no-pending-otp': ['failed-precondition', 'Ask for a new code first.'],
  'wrong-code': ['invalid-argument', 'That code is not the one Checkers sent.'],
  // No session, or its hour is up: the member links again by SMS.
  'checkers-link-expired': ['failed-precondition', 'The Checkers link has expired.'],
  // Checkers named no Sixty60 store for the member's delivery address.
  'no-checkers-store': ['failed-precondition', 'No Sixty60 store delivers to that address.'],
  'not-a-member': ['permission-denied', 'You are not in this household.'],
  // Checkers could not be reached, answered 429 or 5xx, or was not configured.
  'checkers-down': ['unavailable', 'Checkers is not answering right now.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type CheckersRefusal = keyof typeof CHECKERS_REFUSALS;

/** The one place an Add to Checkers refusal becomes the error the client receives. */
export function refuseCheckers(reason: CheckersRefusal): HttpsError {
  const [code, message] = CHECKERS_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
