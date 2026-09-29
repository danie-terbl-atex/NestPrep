import { SCHOOL_DAYS, WEEK_DAYS } from './iso_week';
import { isLikedBy, isSuggestableFor } from './food_safety';
import { tasteFrom, tasteWord, type TasteWord } from './taste';
import { LUNCH_SLOTS, slotKey, type LibraryItem, type LunchSlot } from './week_documents';
import type { ChildFacts, WeekFacts } from './week_reads';

/**
 * What the model may know about the week, built from the household's facts —
 * and the key back from what it says to real ids (lunch-box ADR-0011).
 *
 * **Data minimisation.** Every child is `child-1`, `child-2`…; every item is
 * `main-3`, `fruit-1`…; every meal `meal-4`. The model sees item and meal
 * *names*, which slot each goes in, a one-word taste, and — only when asked —
 * how many boxes' worth the pantry holds and what a box costs. It never sees
 * a child's name, age, school, allergy, diet, dislike or anything medical:
 * those decide which items are offered at all, here, and are not sent. The
 * mapping from a placeholder to a member or document id never leaves the
 * Function.
 */
export interface BriefItem {
  readonly ref: string;
  readonly name: string;
  readonly taste: TasteWord;
  /** Boxes' worth in the house, when planning from it. */
  readonly inPantry?: number;
  /** Cents a box, when planning to a budget and the household priced it. */
  readonly centsPerBox?: number;
}

export interface BriefChild {
  readonly ref: string;
  readonly memberId: string;
  /** The empty compartments to fill, as `{day}_{slot}`. */
  readonly open: readonly string[];
  /** Slot → the items safe and not disliked for this child, best first. */
  readonly candidates: Readonly<Record<LunchSlot, readonly BriefItem[]>>;
  /** Go-to boxes, every item in them safe for this child, as item refs. */
  readonly goToBoxes: readonly (readonly string[])[];
  /** What their week holds already, as item refs — for variety. */
  readonly alreadyPacked: readonly string[];
}

export interface PlanBrief {
  readonly children: readonly BriefChild[];
  /** Weekdays whose dinner is still empty; none when dinners are not planned. */
  readonly dinnerDays: readonly number[];
  readonly meals: readonly { readonly ref: string; readonly name: string }[];
  /** Meal refs already on this week's dinners. */
  readonly dinnersPlanned: readonly string[];
  readonly usePantry: boolean;
  readonly thrifty: boolean;
  /** Placeholder → real id, kept on the server. */
  readonly itemIds: ReadonlyMap<string, LibraryItem>;
  readonly mealIds: ReadonlyMap<string, string>;
}

/** Enough choice per compartment for a varied week, and a bounded prompt. */
export const MAX_CANDIDATES_PER_SLOT = 24;

export interface BriefOptions {
  readonly monday: string;
  readonly week: string;
  readonly children: readonly ChildFacts[];
  readonly withDinners: boolean;
  readonly usePantry: boolean;
  readonly thrifty: boolean;
}

