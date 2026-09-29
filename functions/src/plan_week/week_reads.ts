import type { Firestore } from 'firebase-admin/firestore';

import { FAMILY_PROFILES } from '../family_profiles/member_details';
import { householdRef } from '../household/documents';
import { foodRulesFrom, isAllergen, type ChildFoodRules } from './food_safety';
import { historyStart } from './taste';
import {
  FAVOURITE_LIMIT,
  ITEM_LIMIT,
  LUNCH_FAVOURITES,
  LUNCH_ITEMS,
  LUNCH_PANTRY,
  LUNCH_PLANS,
  LUNCH_PRICES,
  MEALS,
  MEAL_LIMIT,
  MEAL_PLANS,
  PLAN_LIMIT,
  SCHOOLS,
  favouriteFrom,
  isLunchSlot,
  planFrom,
  storedItem,
  storedMeal,
  storedMealPlan,
  storedOtherAllergy,
  storedPantry,
  storedPrice,
  storedProfile,
  storedSchool,
  type FavouriteFacts,
  type LibraryItem,
  type LunchPlanFacts,
  type MealFacts,
} from './week_documents';

/** Everything in a household a week is planned from, read once. */
export interface WeekFacts {
  readonly children: readonly ChildFacts[];
  /** Every item not put away. */
  readonly library: readonly LibraryItem[];
  readonly plans: readonly LunchPlanFacts[];
  readonly favourites: readonly FavouriteFacts[];
  readonly meals: readonly MealFacts[];
  /** Weekday → the meal already planned for dinner. */
  readonly dinners: ReadonlyMap<number, string>;
  /** Item id → boxes' worth in the house; empty unless asked for. */
  readonly pantry: ReadonlyMap<string, number>;
  /** Item id → cents a box; empty unless asked for. */
  readonly prices: ReadonlyMap<string, number>;
  /** Everybody's rules, for checking a dinner nobody has cooked before. */
  readonly everybody: readonly ChildFoodRules[];
}

export interface ChildFacts {
  readonly memberId: string;
  readonly rules: ChildFoodRules;
}

/** Every profile in a household, whoever it is — far above any real family. */
const PROFILE_LIMIT = 30;

export interface WeekReadOptions {
  readonly monday: string;
  readonly withDinners: boolean;
  readonly withPantry: boolean;
  readonly withPrices: boolean;
}

export async function readWeekFacts(
  store: Firestore,
  householdId: string,
  options: WeekReadOptions,
): Promise<WeekFacts> {
  const household = householdRef(store, householdId);
  const [profiles, schools, items, plans, favourites, meals, mealPlan, pantry, prices] =
    await Promise.all([
      household.collection(FAMILY_PROFILES).limit(PROFILE_LIMIT).get(),
      household.collection(SCHOOLS).limit(PROFILE_LIMIT).get(),
      household.collection(LUNCH_ITEMS).limit(ITEM_LIMIT).get(),
      household
        .collection(LUNCH_PLANS)
        .where('weekStart', '>=', historyStart(options.monday))
        .where('weekStart', '<=', options.monday)
        .limit(PLAN_LIMIT)
        .get(),
      household.collection(LUNCH_FAVOURITES).limit(FAVOURITE_LIMIT).get(),
      options.withDinners ? household.collection(MEALS).limit(MEAL_LIMIT).get() : null,
      options.withDinners ? household.collection(MEAL_PLANS).doc(options.monday).get() : null,
      options.withPantry ? household.collection(LUNCH_PANTRY).limit(ITEM_LIMIT).get() : null,
      options.withPrices ? household.collection(LUNCH_PRICES).limit(ITEM_LIMIT).get() : null,
    ]);

  const nutFreeSchools = new Set(
    schools.docs
      .filter((school) => storedSchool.safeParse(school.data()).data?.nutFree === true)
      .map((school) => school.id),
  );

  const children: ChildFacts[] = [];
  const everybody: ChildFoodRules[] = [];
  for (const doc of profiles.docs) {
    const profile = storedProfile.safeParse(doc.data());
    if (!profile.success) continue;
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
    everybody.push(rules);
    if (profile.data.isChild) children.push({ memberId: doc.id, rules });
  }

  const library: LibraryItem[] = items.docs.flatMap((doc) => {
    const item = storedItem.safeParse(doc.data());
    if (!item.success || item.data.archived || !isLunchSlot(item.data.slot)) return [];
    return [
      { id: doc.id, name: item.data.name, slot: item.data.slot, allergens: item.data.allergens },
    ];
  });

  const mealSlots = storedMealPlan.safeParse(mealPlan?.data() ?? {});
  const dinners = new Map(
    Object.entries(mealSlots.success ? mealSlots.data.slots : {}).flatMap(([key, value]) => {
      const [day, slot] = key.split('_');
      return slot === 'dinner' && typeof value === 'string' && value !== ''
        ? [[Number(day), value] as const]
        : [];
    }),
  );

  return {
    children,
    library,
    plans: plans.docs.flatMap((doc) => planFrom(doc.data()) ?? []),
    favourites: favourites.docs.flatMap((doc) => favouriteFrom(doc.data()) ?? []),
    meals: (meals?.docs ?? []).flatMap((doc) => {
      const meal = storedMeal.safeParse(doc.data());
      return meal.success ? [{ id: doc.id, name: meal.data.name }] : [];
    }),
    dinners,
    pantry: new Map(
      (pantry?.docs ?? []).flatMap((doc) => {
        const entry = storedPantry.safeParse(doc.data());
        return entry.success && entry.data.portions > 0
          ? [[doc.id, entry.data.portions] as const]
          : [];
      }),
    ),
    prices: new Map(
      (prices?.docs ?? []).flatMap((doc) => {
        const price = storedPrice.safeParse(doc.data());
        return price.success
          ? [[doc.id, Math.round(price.data.cents / price.data.portions)] as const]
          : [];
      }),
    ),
    everybody,
  };
}
