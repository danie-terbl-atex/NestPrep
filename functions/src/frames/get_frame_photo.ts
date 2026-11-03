import { frameJpegEndpoint } from './frame_jpeg';
import { framePhotosPrefix } from './frame_documents';
import { FRAME_PHOTO_PER_CREDENTIAL } from './frame_policy';

/** One screensaver photo's bytes, while the frame's screensaver is on (photo-frames ADR-0006). */
export const getFramePhoto = frameJpegEndpoint(FRAME_PHOTO_PER_CREDENTIAL, (linked, id) =>
  linked.frame.screensaver === null ? null : `${framePhotosPrefix(linked.home.id)}${id}`,
);
