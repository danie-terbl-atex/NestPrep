import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

export const WOOLWORTHS_REFUSALS = {
  'woolworths-switched-off': ['failed-precondition', 'Add to Woolworths is switched off.'],
  'woolworths-not-linked': ['failed-precondition', 'Link your Woolworths account first.'],
  'woolworths-link-expired': ['failed-precondition', 'The Woolworths link has expired.'],
  'woolworths-link-rejected': ['invalid-argument', 'Woolworths did not accept that sign-in.'],
  'woolworths-unavailable': ['unavailable', 'Woolworths is not answering right now.'],
  'woolworths-rejected': ['failed-precondition', 'Woolworths did not take those items.'],
  'woolworths-no-delivery-address': [
    'failed-precondition',
    'Set a delivery address in the Woolworths app first.',
  ],
  'not-a-member': ['permission-denied', 'You are not in this household.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type WoolworthsRefusal = keyof typeof WOOLWORTHS_REFUSALS;

export function refuseWoolworths(reason: WoolworthsRefusal): HttpsError {
  const [code, message] = WOOLWORTHS_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
