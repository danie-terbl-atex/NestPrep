import { exclusionFor, hasAnyAllergy } from './child_exclusion';
import { isAllergen, type ChildFoodRules } from './food_safety';
import { openCompartments } from './open_compartments';
import type { FoundIdea, FoundProduct } from './schemas';
import type { LunchPlanFacts, LunchSlot } from './week_documents';
import type { ChildFacts } from './week_reads';

/**
 * What the model may know when it builds the week from the store's products
 * (lunch-box ADR-0012): children as `child-N` with their open compartments,
 * the ideas as `idea-N`, each product as `p-N` with its name, price,
 * promotion and pack size, and which children it may go to. The phone
 * filtered the products already; this checks each one again against each
 * child's rules before the model sees it, and the mapping back to ids stays
 * here.
 */
export interface WeekBriefProduct {
  readonly ref: string;
  readonly ideaRef: string;
  readonly ideaId: string;
  readonly slot: LunchSlot;
  /** From a shelf of Checkers' lunchbox range (lunch-box ADR-0013). */
  readonly fromAisle: boolean;
  readonly product: FoundProduct;
  /** Children this product may go to — refs, after NestPrep's check. */
  readonly childRefs: readonly string[];
}

export interface WeekBriefChild {
  readonly ref: string;
  readonly memberId: string;
  readonly open: readonly string[];
}

export interface WeekBrief {
  readonly budgetCents: number | null;
  readonly children: readonly WeekBriefChild[];
  readonly products: readonly WeekBriefProduct[];
  /** Products the phone sent that no child may have after all. */
  readonly removed: number;
}

export function weekBriefFrom(
  ideas: readonly FoundIdea[],
  children: readonly ChildFacts[],
  plans: readonly LunchPlanFacts[],
  monday: string,
  budgetCents: number | null,
): WeekBrief {
  const briefChildren = children.map((child, index) => ({
    ref: `child-${String(index + 1)}`,
    memberId: child.memberId,
    rules: child.rules,
    open: openCompartments(
      plans.find((plan) => plan.childId === child.memberId && plan.weekStart === monday),
    ),
  }));
  const byMember = new Map(briefChildren.map((child) => [child.memberId, child]));

  const products: WeekBriefProduct[] = [];
  let removed = 0;
  ideas.forEach((idea, index) => {
    const forWhom = idea.childIds.flatMap((id) => byMember.get(id) ?? []);
    for (const product of idea.products) {
      const childRefs = forWhom
        .filter((child) => isProductAllowedFor(child.rules, product))
        .map((child) => child.ref);
      if (childRefs.length === 0) {
        removed += 1;
        continue;
      }
      products.push({
        ref: `p-${String(products.length + 1)}`,
        ideaRef: `idea-${String(index + 1)}`,
        ideaId: idea.id,
        slot: idea.slot,
        fromAisle: idea.fromAisle,
        product,
        childRefs,
      });
    }
  });

  return {
    budgetCents,
    children: briefChildren
      .filter((child) => child.open.length > 0)
      .map(({ ref, memberId, open }) => ({ ref, memberId, open })),
    products,
    removed,
  };
}

/**
 * Whether a product may go in this child's box: nothing it is known or named
 * to contain that they must avoid, no free-text allergy or dislike in its
 * name — and, for a child with any allergy, the store said what is in it.
 */
export function isProductAllowedFor(rules: ChildFoodRules, product: FoundProduct): boolean {
  if (!product.allergensKnown && hasAnyAllergy(rules)) return false;
  return exclusionFor(rules, product.name, product.allergens.filter(isAllergen)) === null;
}

/** The brief as the model reads it — placeholders, product names and prices only. */
export function weekBriefForModel(brief: WeekBrief): unknown {
  const ideaRefs = [...new Set(brief.products.map((product) => product.ideaRef))];
  return {
    budgetCents: brief.budgetCents,
    boxesToFill: brief.children.reduce((sum, child) => sum + child.open.length, 0),
    children: brief.children.map((child) => ({ ref: child.ref, open: child.open })),
    ideas: ideaRefs.map((ref) => {
      const own = brief.products.filter((product) => product.ideaRef === ref);
      return {
        ref,
        slot: own[0]?.slot,
        ...(own[0]?.fromAisle === true && { aisle: true }),
        products: own.map(({ ref: productRef, product, childRefs }) => ({
          ref: productRef,
          name: product.name,
          priceCents: product.priceCents,
          promo: product.isOnPromotion,
          packQuantity: product.packQuantity,
          children: childRefs,
        })),
      };
    }),
  };
}
