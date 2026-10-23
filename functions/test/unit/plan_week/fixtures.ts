import {
  foodRulesFrom,
  type ChildFoodRules,
  type StoredFoodFacts,
} from '../../../src/plan_week/food_safety';
import type { SchoolWeek } from '../../../src/plan_week/open_compartments';
import type { FoundProduct } from '../../../src/plan_week/schemas';
import type { PlannedWeek } from '../../../src/plan_week/week_brief';
import type { LunchPlanFacts } from '../../../src/plan_week/week_documents';

export function rulesOf(facts: Partial<StoredFoodFacts> = {}): ChildFoodRules {
  return foodRulesFrom({
    allergyCodes: [],
    otherAllergies: [],
    diet: [],
    schoolIsNutFree: false,
    likes: [],
    dislikes: [],
    ...facts,
  });
}

export function productOf(fields: Partial<FoundProduct> = {}): FoundProduct {
  return {
    productId: 'prod-1',
    name: 'Apples 1.5kg',
    brand: null,
    priceCents: 3499,
    isOnPromotion: false,
    allergens: [],
    allergensKnown: true,
    packQuantity: null,
    ...fields,
  };
}

/** The Monday of the week every plan_week test plans. */
export const MONDAY = '2026-10-05';

/** That week, seen from the Saturday before it: no school day has gone. */
export const SCHOOL_WEEK: SchoolWeek = { monday: MONDAY, today: '2026-10-03' };

export function weekOf(
  plans: readonly LunchPlanFacts[],
  budgetCents: number | null,
  fields: Partial<PlannedWeek> = {},
): PlannedWeek {
  return { ...SCHOOL_WEEK, plans, budgetCents, prices: {}, ...fields };
}
