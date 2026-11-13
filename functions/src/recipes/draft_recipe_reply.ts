import { z } from 'zod';

import { INGREDIENT_UNITS, type IngredientUnit } from '../plan_week/idea_recipe';
import { OWN_RECIPE_CONTEXTS, OWN_RECIPE_LIMITS } from './own_recipe';
import { COURSES } from './recipe';

const nullableText = z.string().nullish();
const course = z.enum(COURSES).nullish();

export const draftReply = z.object({
  isRecipe: z.boolean(),
  name: nullableText,
  summary: nullableText,
  placement: z.object({ breakfast: course, lunch: course, dinner: course }).nullish(),
  servings: z.number().nullish(),
  prepMinutes: z.number().nullish(),
  cookMinutes: z.number().nullish(),
  ingredients: z
    .array(
      z.object({
        name: z.string(),
        quantity: z.number().nullish(),
        unit: z.string().nullish(),
        note: nullableText,
        group: nullableText,
      }),
    )
    .nullish(),
  steps: z.array(z.string()).nullish(),
  notes: nullableText,
});
export type DraftReply = z.infer<typeof draftReply>;

type Context = (typeof OWN_RECIPE_CONTEXTS)[number];

export interface RecipeDraft {
  readonly name: string;
  readonly summary: string;
  readonly contexts: readonly Context[];
  readonly placement: Partial<Record<Context, (typeof COURSES)[number]>>;
  readonly ingredients: readonly {
    readonly name: string;
    readonly quantity: number | null;
    readonly unit: IngredientUnit | null;
    readonly note: string | null;
    readonly group: string | null;
  }[];
  readonly steps: readonly string[];
  readonly servings: number | null;
  readonly prepMinutes: number | null;
  readonly cookMinutes: number | null;
  readonly notes: string | null;
  readonly cutShort: boolean;
}

export function draftFrom(reply: DraftReply): RecipeDraft | null {
  if (!reply.isRecipe) return null;
  const name = clipped(reply.name, OWN_RECIPE_LIMITS.name);
  const ingredients = (reply.ingredients ?? []).flatMap((line) => {
    const lineName = clipped(line.name, OWN_RECIPE_LIMITS.ingredientName);
    if (lineName === null) return [];
    return [
      {
        name: lineName,
        ...amountOf(line.quantity, line.unit),
        note: clipped(line.note, OWN_RECIPE_LIMITS.ingredientNote),
        group: clipped(line.group, OWN_RECIPE_LIMITS.ingredientGroup),
      },
    ];
  });
  const steps = (reply.steps ?? []).flatMap((step) => clipped(step, OWN_RECIPE_LIMITS.step) ?? []);
  if (name === null || (ingredients.length === 0 && steps.length === 0)) return null;
  return {
    name,
    summary: clipped(reply.summary, OWN_RECIPE_LIMITS.summary) ?? '',
    ...mealsOf(reply),
    ingredients: ingredients.slice(0, OWN_RECIPE_LIMITS.ingredients),
    steps: steps.slice(0, OWN_RECIPE_LIMITS.steps),
    servings: wholeWithin(reply.servings, 1, OWN_RECIPE_LIMITS.servings),
    prepMinutes: wholeWithin(reply.prepMinutes, 0, OWN_RECIPE_LIMITS.minutes),
    cookMinutes: wholeWithin(reply.cookMinutes, 0, OWN_RECIPE_LIMITS.minutes),
    notes: clipped(reply.notes, OWN_RECIPE_LIMITS.notes),
    cutShort:
      ingredients.length > OWN_RECIPE_LIMITS.ingredients ||
      steps.length > OWN_RECIPE_LIMITS.steps ||
      (reply.steps ?? []).some((step) => Array.from(step.trim()).length > OWN_RECIPE_LIMITS.step),
  };
}

function clipped(value: string | null | undefined, max: number): string | null {
  const collapsed = value?.trim() ?? '';
  if (collapsed === '') return null;
  return Array.from(collapsed).slice(0, max).join('').trim();
}

/** A unit outside the vocabulary loses its amount too: "2" of a unit nobody can read misleads. */
function amountOf(
  quantity: number | null | undefined,
  unit: string | null | undefined,
): { quantity: number | null; unit: IngredientUnit | null } {
  const known = INGREDIENT_UNITS.find((candidate) => candidate === unit) ?? null;
  const usable =
    typeof quantity === 'number' && quantity > 0 && quantity <= OWN_RECIPE_LIMITS.quantity;
  if (!usable || (known === null && unit != null && unit !== '')) {
    return { quantity: null, unit: null };
  }
  return { quantity, unit: known };
}

function wholeWithin(value: number | null | undefined, min: number, max: number): number | null {
  if (value === null || value === undefined) return null;
  const whole = Math.round(value);
  return whole >= min && whole <= max ? whole : null;
}

function mealsOf(reply: DraftReply): Pick<RecipeDraft, 'contexts' | 'placement'> {
  const placement: Partial<Record<Context, (typeof COURSES)[number]>> = {};
  for (const context of OWN_RECIPE_CONTEXTS) {
    const chosen = reply.placement?.[context];
    if (chosen !== null && chosen !== undefined) placement[context] = chosen;
  }
  const contexts = OWN_RECIPE_CONTEXTS.filter((context) => context in placement);
  return contexts.length > 0
    ? { contexts, placement }
    : { contexts: ['dinner'], placement: { dinner: 'main' } };
}
