import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way a kid sign-in call can refuse that the household vocabulary has no
 * word for (accounts ADR-0003).
 *
 * Same contract as the household and documents refusals (`BE-04`): each
 * carries its own `reason` in the error's details, and the client maps that
 * string to a sentence. "Only an admin can do that", "that person is no longer
 * in the household" and "a kid sign-in cannot do that" are the household's
 * `refuse()`, because they are the same sentence whichever callable said them.
 */
export const KID_REFUSALS = {
  notEligible: ['failed-precondition', 'That profile cannot have a kid sign-in.'],
  tooManyDevices: ['resource-exhausted', 'That profile already has as many devices as it may.'],
  codeNotFound: ['not-found', 'That is not a live pairing code.'],
  codeExpired: ['deadline-exceeded', 'That pairing code has expired.'],
  deviceNotFound: ['not-found', 'That device is no longer signed in.'],
  signInUnavailable: ['unavailable', 'Kid sign-in cannot mint a token right now.'],
  // Too many redemptions from one address: the guard against guessing codes
  // on the one callable anybody can reach (accounts ADR-0006).
  tooManyAttempts: ['resource-exhausted', 'Too many codes tried. Wait and try again.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type KidRefusal = keyof typeof KID_REFUSALS;

/** The one place a kid sign-in refusal becomes the error the client receives. */
export function refuseKid(reason: KidRefusal): HttpsError {
  const [code, message] = KID_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
