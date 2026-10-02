import type { Firestore } from 'firebase-admin/firestore';

import { FAMILY_PROFILES } from '../family_profiles/member_details';
import { householdRef } from '../household/documents';
import { foodRulesFrom, isAllergen, type ChildFoodRules } from './food_safety';
import { historyStart } from './taste';
import {
  LUNCH_BUDGET,
  LUNCH_PLANS,
  PLAN_LIMIT,
  SCHOOLS,
  WEEKLY_BUDGET,
  planFrom,
  storedBudget,
  storedOtherAllergy,
  storedProfile,
  storedSchool,
  type LunchPlanFacts,
} from './week_documents';

/** Everything in a household a week's lunches are planned from, read once. */
export interface WeekFacts {
  readonly children: readonly ChildFacts[];
  /** This week's plans and the eight weeks before, for what is open and what was eaten. */
  readonly plans: readonly LunchPlanFacts[];
  /** The household's weekly lunch budget in cents, for every child together; null when unset. */
  readonly budgetCents: number | null;
}

export interface ChildFacts {
  readonly memberId: string;
  readonly rules: ChildFoodRules;
}

/** Every profile in a household, whoever it is — far above any real family. */
const PROFILE_LIMIT = 30;

export async function readWeekFacts(
  store: Firestore,
  householdId: string,
  monday: string,
): Promise<WeekFacts> {
  const household = householdRef(store, householdId);
  const [profiles, schools, plans, budget] = await Promise.all([
    household.collection(FAMILY_PROFILES).limit(PROFILE_LIMIT).get(),
    household.collection(SCHOOLS).limit(PROFILE_LIMIT).get(),
    household
      .collection(LUNCH_PLANS)
      .where('weekStart', '>=', historyStart(monday))
      .where('weekStart', '<=', monday)
      .limit(PLAN_LIMIT)
      .get(),
    household.collection(LUNCH_BUDGET).doc(WEEKLY_BUDGET).get(),
  ]);

  const nutFreeSchools = new Set(
    schools.docs
      .filter((school) => storedSchool.safeParse(school.data()).data?.nutFree === true)
      .map((school) => school.id),
  );

  const children: ChildFacts[] = [];
  for (const doc of profiles.docs) {
    const profile = storedProfile.safeParse(doc.data());
    if (!profile.success || !profile.data.isChild) continue;
    const rules = foodRulesFrom({
      allergyCodes: Object.keys(profile.data.allergies).filter(isAllergen),
      otherAllergies: Object.values(profile.data.otherAllergies).flatMap((entry) => {
        const other = storedOtherAllergy.safeParse(entry);
        return other.success ? [other.data.name] : [];
      }),
      diet: profile.data.diet,
      schoolIsNutFree:
        typeof profile.data.schoolId === 'string' && nutFreeSchools.has(profile.data.schoolId),
      likes: profile.data.likes,
      dislikes: profile.data.dislikes,
    });
    children.push({ memberId: doc.id, rules });
  }

  const storedWeekly = storedBudget.safeParse(budget.data());
  return {
    children,
    plans: plans.docs.flatMap((doc) => planFrom(doc.data()) ?? []),
    budgetCents: budget.exists && storedWeekly.success ? storedWeekly.data.cents : null,
  };
}
