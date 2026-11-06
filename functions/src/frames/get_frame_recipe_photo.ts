import { db } from '../shared/firestore';
import { frameJpegEndpoint } from './frame_jpeg';
import { mealPhotoPath } from './frame_meal_photos';
import { FRAME_RECIPE_PHOTO_PER_CREDENTIAL } from './frame_policy';

export const getFrameRecipePhoto = frameJpegEndpoint(
  FRAME_RECIPE_PHOTO_PER_CREDENTIAL,
  ({ frame, home }, id) => {
    const { share } = frame;
    if (frame.panels.share && share?.kind === 'recipe' && share.id === id) return share.photoPath;
    return frame.panels.meals ? mealPhotoPath(db(), home, id) : null;
  },
);
