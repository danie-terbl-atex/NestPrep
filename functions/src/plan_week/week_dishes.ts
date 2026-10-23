import { exclusionFor, isProductAllowedFor } from './child_exclusion';
import type { ChildFoodRules } from './food_safety';
import { recipeWords } from './idea_recipe';
import type { FoundDish, FoundIdea, FoundProduct } from './schemas';
import type { WeekBriefProduct } from './week_brief';

/**
 * A dish in the week (lunch-box ADR-0021 §4, ADR-0023): placed like a
 * product, bought as its ingredients. Each ingredient is bought as **the
 * first product the phone kept for it, in the store's order, that every
 * child the dish goes to may have** — no model choice. A dish goes to a
 * child only while every ingredient still has such a product for all the
 * dish's children so far, taken in order; **it is never planned with an
 * ingredient missing**, so one the shop had nothing for means no dish.
 */

/** One ingredient product a dish is bought as, `i-N` to Jev. */
export interface WeekBriefPart {
  readonly ref: string;
  readonly ingredient: string;
  readonly product: FoundProduct;
}

/** The product id a dish stands under in the week — never a store's id. */
export function dishProductId(ideaId: string): string {
  return `dish:${ideaId}`;
}

interface DishChild {
  readonly ref: string;
  readonly rules: ChildFoodRules;
}

interface DishRefs {
  readonly ref: string;
  readonly ideaRef: string;
  /** How many parts earlier dishes took, so part refs stay unique. */
  readonly partsSoFar: number;
}

/**
 * [dish] as an entry of the week, for the children whose rules its every
 * word passes — or null when no child may have it.
 */
export function dishEntryFor(
  idea: FoundIdea,
  dish: FoundDish,
  forWhom: readonly DishChild[],
  refs: DishRefs,
): WeekBriefProduct | null {
  const words = recipeWords(dish);
  const children: DishChild[] = [];
  for (const child of forWhom) {
    if (exclusionFor(child.rules, words) !== null) continue;
    if (productsFor([...children, child], dish) !== null) children.push(child);
  }
  const products = productsFor(children, dish);
  if (children.length === 0 || products === null) return null;
  const parts: WeekBriefPart[] = products.map((product, index) => ({
    ref: `i-${String(refs.partsSoFar + index + 1)}`,
    ingredient: dish.ingredients[index]?.name ?? '',
    product,
  }));
  return {
    ref: refs.ref,
    ideaRef: refs.ideaRef,
    ideaId: idea.id,
    slot: idea.slot,
    fromAisle: false,
    product: {
      productId: dishProductId(idea.id),
      name: dish.name,
      brand: null,
      priceCents: 0,
      isOnPromotion: false,
      allergens: [],
      allergensKnown: true,
      packQuantity: 1,
    },
    childRefs: children.map((child) => child.ref),
    parts,
    madeWith: dish.ingredients.map((ingredient) => ingredient.name),
  };
}

/** One product per ingredient that all of [children] may have, or null when an ingredient has none. */
function productsFor(children: readonly DishChild[], dish: FoundDish): FoundProduct[] | null {
  const chosen: FoundProduct[] = [];
  for (const ingredient of dish.ingredients) {
    const product = ingredient.products.find((candidate) =>
      children.every((child) => isProductAllowedFor(child.rules, candidate)),
    );
    if (product === undefined) return null;
    chosen.push(product);
  }
  return chosen;
}
