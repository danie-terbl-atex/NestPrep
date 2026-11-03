import { db } from '../shared/firestore';
import { frameJpegEndpoint } from './frame_jpeg';
import { readFrameLunch } from './frame_lunch_photos';
import { FRAME_LUNCH_PHOTO_PER_CREDENTIAL } from './frame_policy';

/**
 * The picture of one of today's lunch boxes (photo-frames ADR-0009): only an
 * id the frame's own day carries now, so a lunch panel switched off, a
 * subscription that ended or a box changed since makes it `missing`.
 */
export const getFrameLunchPhoto = frameJpegEndpoint(
  FRAME_LUNCH_PHOTO_PER_CREDENTIAL,
  async (linked, id) => {
    if (!linked.frame.panels.lunch) return null;
    const { lunchPhotos } = await readFrameLunch(db(), linked.home, linked.clock.date);
    return Object.values(lunchPhotos).find((photo) => photo.id === id)?.path ?? null;
  },
);
