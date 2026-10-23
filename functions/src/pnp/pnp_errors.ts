import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way an Add to Pick n Pay call can refuse (add-to-pnp ADR-0003).
 * Same contract as Checkers' (BE-04): each carries its `reason` in the
 * error's details and the app maps that string to a sentence; the message is
 * for a log.
 */
export const PNP_REFUSALS = {
  // The `addToPnp` switch is off (foundation ADR-0014).
  'pnp-switched-off': ['failed-precondition', 'Add to Pick n Pay is switched off.'],
  // Completed with no live start: none, lapsed after fifteen minutes, or used.
  'pnp-no-pending-link': ['failed-precondition', 'Start linking Pick n Pay again.'],
  // The state did not match the start, or PnP would not take the code.
  'pnp-link-refused': ['invalid-argument', 'Pick n Pay did not accept that sign-in.'],
  // No session, or PnP no longer takes its tokens: the member links again.
  'pnp-link-expired': ['failed-precondition', 'The Pick n Pay link has expired.'],
  // PnP could not be reached, answered 429 or 5xx, or the key is missing.
  'pnp-down': ['unavailable', 'Pick n Pay is not answering right now.'],
  // The member's PnP cart has no store yet: PnP sets one from a delivery address.
  'pnp-no-delivery-address': ['failed-precondition', 'Set a delivery address in Pick n Pay first.'],
  'not-a-member': ['permission-denied', 'You are not in this household.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type PnpRefusal = keyof typeof PNP_REFUSALS;

/** The one place an Add to Pick n Pay refusal becomes the error the client receives. */
export function refusePnp(reason: PnpRefusal): HttpsError {
  const [code, message] = PNP_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
