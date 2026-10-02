import { z } from 'zod';

/**
 * The stored shapes planning a week reads, parsed — never cast (ENG-09). A
 * document that does not parse is left out rather than failing the plan: one
 * odd item must not stop a family planning its week (BE-10).
 */

export const LUNCH_SLOTS = ['main', 'fruit', 'veg', 'snack', 'treat'] as const;
export type LunchSlot = (typeof LUNCH_SLOTS)[number];

export function isLunchSlot(value: string): value is LunchSlot {
  return (LUNCH_SLOTS as readonly string[]).includes(value);
}

export const LUNCH_PLANS = 'lunchPlans';
export const SCHOOLS = 'schools';
export const LUNCH_BUDGET = 'lunchBudget';
export const WEEKLY_BUDGET = 'weekly';

/** The bounds the app's repositories read with (BE-08). */
export const PLAN_LIMIT = 120;

const strings = z
  .array(z.unknown())
  .transform((list) => list.filter((entry): entry is string => typeof entry === 'string'));

const storedPick = z.object({
  itemId: z.string().min(1),
  name: z.string(),
  allergens: strings.optional().default([]),
});
export type StoredPick = z.infer<typeof storedPick>;

const storedFeedback = z.object({
  verdict: z.enum(['ate', 'left']),
  items: z.record(z.string(), z.unknown()).optional().default({}),
});

export const storedPlan = z.object({
  childId: z.string(),
  weekStart: z.string(),
  slots: z.record(z.string(), z.unknown()).optional().default({}),
  feedback: z.record(z.string(), z.unknown()).optional().default({}),
});

export interface LunchPlanFacts {
  readonly childId: string;
  readonly weekStart: string;
  readonly slots: Readonly<Record<string, StoredPick>>;
  readonly feedback: Readonly<Record<string, z.infer<typeof storedFeedback>>>;
}

/** A plan, keeping only the picks and marks that parse. */
export function planFrom(data: unknown): LunchPlanFacts | null {
  const plan = storedPlan.safeParse(data);
  if (!plan.success) return null;
  const slots: Record<string, StoredPick> = {};
  for (const [key, value] of Object.entries(plan.data.slots)) {
    const pick = storedPick.safeParse(value);
    if (pick.success) slots[key] = pick.data;
  }
  const feedback: Record<string, z.infer<typeof storedFeedback>> = {};
  for (const [day, value] of Object.entries(plan.data.feedback)) {
    const mark = storedFeedback.safeParse(value);
    if (mark.success) feedback[day] = mark.data;
  }
  return { childId: plan.data.childId, weekStart: plan.data.weekStart, slots, feedback };
}

export const storedProfile = z.object({
  isChild: z.boolean().optional().default(false),
  allergies: z.record(z.string(), z.unknown()).optional().default({}),
  otherAllergies: z.record(z.string(), z.unknown()).optional().default({}),
  diet: strings.optional().default([]),
  likes: strings.optional().default([]),
  dislikes: strings.optional().default([]),
  schoolId: z.string().nullable().optional(),
});

export const storedOtherAllergy = z.object({ name: z.string().min(1) });

export const storedSchool = z.object({ nutFree: z.boolean().optional().default(false) });

/** The household's weekly lunch budget, whole rand cents (lunch-box ADR-0007). */
export const storedBudget = z.object({ cents: z.number().int().min(0) });

/** `{isoWeekday}_{slot}`, as a lunch plan keys its slots. */
export function slotKey(day: number, slot: string): string {
  return `${String(day)}_${slot}`;
}
