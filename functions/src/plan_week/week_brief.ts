import { exclusionFor, hasAnyAllergy } from './child_exclusion';
import { isAllergen, type ChildFoodRules } from './food_safety';
import { openCompartments } from './open_compartments';
import {
  NO_PACKING_CHOICES,
  type PackingChoices,
  type PackingPreference,
} from './packing_preferences';
import type { FoundIdea, FoundProduct } from './schemas';
import type { LunchPlanFacts, LunchSlot } from './week_documents';
import type { ChildFacts } from './week_reads';

/**
 * The week's products as NestPrep holds them before Jev scores them
 * (lunch-box ADR-0012, foundation ADR-0021): children as `child-N` with their
 * open compartments, each product as `p-N` with the children it may go to.
 * The phone filtered the products already; this checks each one again
 * against each child's rules, and the mapping back to ids stays here.
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
  readonly preferences: readonly PackingPreference[];
}

export function weekBriefFrom(
  ideas: readonly FoundIdea[],
  children: readonly ChildFacts[],
  plans: readonly LunchPlanFacts[],
  monday: string,
  budgetCents: number | null,
  choices: PackingChoices = NO_PACKING_CHOICES,
): WeekBrief {
  const briefChildren = children.map((child, index) => ({
    ref: `child-${String(index + 1)}`,
    memberId: child.memberId,
    rules: child.rules,
    open: openCompartments(
      plans.find((plan) => plan.childId === child.memberId && plan.weekStart === monday),
      choices.slots,
    ),
  }));
  const byMember = new Map(briefChildren.map((child) => [child.memberId, child]));

  const products: WeekBriefProduct[] = [];
  let removed = 0;
  ideas.forEach((idea, index) => {
    if (!choices.slots.includes(idea.slot)) return;
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
    preferences: choices.preferences,
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
