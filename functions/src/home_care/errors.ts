import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way a home-care call can refuse (home-care ADR-0006).
 *
 * Same contract as the household refusals (BE-04): the gRPC code alone cannot
 * choose copy, so each carries its own `reason` in the error's details and
 * the app maps that string to a sentence. `notAMember` keeps the household
 * feature's name, because the app already has words for it. The app's
 * `HomeCareProblem` is the other half, and
 * `home_care_v2_contract_test.dart` reads this file to hold the two
 * together.
 */
export const HOME_CARE_REFUSALS = {
  notAMember: ['permission-denied', 'You are not in this household.'],
  // The household's `homeCare` grant is `none` for this caller.
  homeCareNotShared: ['permission-denied', 'Home care is not open to you.'],
  // The `homeCareHelperLanguage` switch is off (foundation ADR-0014).
  translationSwitchedOff: ['failed-precondition', 'Translation is switched off.'],
  // This month's characters are spent; cached texts still come back.
  translationLimitReached: ['resource-exhausted', 'This month’s translations are used up.'],
  // Google does not translate into this language.
  languageUnsupported: ['invalid-argument', 'That language cannot be translated.'],
  // Google could not be reached or would not answer; nothing was charged.
  translationUnavailable: ['unavailable', 'Translation is not available right now.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type HomeCareRefusal = keyof typeof HOME_CARE_REFUSALS;

/** The one place a home-care refusal becomes the error the client receives. */
export function refuseHomeCare(reason: HomeCareRefusal): HttpsError {
  const [code, message] = HOME_CARE_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
