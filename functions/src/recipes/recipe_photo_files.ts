import { hash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { CATALOGUE_PHOTOS_DIR } from './catalogue_recipe_files';
import type { PhotoSize } from './recipe_photo';
import { RECIPES } from './recipe';

/** One photo file as the seed publishes it: its Storage object path and its bytes. */
export interface PhotoObject {
  readonly path: string;
  readonly bytes: Buffer;
}

export type RecipePhotoObjects = Readonly<Record<PhotoSize, PhotoObject>>;

const JPEG_START = [0xff, 0xd8, 0xff];

/**
 * A recipe's two photos from `catalogue/recipe-photos/<id>/`, each named in
 * Storage by a short hash of its content (recipes ADR-0003 §4), so a changed
 * picture is a new object and no cache ever serves the old one. A missing
 * file, or one that is not a JPEG, throws with the recipe's id.
 */
export function readRecipePhotos(
  recipeId: string,
  dir: string = CATALOGUE_PHOTOS_DIR,
): RecipePhotoObjects {
  return { hero: readPhoto(recipeId, 'hero', dir), card: readPhoto(recipeId, 'card', dir) };
}

function readPhoto(recipeId: string, size: PhotoSize, dir: string): PhotoObject {
  const file = resolve(dir, recipeId, `${size}.jpg`);
  let bytes: Buffer;
  try {
    bytes = readFileSync(file);
  } catch (error) {
    throw new Error(`recipe ${recipeId} has no catalogue/recipe-photos/${recipeId}/${size}.jpg`, {
      cause: error,
    });
  }
  if (!JPEG_START.every((byte, index) => bytes[index] === byte)) {
    throw new Error(`catalogue/recipe-photos/${recipeId}/${size}.jpg is not a JPEG`);
  }
  return { path: photoObjectPath(recipeId, size, bytes), bytes };
}

/** `recipes/<id>/<size>-<first 8 hex of its SHA-256>.jpg`. */
export function photoObjectPath(recipeId: string, size: PhotoSize, bytes: Uint8Array): string {
  const short = hash('sha256', bytes, 'hex').slice(0, 8);
  return `${RECIPES}/${recipeId}/${size}-${short}.jpg`;
}
