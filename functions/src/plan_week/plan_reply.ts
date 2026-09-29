import { z } from 'zod';

import { isDinnerIdeaSafe, type DinnerIdea } from './dinner_safety';
import { isSuggestableFor, type ChildFoodRules } from './food_safety';
import type { PlanBrief } from './plan_brief';
import { isLunchSlot, slotKey, type LunchSlot } from './week_documents';

/**
 * The model's answer: two lists, each entry checked on its own so one odd
 * entry costs that entry, not the week (ENG-09). Bounded here because Vertex
 * will not take `maxItems` in a response schema.
 */
export const MAX_REPLY_LUNCHES = 5 * 5 * 12;
export const MAX_REPLY_DINNERS = 14;

export const planReply = z.object({
  lunches: z.array(z.unknown()).transform((list) => list.slice(0, MAX_REPLY_LUNCHES)),
  dinners: z.array(z.unknown()).transform((list) => list.slice(0, MAX_REPLY_DINNERS)),
});
export type PlanReply = z.infer<typeof planReply>;

const replyLunch = z.object({
  child: z.string(),
  day: z.number().int().min(1).max(5),
  slot: z.string(),
  item: z.string(),
});

const ingredientLine = z.object({
  name: z.string().trim().min(1).max(40),
  quantity: z.string().trim().max(20).nullable().optional(),
});

const replyDinner = z.object({
  day: z.number().int().min(1).max(7),
  meal: z.string().nullable().optional(),
  newMeal: z
    .object({
      name: z.string().trim().min(1).max(60),
      ingredients: z.array(z.unknown()).transform((list) => list.slice(0, MAX_INGREDIENTS)),
    })
    .nullable()
    .optional(),
});

export const MAX_INGREDIENTS = 20;
/** The model is asked for two; three is where it has stopped listening. */
export const MAX_NEW_DINNERS = 3;

export interface ProposedLunch {
  readonly childId: string;
  readonly day: number;
  readonly slot: LunchSlot;
  readonly itemId: string;
}

export interface ProposedDinner {
  readonly day: number;
  readonly mealId: string | null;
  readonly newMeal: DinnerIdea | null;
}

export interface WeekProposal {
  readonly lunches: readonly ProposedLunch[];
  readonly dinners: readonly ProposedDinner[];
  /** Entries the model gave that were not allowed, and were left out. */
  readonly dropped: number;
}

/**
 * The reply, checked against the brief and the household's rules **after**
 * the model (lunch-box ADR-0011): a child, item or meal it did not know is
 * dropped; a compartment or dinner that was not open, or is already taken in
 * this reply, is dropped; an item not safe and suggestable for that child is
 * dropped — whatever the brief offered, the rules are asked again — and a new
 * dinner idea that names something anybody in the household must avoid is
 * dropped. What is left is a proposal: nothing is written.
 */
export function proposalFrom(
  reply: PlanReply,
  brief: PlanBrief,
  rulesOf: ReadonlyMap<string, ChildFoodRules>,
  everybody: readonly ChildFoodRules[],
): WeekProposal {
  let dropped = 0;
  const lunches: ProposedLunch[] = [];
  const taken = new Set<string>();
  const children = new Map(brief.children.map((child) => [child.ref, child]));

  for (const entry of reply.lunches) {
    const lunch = replyLunch.safeParse(entry);
    const child = lunch.success ? children.get(lunch.data.child) : undefined;
    const item = lunch.success ? brief.itemIds.get(lunch.data.item) : undefined;
    const rules = child === undefined ? undefined : rulesOf.get(child.memberId);
    if (!lunch.success || child === undefined || item === undefined || rules === undefined) {
      dropped += 1;
      continue;
    }
    const { day, slot } = lunch.data;
    const key = `${child.memberId}/${slotKey(day, slot)}`;
    const isAllowed =
      isLunchSlot(slot) &&
      item.slot === slot &&
      child.open.includes(slotKey(day, slot)) &&
      !taken.has(key) &&
      isSuggestableFor(rules, item.name, item.allergens);
    if (!isAllowed) {
      dropped += 1;
      continue;
    }
    taken.add(key);
    lunches.push({ childId: child.memberId, day, slot: item.slot, itemId: item.id });
  }

  const dinners: ProposedDinner[] = [];
  const dinnerDays = new Set(brief.dinnerDays);
  const plannedDays = new Set<number>();
  const usedMeals = new Set<string>();
  let newIdeas = 0;
  for (const entry of reply.dinners) {
    const dinner = replyDinner.safeParse(entry);
    if (!dinner.success || !dinnerDays.has(dinner.data.day) || plannedDays.has(dinner.data.day)) {
      dropped += 1;
      continue;
    }
    const mealId = dinner.data.meal == null ? undefined : brief.mealIds.get(dinner.data.meal);
    const idea = dinner.data.newMeal == null ? null : ideaFrom(dinner.data.newMeal);
    if (mealId !== undefined && !usedMeals.has(mealId)) {
      usedMeals.add(mealId);
      plannedDays.add(dinner.data.day);
      dinners.push({ day: dinner.data.day, mealId, newMeal: null });
    } else if (
      mealId === undefined &&
      idea !== null &&
      newIdeas < MAX_NEW_DINNERS &&
      isDinnerIdeaSafe(idea, everybody)
    ) {
      newIdeas += 1;
      plannedDays.add(dinner.data.day);
      dinners.push({ day: dinner.data.day, mealId: null, newMeal: idea });
    } else {
      dropped += 1;
    }
  }

  return {
    lunches: lunches.sort(
      (a, b) => a.childId.localeCompare(b.childId) || a.day - b.day || a.slot.localeCompare(b.slot),
    ),
    dinners: dinners.sort((a, b) => a.day - b.day),
    dropped,
  };
}

function ideaFrom(raw: { name: string; ingredients: unknown[] }): DinnerIdea | null {
  const seen = new Set<string>();
  const ingredients = raw.ingredients.flatMap((entry) => {
    const line = ingredientLine.safeParse(entry);
    if (!line.success) return [];
    const key = line.data.name.toLowerCase();
    if (seen.has(key)) return [];
    seen.add(key);
    const quantity = line.data.quantity ?? null;
    return [{ name: line.data.name, quantity: quantity === '' ? null : quantity }];
  });
  return ingredients.length === 0 ? null : { name: raw.name, ingredients };
}
