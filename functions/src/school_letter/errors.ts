import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way reading a school letter can refuse that is the letter's own
 * (calendar ADR-0005). Membership and the calendar grant refuse with calendar
 * sync's reasons (`notAMember`, `calendarNotShared`), and the model with the
 * shared AI ones (`aiLimitReached`…). Same contract as every refusal (BE-04):
 * the app's `SchoolLetterProblem` maps the reason, and
 * `calendar_v2_contract_test.dart` reads this block.
 */
export const SCHOOL_LETTER_REFUSALS = {
  // The `snapSchoolLetter` flag is off (foundation ADR-0014).
  letterFeatureOff: ['failed-precondition', 'Reading school letters is switched off.'],
  // Past the size a letter needs to be.
  letterTooLarge: ['invalid-argument', 'That file is too large to read.'],
  // Not a JPEG, PNG or PDF — whatever it claims to be.
  letterNotSupported: ['invalid-argument', 'That file is not a photo or a PDF.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type SchoolLetterRefusal = keyof typeof SCHOOL_LETTER_REFUSALS;

export function refuseLetter(reason: SchoolLetterRefusal): HttpsError {
  const [code, message] = SCHOOL_LETTER_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
