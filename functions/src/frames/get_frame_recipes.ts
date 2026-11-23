import type { DocumentReference, Firestore } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';

import { parseInput } from '../household/parse_input';
import { HOUSEHOLD_RECIPES } from '../recipes/household_recipe';
import { MAX_OWN_RECIPES, OWN_SOURCE } from '../recipes/own_recipe';
import { RECIPES } from '../recipes/recipe';
import { db } from '../shared/firestore';
import { readLinkedFrame } from './frame_access';
import { parsed } from './frame_documents';
import { refuseFrame } from './frame_errors';
import { readFramePremium } from './frame_lunch_photos';
import {
  FRAME_CATALOGUE_RECIPE_LIMIT,
  FRAME_DEVICE_OPTIONS,
  FRAME_RECIPES_PER_CREDENTIAL,
} from './frame_policy';
import {
  type FrameRecipeEntry,
  frameRecipeEntry,
  frameRecipeLink,
  frameRecipeListing,
  frameRecipesInOrder,
  frameRecipesVersion,
  recipesShown,
} from './frame_recipes';
import { getFrameRecipesInput } from './frame_schemas';

export type GetFrameRecipesResult =
  | { status: 'unlinked' }
  | { status: 'linked'; unchanged: true }
  | { status: 'linked'; version: string; recipes: FrameRecipeEntry[] };

const UNLINKED: GetFrameRecipesResult = { status: 'unlinked' };

export const getFrameRecipes = onCall(
  FRAME_DEVICE_OPTIONS,
  async (request): Promise<GetFrameRecipesResult> => {
    const input = parseInput(getFrameRecipesInput, request.data);
    const store = db();
    const linked = await readLinkedFrame(store, input.secret, FRAME_RECIPES_PER_CREDENTIAL);
    if (linked === null) return UNLINKED;
    if (!recipesShown(linked.frame.panels, await readFramePremium(store, linked.home))) {
      throw refuseFrame('recipesOff');
    }
    const recipes = await readFrameRecipeEntries(store, linked.home);
    const version = frameRecipesVersion(recipes);
    if (input.version === version) return { status: 'linked', unchanged: true };
    return { status: 'linked', version, recipes };
  },
);

async function readFrameRecipeEntries(
  store: Firestore,
  home: DocumentReference,
): Promise<FrameRecipeEntry[]> {
  const [catalogue, own] = await Promise.all([
    store
      .collection(RECIPES)
      .where('status', '==', 'published')
      .orderBy('name')
      .limit(FRAME_CATALOGUE_RECIPE_LIMIT)
      .get(),
    home
      .collection(HOUSEHOLD_RECIPES)
      .where('source', '==', OWN_SOURCE)
      .orderBy('name')
      .limit(MAX_OWN_RECIPES)
      .get(),
  ]);
  const entries = [
    ...catalogue.docs.map((doc) => ({ doc, household: false })),
    ...own.docs.map((doc) => ({ doc, household: true })),
  ].flatMap(({ doc, household }) => {
    const link = frameRecipeLink(doc.id, household);
    const listing = parsed(frameRecipeListing, doc.data());
    return link === null || listing === null ? [] : [frameRecipeEntry(link, listing)];
  });
  return frameRecipesInOrder(entries);
}
