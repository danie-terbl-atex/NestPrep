import { onCall } from 'firebase-functions/v2/https';

import { parseInput } from '../household/parse_input';
import { db } from '../shared/firestore';
import { readLinkedFrame } from './frame_access';
import { refuseFrame } from './frame_errors';
import { readFramePremium } from './frame_lunch_photos';
import { FRAME_DEVICE_OPTIONS, FRAME_RECIPE_PER_CREDENTIAL } from './frame_policy';
import { type FrameRecipe } from './frame_recipe';
import { frameRecipeAt, frameRecipeLink, readFrameRecipe, recipesShown } from './frame_recipes';
import { readFamilySize } from './frame_reads';
import { getFrameRecipeInput } from './frame_schemas';

export type GetFrameRecipeResult =
  { status: 'unlinked' } | { status: 'linked'; recipe: FrameRecipe };

const UNLINKED: GetFrameRecipeResult = { status: 'unlinked' };

export const getFrameRecipe = onCall(
  FRAME_DEVICE_OPTIONS,
  async (request): Promise<GetFrameRecipeResult> => {
    const input = parseInput(getFrameRecipeInput, request.data);
    const store = db();
    const linked = await readLinkedFrame(store, input.secret, FRAME_RECIPE_PER_CREDENTIAL);
    if (linked === null) return UNLINKED;
    if (!recipesShown(linked.frame.panels, await readFramePremium(store, linked.home))) {
      throw refuseFrame('recipesOff');
    }
    const link = frameRecipeLink(input.id, input.household);
    const [source, familySize] = await Promise.all([
      link === null ? null : readFrameRecipe(store, linked.home, link),
      readFamilySize(linked.home),
    ]);
    const recipe =
      link === null || source === null ? null : frameRecipeAt(link, source, familySize);
    if (recipe === null) throw refuseFrame('recipeNotFound');
    return { status: 'linked', recipe };
  },
);
