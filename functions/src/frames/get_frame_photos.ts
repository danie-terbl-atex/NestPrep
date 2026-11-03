import { onCall } from 'firebase-functions/v2/https';

import { parseInput } from '../household/parse_input';
import { db } from '../shared/firestore';
import { objectStore } from '../shared/storage';
import { readLinkedFrame } from './frame_access';
import { framePhotosPrefix } from './frame_documents';
import { type FramePhoto, framePhotosOf } from './frame_photos';
import {
  FRAME_DEVICE_OPTIONS,
  FRAME_PHOTOS_PER_CREDENTIAL,
  FRAME_PHOTO_SCAN,
} from './frame_policy';
import { getFramePhotosInput } from './frame_schemas';

export type GetFramePhotosResult =
  { status: 'unlinked' } | { status: 'linked'; photos: FramePhoto[] };

const UNLINKED: GetFramePhotosResult = { status: 'unlinked' };

/**
 * A linked frame lists its household's screensaver album (photo-frames
 * ADR-0006); a frame whose screensaver is off is told there is nothing to show.
 */
export const getFramePhotos = onCall(
  FRAME_DEVICE_OPTIONS,
  async (request): Promise<GetFramePhotosResult> => {
    const { secret } = parseInput(getFramePhotosInput, request.data);
    const linked = await readLinkedFrame(db(), secret, FRAME_PHOTOS_PER_CREDENTIAL);
    if (linked === null) return UNLINKED;
    if (linked.frame.screensaver === null) return { status: 'linked', photos: [] };

    const prefix = framePhotosPrefix(linked.home.id);
    const objects = await objectStore().list(prefix, FRAME_PHOTO_SCAN);
    return { status: 'linked', photos: framePhotosOf(objects, prefix) };
  },
);
