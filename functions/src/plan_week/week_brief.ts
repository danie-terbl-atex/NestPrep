import { inWeekItems, type InWeekItem } from './basket';
import { isProductAllowedFor } from './child_exclusion';
import { openCompartments, type SchoolWeek } from './open_compartments';
import {
  DEFAULT_SAME_ALL_WEEK,
  NO_PACKING_CHOICES,
  type PackingChoices,
  type PackingPreference,
} from './packing_preferences';
import type { FoundIdea, FoundProduct } from './schemas';
import { dishEntryFor, type WeekBriefPart } from './week_dishes';
import type { LunchPlanFacts, LunchSlot, StoredPrice } from './week_documents';
import type { ChildFacts } from './week_reads';

export { isProductAllowedFor } from './child_exclusion';

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
  /**
   * Present when this entry is a dish (lunch-box ADR-0021): [product] is then
   * the dish itself (`dish:<ideaId>`, no price of its own) and these are the
   * ingredient products it is bought as — one per ingredient the store had.
   */
  readonly parts?: readonly WeekBriefPart[];
  /** A dish's every ingredient name, bought or not — what Jev reads it as. */
  readonly madeWith?: readonly string[];
}

export interface WeekBriefChild {
  readonly ref: string;
  readonly memberId: string;
  readonly open: readonly string[];
}

/** The week being planned, as the household holds it now. */
export interface PlannedWeek extends SchoolWeek {
  /** This week's plans and the weeks before; only this week's are read here. */
  readonly plans: readonly LunchPlanFacts[];
  readonly budgetCents: number | null;
  /** Item id → price, for what is already packed this week. */
  readonly prices: Readonly<Record<string, StoredPrice>>;
}

export interface WeekBrief {
  readonly budgetCents: number | null;
  /** What every child's week already holds — the basket starts there (ADR-0012 §4). */
  readonly alreadyInWeek: readonly InWeekItem[];
  readonly children: readonly WeekBriefChild[];
  readonly products: readonly WeekBriefProduct[];
  /** Products the phone sent that no child may have after all. */
  readonly removed: number;
  readonly preferences: readonly PackingPreference[];
  /** Compartments that keep one product all week (lunch-box ADR-0028). */
  readonly sameAllWeek: readonly LunchSlot[];
}

export function weekBriefFrom(
  ideas: readonly FoundIdea[],
  children: readonly ChildFacts[],
  week: PlannedWeek,
  choices: PackingChoices = NO_PACKING_CHOICES,
): WeekBrief {
  const briefChildren = children.map((child, index) => ({
    ref: `child-${String(index + 1)}`,
    memberId: child.memberId,
    rules: child.rules,
    open: openCompartments(
      week.plans.find((plan) => plan.childId === child.memberId && plan.weekStart === week.monday),
      week,
      choices.slots,
      choices.treatDays,
    ),
  }));
  const byMember = new Map(briefChildren.map((child) => [child.memberId, child]));

  const products: WeekBriefProduct[] = [];
  let removed = 0;
  ideas.forEach((idea, index) => {
    if (!choices.slots.includes(idea.slot)) return;
    const forWhom = idea.childIds.flatMap((id) => byMember.get(id) ?? []);
    if (idea.dish !== undefined && idea.slot === 'main') {
      const entry = dishEntryFor(idea, idea.dish, forWhom, {
        ref: `p-${String(products.length + 1)}`,
        ideaRef: `idea-${String(index + 1)}`,
        partsSoFar: products.reduce((sum, product) => sum + (product.parts?.length ?? 0), 0),
      });
      if (entry === null) removed += 1;
      else products.push(entry);
      return;
    }
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
    budgetCents: week.budgetCents,
    alreadyInWeek: inWeekItems(week.plans, week.monday, week.prices),
    children: briefChildren
      .filter((child) => child.open.length > 0)
      .map(({ ref, memberId, open }) => ({ ref, memberId, open })),
    products,
    removed,
    preferences: choices.preferences,
    sameAllWeek: choices.sameAllWeek ?? DEFAULT_SAME_ALL_WEEK,
  };
}
