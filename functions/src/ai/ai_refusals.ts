import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way an AI call can refuse, shared by every AI feature (foundation
 * ADR-0015).
 *
 * Same contract as the household refusals (BE-04): the reason travels in the
 * error's details and the app's `AiProblem` maps it to a sentence;
 * `calendar_v2_contract_test.dart` reads this block. The messages are for a
 * log; none reaches a person.
 */
export const AI_REFUSALS = {
  // The kill switch, or this feature's own switch, is off.
  aiSwitchedOff: ['failed-precondition', 'AI features are switched off.'],
  // The household has spent this month's calls.
  aiLimitReached: ['resource-exhausted', 'This household has used its AI calls for the month.'],
  // The model could not be reached, or kept failing.
  aiUnavailable: ['unavailable', 'The AI model did not answer.'],
  // The model answered twice in a shape that could not be read.
  aiUnreadable: ['internal', 'The AI answer could not be read.'],
  // The model declined the content (a safety filter).
  aiDeclined: ['failed-precondition', 'The AI model would not read that.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type AiRefusal = keyof typeof AI_REFUSALS;

/** The one place an AI refusal becomes the error the client receives. */
export function refuseAi(reason: AiRefusal): HttpsError {
  const [code, message] = AI_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
