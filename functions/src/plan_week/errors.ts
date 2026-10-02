import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way planning a week can refuse that is its own (lunch-box ADR-0012).
 * Membership refuses with the household's `notAMember`, premium with
 * subscriptions' `premiumRequired` (feature `aiPlanning`), and the model with
 * the shared AI reasons (`aiLimitReached`…). Same contract as every refusal
 * (BE-04): the app's `PlanWeekProblem` maps the reason.
 */
export const PLAN_WEEK_REFUSALS = {
  // The `planMyWeek` flag is off (foundation ADR-0014).
  planWeekOff: ['failed-precondition', 'Planning the week is switched off.'],
  // The caller may not change the household's lunches.
  lunchNotShared: ['permission-denied', 'You cannot plan lunches in this household.'],
  // Nothing to plan: none of the members asked for is a child.
  nothingToPlan: ['invalid-argument', 'Choose a child to plan.'],
  // A week that is not one, or one long gone.
  weekNotPlannable: ['invalid-argument', 'That week cannot be planned.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type PlanWeekRefusal = keyof typeof PLAN_WEEK_REFUSALS;

export function refusePlanWeek(reason: PlanWeekRefusal): HttpsError {
  const [code, message] = PLAN_WEEK_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
