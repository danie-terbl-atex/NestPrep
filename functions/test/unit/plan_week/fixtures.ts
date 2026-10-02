import {
  foodRulesFrom,
  type ChildFoodRules,
  type StoredFoodFacts,
} from '../../../src/plan_week/food_safety';
import type { FoundProduct } from '../../../src/plan_week/schemas';

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
