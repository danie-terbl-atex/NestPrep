import type { StoredObject } from '../shared/storage';
import { FRAME_PHOTO_LIMIT } from './frame_policy';
import { FRAME_PHOTO_ID } from './frame_schemas';

export interface FramePhoto {
  readonly id: string;
  readonly bytes: number;
}

/**
 * The photos a screensaver cycles through (photo-frames ADR-0006): only the
 * album's own JPEGs by a name the rules allow, newest first, at most
 * `FRAME_PHOTO_LIMIT`.
 */
export function framePhotosOf(objects: readonly StoredObject[], prefix: string): FramePhoto[] {
  return objects
    .flatMap((object) => {
      const id = object.name.slice(prefix.length);
      return object.name.startsWith(prefix) &&
        FRAME_PHOTO_ID.test(id) &&
        object.contentType === 'image/jpeg'
        ? [{ id, bytes: object.size, at: object.timeCreated?.getTime() ?? 0 }]
        : [];
    })
    .sort((a, b) => b.at - a.at)
    .slice(0, FRAME_PHOTO_LIMIT)
    .map(({ id, bytes }) => ({ id, bytes }));
}
