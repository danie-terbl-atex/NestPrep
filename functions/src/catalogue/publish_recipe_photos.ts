import type { PhotoObject } from '../recipes/recipe_photo_files';
import type { ObjectStore } from '../shared/storage';

/**
 * A photo's object name carries its content's hash (recipes ADR-0003 §4), so
 * an object never changes once written and may be cached for a year.
 */
export const RECIPE_PHOTO_CACHE_CONTROL = 'public, max-age=31536000, immutable';

/** How many uploads or checks are in flight at once; a seed is not a stampede. */
const IN_FLIGHT = 8;

export type PhotoStore = Pick<ObjectStore, 'exists' | 'save'>;

export interface PhotoSummary {
  /** Uploaded — or, in a dry run, that would be. */
  readonly uploaded: number;
  /** Already in Storage under the same content hash, so left alone. */
  readonly present: number;
}

/**
 * Uploads every recipe photo not yet in Storage (recipes ADR-0003 §4). Run
 * before the recipe documents are written, so a published recipe never names
 * a picture that is not there. Safe to run again: a photo already present
 * under its content hash is skipped. With `write: false` it only counts.
 */
export async function publishRecipePhotos(
  objects: PhotoStore,
  photos: readonly PhotoObject[],
  { write }: { readonly write: boolean },
): Promise<PhotoSummary> {
  let uploaded = 0;
  let present = 0;
  for (let start = 0; start < photos.length; start += IN_FLIGHT) {
    await Promise.all(
      photos.slice(start, start + IN_FLIGHT).map(async (photo) => {
        if (await objects.exists(photo.path)) {
          present += 1;
          return;
        }
        if (write) {
          await objects.save(photo.path, photo.bytes, 'image/jpeg', RECIPE_PHOTO_CACHE_CONTROL);
        }
        uploaded += 1;
      }),
    );
  }
  return { uploaded, present };
}
