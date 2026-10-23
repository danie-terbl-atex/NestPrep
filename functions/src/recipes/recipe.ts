import { z } from 'zod';

import { ALLERGENS } from '../plan_week/food_safety';
import { INGREDIENT_UNITS } from '../plan_week/idea_recipe';
import { LUNCH_SLOTS } from '../plan_week/week_documents';
import { recipePhotoSource } from './recipe_photo';

/**
 * A recipe as NestPrep publishes it (recipes ADR-0001, ADR-0003): one entry,
 * offered in every context it names, with the allergen codes family profiles
 * own. The shape is parsed when the catalogue loads, so a malformed recipe
 * stops the seed rather than reaching a household (ENG-09).
 */

export const RECIPES = 'recipes';

/** The packed lunch box, and the meal plan's three meals (recipes ADR-0003 §1). */
export const RECIPE_CONTEXTS = ['lunchBox', 'breakfast', 'lunch', 'dinner'] as const;
export type RecipeContext = (typeof RECIPE_CONTEXTS)[number];

/** Where a recipe sits in a meal context; the lunch box places by compartment instead. */
export const COURSES = ['main', 'side', 'dessert', 'snack'] as const;

/** A fixed vocabulary, so the app filters by chips and never by free text. */
export const RECIPE_TAGS = [
  'braai',
  'potjie',
  'onePot',
  'quick',
  'budget',
  'kidFriendly',
  'comfort',
  'festive',
  'baking',
  'traditional',
  'capeMalay',
  'streetFood',
  'vegetableForward',
] as const;
export const CUISINES = ['southAfrican', 'international'] as const;
export const DIFFICULTIES = ['easy', 'medium', 'involved'] as const;

/** A `quick` recipe is on the table in this many minutes, prep and cooking together. */
export const QUICK_MINUTES = 30;

const text = (max: number): z.ZodString => z.string().trim().min(1).max(max);
const slug = z
  .string()
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/)
  .max(60);

/** A unit from the meal plan's vocabulary, so a line becomes a meal's line unchanged (§3). */
const ingredient = z
  .object({
    name: text(60),
    quantity: z.number().positive().max(10_000).nullable(),
    unit: z.enum(INGREDIENT_UNITS).nullable(),
    note: text(80).nullable(),
    group: text(40).nullable(),
  })
  .strict();
export type RecipeIngredient = z.infer<typeof ingredient>;

const course = z.enum(COURSES);
const placement = z
  .object({ lunchBox: z.enum(LUNCH_SLOTS), breakfast: course, lunch: course, dinner: course })
  .partial()
  .strict();

const distinct = (values: readonly string[]): boolean => new Set(values).size === values.length;

export const recipeSource = z
  .object({
    id: slug,
    name: text(60),
    summary: text(200),
    about: text(400).nullable(),
    cuisine: z.enum(CUISINES),
    contexts: z.array(z.enum(RECIPE_CONTEXTS)).min(1),
    placement,
    tags: z.array(z.enum(RECIPE_TAGS)).max(4),
    allergens: z.array(z.enum(ALLERGENS)),
    dietTags: z.array(z.enum(['vegetarian', 'vegan'])),
    ingredients: z.array(ingredient).min(1).max(30),
    steps: z.array(text(400)).min(1).max(20),
    servings: z.number().int().min(1).max(24),
    prepMinutes: z.number().int().min(1).max(240),
    cookMinutes: z.number().int().min(0).max(720),
    difficulty: z.enum(DIFFICULTIES),
    prepAhead: z.boolean(),
    prepNote: text(140).nullable(),
    photo: recipePhotoSource.nullable(),
  })
  .strict()
  .refine(
    (recipe) =>
      distinct(recipe.contexts) &&
      Object.keys(recipe.placement).sort().join() === [...recipe.contexts].sort().join(),
    { message: 'placement must name exactly the recipe’s contexts', path: ['placement'] },
  )
  .refine((recipe) => distinct(recipe.allergens), {
    message: 'an allergen code is listed twice',
    path: ['allergens'],
  })
  .refine((recipe) => distinct(recipe.tags), { message: 'a tag is listed twice', path: ['tags'] })
  .refine((recipe) => new Set(recipe.ingredients.map(({ group }) => group === null)).size === 1, {
    message: 'a group is set on every ingredient line or on none',
    path: ['ingredients'],
  })
  .refine(
    (recipe) =>
      !recipe.tags.includes('quick') || recipe.prepMinutes + recipe.cookMinutes <= QUICK_MINUTES,
    {
      message: `quick means prep and cooking within ${String(QUICK_MINUTES)} minutes`,
      path: ['tags'],
    },
  );
export type Recipe = z.infer<typeof recipeSource>;