export function briefFrom(facts: WeekFacts, options: BriefOptions): PlanBrief {
  const sorted = [...facts.library].sort(
    (a, b) =>
      LUNCH_SLOTS.indexOf(a.slot) - LUNCH_SLOTS.indexOf(b.slot) ||
      a.name.localeCompare(b.name) ||
      a.id.localeCompare(b.id),
  );
  const perSlot: Partial<Record<LunchSlot, number>> = {};
  const numbered = sorted.map((item) => {
    const next = (perSlot[item.slot] ?? 0) + 1;
    perSlot[item.slot] = next;
    return { ref: `${item.slot}-${String(next)}`, item };
  });
  const refOf = new Map(numbered.map(({ ref, item }) => [item.id, ref]));
  const itemIds = new Map(numbered.map(({ ref, item }) => [ref, item]));

  const children = options.children.map((child, index) =>
    briefChild(child, index, facts, options, sorted, refOf),
  );

  const numberedMeals = [...facts.meals]
    .sort((a, b) => a.name.localeCompare(b.name) || a.id.localeCompare(b.id))
    .map((meal, index) => ({ ref: `meal-${String(index + 1)}`, meal }));
  const meals = numberedMeals.map(({ ref, meal }) => ({ ref, name: meal.name }));
  const mealIds = new Map(numberedMeals.map(({ ref, meal }) => [ref, meal.id]));
  const mealRefOf = new Map(numberedMeals.map(({ ref, meal }) => [meal.id, ref]));

  return {
    children,
    dinnerDays: options.withDinners ? WEEK_DAYS.filter((day) => !facts.dinners.has(day)) : [],
    meals: options.withDinners ? meals : [],
    dinnersPlanned: [...facts.dinners.values()].flatMap((id) => mealRefOf.get(id) ?? []),
    usePantry: options.usePantry,
    thrifty: options.thrifty,
    itemIds,
    mealIds,
  };
}

function briefChild(
  child: ChildFacts,
  index: number,
  facts: WeekFacts,
  options: BriefOptions,
  library: readonly LibraryItem[],
  refOf: ReadonlyMap<string, string>,
): BriefChild {
  const thisWeek = facts.plans.find(
    (plan) => plan.childId === child.memberId && plan.weekStart === options.monday,
  );
  const history = facts.plans.filter((plan) => plan.childId === child.memberId);
  const taste = tasteFrom(history, options.monday);
  const suggestable = new Set(
    library
      .filter((item) => isSuggestableFor(child.rules, item.name, item.allergens))
      .map((item) => item.id),
  );

  const candidates = {} as Record<LunchSlot, BriefItem[]>;
  for (const slot of LUNCH_SLOTS) {
    candidates[slot] = library
      .filter((item) => item.slot === slot && suggestable.has(item.id))
      .map((item) => {
        const liked = isLikedBy(child.rules, item.name);
        const score = (taste.get(item.id) ?? 0) + (liked ? 2 : 0);
        return { item, liked, score };
      })
      .sort((a, b) => b.score - a.score || a.item.name.localeCompare(b.item.name))
      .slice(0, MAX_CANDIDATES_PER_SLOT)
      .map(({ item, liked }) => briefItem(item, liked, taste, facts, options, refOf));
  }

  const open: string[] = [];
  for (const day of SCHOOL_DAYS) {
    for (const slot of LUNCH_SLOTS) {
      if (slot === 'treat' && day !== 5) continue;
      if (thisWeek?.slots[slotKey(day, slot)] !== undefined) continue;
      open.push(slotKey(day, slot));
    }
  }

  return {
    ref: `child-${String(index + 1)}`,
    memberId: child.memberId,
    open,
    candidates,
    goToBoxes: facts.favourites
      .filter((favourite) => favourite.childId === child.memberId)
      .map((favourite) => Object.values(favourite.items))
      .filter((ids) => ids.length > 0 && ids.every((id) => suggestable.has(id)))
      .map((ids) => ids.flatMap((id) => refOf.get(id) ?? [])),
    alreadyPacked: Object.values(thisWeek?.slots ?? {}).flatMap(
      (pick) => refOf.get(pick.itemId) ?? [],
    ),
  };
}

function briefItem(
  item: LibraryItem,
  liked: boolean,
  taste: ReadonlyMap<string, number>,
  facts: WeekFacts,
  options: BriefOptions,
  refOf: ReadonlyMap<string, string>,
): BriefItem {
  const pantry = options.usePantry ? facts.pantry.get(item.id) : undefined;
  const cents = options.thrifty ? facts.prices.get(item.id) : undefined;
  return {
    ref: refOf.get(item.id) ?? item.id,
    name: item.name,
    taste: tasteWord(taste.get(item.id), liked),
    ...(pantry === undefined ? {} : { inPantry: pantry }),
    ...(cents === undefined ? {} : { centsPerBox: cents }),
  };
}
