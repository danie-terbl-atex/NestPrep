import { hash } from 'node:crypto';

import { type DocumentReference, FieldValue, type Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { addDays, weekdayOf } from '../calendar_sync/zoned_time';
import { normalisedName } from '../home_care/restock_decision';
import { type MemberRecord, type StoredHousehold, recipientsOf } from '../notifications/recipients';
import { HOUSEHOLD_RECIPES } from '../recipes/household_recipe';
import { OWN_RECIPE_ID, OWN_SOURCE } from '../recipes/own_recipe';
import { DIET_TAGS, RECIPE_CONTEXTS, RECIPES } from '../recipes/recipe';
import { type MealLine, recipeMealLines } from '../recipes/recipe_meal_lines';
import { amountText, recipeScale, startingPeopleFor } from '../recipes/recipe_scale';
import { type FrameRecipeLink, type MealSlot, mondayOf } from './frame_day';
import { parsed } from './frame_documents';
import { recipePhotoPath } from './frame_meal_photos';
import {
  type FrameRecipe,
  type FrameRecipeSource,
  buildFrameRecipe,
  frameRecipeDocument,
  ownRecipeFrameDocument,
} from './frame_recipe';
import type { FramePanels } from './frame_schemas';

export const MEALS = 'meals';
export const MEAL_PLANS = 'mealPlans';
export const FRAME_REQUESTS = 'frameRequests';

const CATALOGUE_RECIPE_ID = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const MEAL_ID_PREFIX = 'recipe-';
const PLAN_WEEKS = 2;

export interface FrameRecipeEntry {
  readonly id: string;
  readonly household: boolean;
  readonly name: string;
  readonly contexts: string[];
  readonly minutes?: number;
  readonly servings: number;
  readonly photo: boolean;
  readonly diet: string[];
}

export const frameRecipeListing = z.object({
  name: z.string().trim().min(1),
  contexts: z.array(z.string()).catch([]),
  servings: z.number().int().min(1),
  prepMinutes: z.number().int().min(0).catch(0),
  cookMinutes: z.number().int().min(0).catch(0),
  dietTags: z.array(z.string()).catch([]),
  photo: z.unknown().optional(),
});
export type FrameRecipeListing = z.infer<typeof frameRecipeListing>;

export function mealsEditorsOf(
  household: StoredHousehold,
  members: readonly MemberRecord[],
): string[] {
  return recipientsOf(household, members)
    .filter((recipient) => recipient.levels.meals === 'edit')
    .map((recipient) => recipient.memberId);
}

export function recipesShown(panels: FramePanels, premium: boolean): boolean {
  return panels.meals && premium;
}

export function frameRecipeLink(id: string, household: boolean): FrameRecipeLink | null {
  const fits = household
    ? OWN_RECIPE_ID.test(id)
    : CATALOGUE_RECIPE_ID.test(id) && id.length <= 60 && !id.startsWith('own-');
  return fits ? { id, household } : null;
}

export function mealIdOf(link: FrameRecipeLink): string {
  return `${MEAL_ID_PREFIX}${link.id}`;
}

export function recipeOfPhotoId(photoId: string): FrameRecipeLink | null {
  if (!photoId.startsWith(MEAL_ID_PREFIX)) return null;
  const id = photoId.slice(MEAL_ID_PREFIX.length);
  return frameRecipeLink(id, id.startsWith('own-'));
}

export function frameRecipeEntry(
  link: FrameRecipeLink,
  listing: FrameRecipeListing,
): FrameRecipeEntry {
  const minutes = listing.prepMinutes + listing.cookMinutes;
  return {
    id: link.id,
    household: link.household,
    name: listing.name,
    contexts: RECIPE_CONTEXTS.filter((context) => listing.contexts.includes(context)),
    ...(minutes > 0 ? { minutes } : {}),
    servings: listing.servings,
    photo: recipePhotoPath(listing) !== null,
    diet: DIET_TAGS.filter((tag) => listing.dietTags.includes(tag)),
  };
}

export function frameRecipesInOrder(entries: readonly FrameRecipeEntry[]): FrameRecipeEntry[] {
  return [...entries].sort(
    (a, b) =>
      a.name.localeCompare(b.name) ||
      Number(a.household) - Number(b.household) ||
      a.id.localeCompare(b.id),
  );
}

export function frameRecipesVersion(entries: readonly FrameRecipeEntry[]): string {
  return hash('sha256', JSON.stringify(entries), 'hex').slice(0, 16);
}

function scaleFor(recipe: FrameRecipeSource, familySize: number): ReturnType<typeof recipeScale> {
  return recipeScale(
    startingPeopleFor(recipe.contexts, recipe.servings, familySize),
    recipe.servings,
  );
}

export function frameRecipeAt(
  link: FrameRecipeLink,
  recipe: FrameRecipeSource,
  familySize: number,
): FrameRecipe | null {
  const scale = scaleFor(recipe, familySize);
  return buildFrameRecipe(recipe, {
    id: link.id,
    people: scale.people,
    amounts: recipe.ingredients.map((line) => amountText(line, scale)),
  });
}

export function frameMealLines(recipe: FrameRecipeSource, familySize: number): MealLine[] {
  return recipeMealLines(recipe.ingredients, scaleFor(recipe, familySize));
}

export interface FrameRecipeMeal {
  readonly name: string;
  readonly nameKey: string;
  readonly addedBy: string;
  readonly ingredients: MealLine[];
  readonly recipeId?: string;
  readonly householdRecipeId?: string;
}

export function frameRecipeMeal(
  link: FrameRecipeLink,
  recipe: FrameRecipeSource,
  addedBy: string,
  familySize: number,
): FrameRecipeMeal {
  const name = recipe.name.trim();
  return {
    name,
    nameKey: normalisedName(name),
    addedBy,
    ingredients: frameMealLines(recipe, familySize),
    ...(link.household ? { householdRecipeId: link.id } : { recipeId: link.id }),
  };
}

export function inPlanReach(date: string, today: string): boolean {
  const monday = mondayOf(today);
  return date >= monday && date <= addDays(monday, PLAN_WEEKS * 7 - 1);
}

export function planSlotKey(date: string, slot: MealSlot): string {
  return `${String(weekdayOf(date))}_${slot}`;
}

export function frameRequestId(frameId: string, requestId: string): string {
  return `frame-${frameId}-${requestId}`;
}

export function frameRequestDocument(frameId: string, expiresAt: Date): Record<string, unknown> {
  return { frameId, kind: 'planMeal', at: FieldValue.serverTimestamp(), expiresAt };
}

export function recipeRef(
  store: Firestore,
  home: DocumentReference,
  link: FrameRecipeLink,
): DocumentReference {
  return link.household
    ? home.collection(HOUSEHOLD_RECIPES).doc(link.id)
    : store.collection(RECIPES).doc(link.id);
}

export function frameRecipeOf(link: FrameRecipeLink, data: unknown): FrameRecipeSource | null {
  if (link.household) return parsed(ownRecipeFrameDocument, data);
  const recipe = parsed(frameRecipeDocument, data);
  return recipe?.status === 'published' ? recipe : null;
}

export async function readFrameRecipe(
  store: Firestore,
  home: DocumentReference,
  link: FrameRecipeLink,
): Promise<FrameRecipeSource | null> {
  return frameRecipeOf(link, (await recipeRef(store, home, link).get()).data());
}

export async function readRecipePhotoPath(
  store: Firestore,
  home: DocumentReference,
  link: FrameRecipeLink,
): Promise<string | null> {
  const data = (await recipeRef(store, home, link).get()).data();
  const shown = link.household
    ? parsed(z.object({ source: z.literal(OWN_SOURCE) }), data) !== null
    : parsed(z.object({ status: z.literal('published') }), data) !== null;
  return shown ? recipePhotoPath(data) : null;
}
