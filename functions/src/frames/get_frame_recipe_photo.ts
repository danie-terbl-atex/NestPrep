import { frameJpegEndpoint } from './frame_jpeg';
import { FRAME_RECIPE_PHOTO_PER_CREDENTIAL } from './frame_policy';

export const getFrameRecipePhoto = frameJpegEndpoint(
  FRAME_RECIPE_PHOTO_PER_CREDENTIAL,
  ({ frame }, id) => {
    const { share } = frame;
    if (!frame.panels.share || share?.kind !== 'recipe' || share.id !== id) return null;
    return share.photoPath;
  },
);
