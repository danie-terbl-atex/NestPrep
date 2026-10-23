import type { SeedFood } from '../lunch_photos/seed_foods';
import type { Allergen } from '../plan_week/food_safety';
import { LUNCH_SLOTS, type LunchSlot } from '../plan_week/week_documents';
import type { Recipe } from '../recipes/recipe';
import { catalogueAllergens } from '../recipes/recipe_document';
import type { StarterBoxSource, StarterPickSource } from './starter_box';

/** One compartment of a published box, carrying its source's name and codes. */
export type StarterPick =
  | {
      readonly kind: 'recipe';
      readonly recipeId: string;
      readonly name: string;
      readonly allergens: readonly Allergen[];
    }
  | {
      readonly kind: 'quickPick';
      readonly seedKey: string;
      readonly name: string;
      readonly allergens: readonly Allergen[];
    };

export type StarterBoxDocument = Readonly<{
  name: string;
  blurb: string;
  order: number;
  picks: Readonly<Partial<Record<LunchSlot, StarterPick>>>;
}>;

/** Where a box's references are resolved from. */
export interface StarterBoxSources {
  readonly recipes: ReadonlyMap<string, Recipe>;
  readonly seedFoods: Readonly<Record<string, SeedFood>>;
}

/**
 * What `lunchStarterBoxes/{id}` holds for [box], before the publisher adds
 * `status`, `version` and `updatedAt` (lunch-box ADR-0018): each pick's name
 * and allergen codes copied from the recipe or starter food it names. A
 * reference to nothing, or to something placed in another compartment, throws
 * — a box that cannot be resolved is never published.
 */
export function starterBoxDocument(
  box: StarterBoxSource,
  sources: StarterBoxSources,
): StarterBoxDocument {
  const picks: Partial<Record<LunchSlot, StarterPick>> = {};
  for (const slot of LUNCH_SLOTS) {
    const source = box.picks[slot];
    if (source !== undefined) picks[slot] = resolvedPick(box.id, slot, source, sources);
  }
  return { name: box.name, blurb: box.blurb, order: box.order, picks };
}

function resolvedPick(
  boxId: string,
  slot: LunchSlot,
  source: StarterPickSource,
  { recipes, seedFoods }: StarterBoxSources,
): StarterPick {
  if (source.kind === 'recipe') {
    const recipe = recipes.get(source.recipeId);
    if (recipe === undefined) throw new Error(`${boxId}.${slot}: no recipe ${source.recipeId}`);
    if (recipe.placement.lunchBox !== slot) {
      throw new Error(`${boxId}.${slot}: ${source.recipeId} is not placed in ${slot}`);
    }
    return { ...source, name: recipe.name, allergens: catalogueAllergens(recipe.allergens) };
  }
  const food = Object.hasOwn(seedFoods, source.seedKey) ? seedFoods[source.seedKey] : undefined;
  if (food === undefined) throw new Error(`${boxId}.${slot}: no starter food ${source.seedKey}`);
  if (food.slot !== slot) throw new Error(`${boxId}.${slot}: ${source.seedKey} is a ${food.slot}`);
  return { ...source, name: food.name, allergens: food.allergens };
}
