import { z } from 'zod';

/** A household has a handful of children; this bounds the request (BE-08). */
export const MAX_PLANNED_CHILDREN = 12;

/**
 * How a week is to be planned, as the parent chose it on the phone (lunch-box
 * ADR-0011). `budget` is a hint the model leans on, never a limit anything is
 * refused by: `thrifty` asks it to prefer what costs least where the household
 * has priced things.
 */
export const PLAN_BUDGETS = ['none', 'thrifty'] as const;
export type PlanBudget = (typeof PLAN_BUDGETS)[number];

/**
 * Planning one week, parsed at the edge (ENG-09, BE-03). `childIds` names
 * which children's lunches to plan; an empty list plans none, and dinners
 * alone are a plan too. The week is ISO-8601, the key a lunch plan is filed
 * under.
 */
export const planMyWeekInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  week: z.string().regex(/^\d{4}-W\d{2}$/),
  childIds: z.array(z.string().trim().min(1).max(128)).max(MAX_PLANNED_CHILDREN),
  includeDinners: z.boolean(),
  useWhatsInTheHouse: z.boolean(),
  budget: z.enum(PLAN_BUDGETS),
});
export type PlanMyWeekInput = z.infer<typeof planMyWeekInput>;
