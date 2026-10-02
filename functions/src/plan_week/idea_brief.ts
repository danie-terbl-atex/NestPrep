import { exclusionFor } from './child_exclusion';
import type { ChildFoodRules } from './food_safety';
import { openCompartments } from './open_compartments';
import type { AisleShelf } from './schemas';
import { tasteFrom } from './taste';
import { LUNCH_SLOTS, isLunchSlot, type LunchPlanFacts, type LunchSlot } from './week_documents';
import type { ChildFacts } from './week_reads';

/**
 * What the model may know when it drafts the week's lunch ideas (lunch-box
 * ADR-0012). Every child is `child-1`, `child-2`…; the model gets how many
 * compartments of each kind are empty, what the child likes and dislikes in
 * their family's words, and the names of what came home eaten or left. It
 * never gets a name, an age, a school, an allergy, a diet or anything
 * medical: those strike ideas out afterwards, here, and are not sent.
 */
export interface IdeaBriefChild {
  readonly ref: string;
  readonly memberId: string;
  readonly rules: ChildFoodRules;
  readonly open: Readonly<Record<LunchSlot, number>>;
  readonly ateWell: readonly string[];
  readonly oftenLeft: readonly string[];
}

/**
 * A shelf of Checkers' Kids Lunchbox range the phone read (lunch-box
 * ADR-0013), kept to the product names some child with that compartment open
 * may have — store words only, which the model is told not to repeat.
 */
export interface IdeaBriefShelf {
  readonly slot: LunchSlot;
  readonly title: string;
  readonly products: readonly string[];
}

export interface IdeaBrief {
  readonly budgetCents: number | null;
  readonly children: readonly IdeaBriefChild[];
  readonly aisle: readonly IdeaBriefShelf[];
}

/** Enough history to steer by, and a bounded prompt. */
export const MAX_REMEMBERED_FOODS = 12;

export function ideaBriefFrom(
  children: readonly ChildFacts[],
  plans: readonly LunchPlanFacts[],
  monday: string,
  budgetCents: number | null,
  aisle: readonly AisleShelf[] = [],
): IdeaBrief {
  const briefChildren = children.map((child, index): IdeaBriefChild => {
    const history = plans.filter((plan) => plan.childId === child.memberId);
    const thisWeek = history.find((plan) => plan.weekStart === monday);
    const open: Record<LunchSlot, number> = { main: 0, fruit: 0, veg: 0, snack: 0, treat: 0 };
    for (const key of openCompartments(thisWeek)) {
      const slot = key.slice(key.indexOf('_') + 1);
      if (isLunchSlot(slot)) open[slot] += 1;
    }
    const { ateWell, oftenLeft } = rememberedFoods(history, monday);
    return {
      ref: `child-${String(index + 1)}`,
      memberId: child.memberId,
      rules: child.rules,
      open,
      ateWell,
      oftenLeft,
    };
  });
  return { budgetCents, children: briefChildren, aisle: shelvesFor(aisle, briefChildren) };
}

/**
 * Each shelf kept to the names some child with its compartment open may
 * have; a shelf nobody can use is dropped, so the model is never steered by
 * a product the phone should not have sent.
 */
function shelvesFor(
  aisle: readonly AisleShelf[],
  children: readonly IdeaBriefChild[],
): IdeaBriefShelf[] {
  return aisle.flatMap((shelf) => {
    const withRoom = children.filter((child) => child.open[shelf.slot] > 0);
    const products = shelf.products.filter((name) =>
      withRoom.some((child) => exclusionFor(child.rules, name) === null),
    );
    return products.length === 0 ? [] : [{ slot: shelf.slot, title: shelf.title, products }];
  });
}

export function hasOpenCompartments(brief: IdeaBrief): boolean {
  return brief.children.some((child) => LUNCH_SLOTS.some((slot) => child.open[slot] > 0));
}

/** The brief as the model reads it — placeholders and food words only. */
export function ideaBriefForModel(brief: IdeaBrief): unknown {
  return {
    budgetCents: brief.budgetCents,
    children: brief.children.map((child) => ({
      ref: child.ref,
      open: child.open,
      likes: child.rules.likes,
      dislikes: child.rules.dislikes,
      ateWell: child.ateWell,
      oftenLeft: child.oftenLeft,
    })),
    ...(brief.aisle.length > 0 && {
      aisle: brief.aisle.map(({ slot, title, products }) => ({ slot, title, products })),
    }),
  };
}

function rememberedFoods(
  history: readonly LunchPlanFacts[],
  monday: string,
): { ateWell: string[]; oftenLeft: string[] } {
  const scores = tasteFrom(history, monday);
  const names = new Map(
    history.flatMap((plan) => Object.values(plan.slots).map((pick) => [pick.itemId, pick.name])),
  );
  const ranked = [...scores.entries()]
    .flatMap(([itemId, score]) => {
      const name = names.get(itemId);
      return name === undefined || score === 0 ? [] : [{ name, score }];
    })
    .sort((a, b) => Math.abs(b.score) - Math.abs(a.score) || a.name.localeCompare(b.name));
  return {
    ateWell: ranked
      .filter((food) => food.score > 0)
      .slice(0, MAX_REMEMBERED_FOODS)
      .map((f) => f.name),
    oftenLeft: ranked
      .filter((food) => food.score < 0)
      .slice(0, MAX_REMEMBERED_FOODS)
      .map((f) => f.name),
  };
}
