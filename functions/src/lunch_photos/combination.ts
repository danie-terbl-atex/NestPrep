import { hash } from 'node:crypto';

import {
  LUNCH_SLOTS,
  slotKey,
  type LunchPlanFacts,
  type LunchSlot,
  type StoredPick,
} from '../plan_week/week_documents';
import { SEED_FOODS, SEED_ITEM_PREFIX } from './seed_foods';

/**
 * What a lunch box's picture is of, and the key it is cached under
 * (lunch-box ADR-0015). Pure: no Firestore, no clock.
 *
 * A box made only of catalogue foods looks the same in every household, so
 * its picture is `shared` and made once for everybody; anything a family
 * added or typed makes it the household's own. Raising [PROMPT_VERSION]
 * changes every key, so a new prompt makes new pictures rather than reusing
 * the old ones.
 */
export const PROMPT_VERSION = 'v1';

/** A household's food name is cut to this before it reaches the model. */
export const MAX_FOOD_LENGTH = 60;

export type PhotoScope = 'shared' | 'household';

export interface BoxFood {
  readonly slot: LunchSlot;
  readonly food: string;
}

export interface LunchCombination {
  readonly scope: PhotoScope;
  readonly key: string;
  readonly foods: readonly BoxFood[];
}

export type LunchBox = Partial<Record<LunchSlot, StoredPick>>;

/** The picks in [plan] on ISO weekday [weekday], by slot. */
export function boxOn(plan: LunchPlanFacts, weekday: number): LunchBox {
  const box: LunchBox = {};
  for (const slot of LUNCH_SLOTS) {
    const pick = plan.slots[slotKey(weekday, slot)];
    if (pick !== undefined) box[slot] = pick;
  }
  return box;
}

/** The box's combination, or null when there is nothing in it to picture. */
export function combinationOf(box: LunchBox): LunchCombination | null {
  const picks = LUNCH_SLOTS.flatMap((slot) => {
    const pick = box[slot];
    return pick === undefined ? [] : [{ slot, pick }];
  });
  if (picks.length === 0) return null;

  const seeded = picks.map(({ slot, pick }) => {
    const key = seedKeyOf(pick.itemId);
    return key === null ? null : { slot, key };
  });
  if (seeded.every((entry) => entry !== null)) {
    return combinationFrom(
      'shared',
      seeded.map(({ slot, key }) => ({ slot, food: SEED_FOODS[key]?.name ?? key, identity: key })),
    );
  }

  const named = picks.flatMap(({ slot, pick }) => {
    const food = normalisedFood(pick.name);
    return food === '' ? [] : [{ slot, food, identity: food.toLowerCase() }];
  });
  return named.length === 0 ? null : combinationFrom('household', named);
}

/**
 * The words the image model is given: foods and the scene, never a child, a
 * name or an allergy (foundation ADR-0015's POPIA section).
 */
export function promptFor(foods: readonly BoxFood[]): string {
  return (
    'Ultra-realistic, appetising editorial food photograph of an open rose-pink bento ' +
    "lunchbox for a child's school day, seen from a three-quarter overhead angle. " +
    `Its compartments hold: ${foods.map(({ food }) => food).join('; ')}. ` +
    'Every food is clearly recognisable with real textures and natural imperfections, ' +
    'kid-sized believable portions, arranged in a bright, fun and inviting way. ' +
    'Warm sunlit kitchen table, soft natural window light, shallow depth of field, ' +
    'a small lilac linen napkin at the edge. Joyful food-magazine style. ' +
    'No people, no hands, no text, no labels, no logos.'
  );
}

/** A household's food name as the model sees it: one line, at most sixty characters. */
export function normalisedFood(name: string): string {
  return name.replace(/\s+/g, ' ').trim().slice(0, MAX_FOOD_LENGTH).trim();
}

function seedKeyOf(itemId: string): string | null {
  if (!itemId.startsWith(SEED_ITEM_PREFIX)) return null;
  const key = itemId.slice(SEED_ITEM_PREFIX.length);
  return Object.hasOwn(SEED_FOODS, key) ? key : null;
}

function combinationFrom(
  scope: PhotoScope,
  entries: readonly { slot: LunchSlot; food: string; identity: string }[],
): LunchCombination {
  const signature = [
    PROMPT_VERSION,
    scope,
    ...entries.map(({ slot, identity }) => `${slot}:${identity}`),
  ].join('|');
  return {
    scope,
    key: hash('sha256', signature).slice(0, 40),
    foods: entries.map(({ slot, food }) => ({ slot, food })),
  };
}
