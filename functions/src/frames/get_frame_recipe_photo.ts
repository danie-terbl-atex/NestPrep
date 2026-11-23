import { db } from '../shared/firestore';
import { frameJpegEndpoint } from './frame_jpeg';
import { readFramePremium } from './frame_lunch_photos';
import { mealPhotoPath } from './frame_meal_photos';
import { FRAME_RECIPE_PHOTO_PER_CREDENTIAL } from './frame_policy';
import { readRecipePhotoPath, recipeOfPhotoId } from './frame_recipes';

export const getFrameRecipePhoto = frameJpegEndpoint(
  FRAME_RECIPE_PHOTO_PER_CREDENTIAL,
  async ({ frame, home }, id) => {
    const { share } = frame;
    if (frame.panels.share && share?.kind === 'recipe' && share.id === id) return share.photoPath;
    if (!frame.panels.meals) return null;
    const store = db();
    const planned = await mealPhotoPath(store, home, id);
    if (planned !== null) return planned;
    const recipe = recipeOfPhotoId(id);
    if (recipe === null || !(await readFramePremium(store, home))) return null;
    return readRecipePhotoPath(store, home, recipe);
  },
);
