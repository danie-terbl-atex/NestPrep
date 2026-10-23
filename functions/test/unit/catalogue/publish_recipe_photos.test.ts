import { resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import { catalogueSource } from '../../../src/catalogue/publish_catalogue';
import {
  RECIPE_PHOTO_CACHE_CONTROL,
  publishRecipePhotos,
  type PhotoStore,
} from '../../../src/catalogue/publish_recipe_photos';
import { RECIPES } from '../../../src/recipes/recipe';

/**
 * Recipes ADR-0003 §4: the seed derives each photo's Storage name from its
 * content, and uploads each recipe photo once, under a name
 * that carries its content hash, as a JPEG cached for a year — and a photo
 * already there is never uploaded again.
 */

interface Saved {
  readonly path: string;
  readonly contentType: string;
  readonly cacheControl: string | undefined;
}

function recordingStore(present: readonly string[]): { store: PhotoStore; saved: Saved[] } {
  const saved: Saved[] = [];
  return {
    saved,
    store: {
      exists: (path) => Promise.resolve(present.includes(path)),
      save: (path, _contents, contentType, cacheControl): Promise<void> => {
        saved.push({ path, contentType, cacheControl });
        return Promise.resolve();
      },
    },
  };
}

const photo = (path: string): { path: string; bytes: Buffer } => ({
  path,
  bytes: Buffer.from([0xff, 0xd8, 0xff]),
});
const PHOTOS = Array.from({ length: 20 }, (_, index) =>
  photo(`recipes/r${String(index)}/hero-0.jpg`),
);

describe('publishing recipe photos', () => {
  it('uploads only what is not there yet, as an immutable year-long JPEG', async () => {
    const { store, saved } = recordingStore(['recipes/r0/hero-0.jpg', 'recipes/r1/hero-0.jpg']);
    const summary = await publishRecipePhotos(store, PHOTOS, { write: true });
    expect(summary).toEqual({ uploaded: 18, present: 2 });
    expect(saved.map(({ path }) => path)).not.toContain('recipes/r0/hero-0.jpg');
    expect(new Set(saved.map(({ path }) => path)).size).toBe(18);
    for (const file of saved) {
      expect(file.contentType).toBe('image/jpeg');
      expect(file.cacheControl).toBe('public, max-age=31536000, immutable');
    }
    expect(RECIPE_PHOTO_CACHE_CONTROL).toContain('immutable');
  });

  it('only counts in a dry run', async () => {
    const { store, saved } = recordingStore([]);
    expect(await publishRecipePhotos(store, PHOTOS, { write: false })).toEqual({
      uploaded: 20,
      present: 0,
    });
    expect(saved).toEqual([]);
  });

  it('lets a failed upload stop the seed, before any recipe names the picture', async () => {
    const { store } = recordingStore([]);
    const failing: PhotoStore = { ...store, save: () => Promise.reject(new Error('quota')) };
    await expect(publishRecipePhotos(failing, PHOTOS, { write: true })).rejects.toThrow('quota');
  });
});

describe('the catalogue the seed publishes', () => {
  const FIXTURES = resolve(import.meta.dirname, '../../fixtures/catalogue');
  const source = catalogueSource({
    recipes: resolve(FIXTURES, 'recipes'),
    photos: resolve(FIXTURES, 'recipe-photos'),
  });

  it('puts the written recipes beside the lunch box’s, each photo named by its hash', () => {
    const recipes = source.entries[RECIPES] ?? [];
    expect(recipes.map(({ id }) => id)).toEqual(expect.arrayContaining(['bobotie', 'vetkoek']));
    const bobotie = recipes.find(({ id }) => id === 'bobotie')?.fields;
    expect(bobotie?.['photo']).toEqual({
      hero: expect.stringMatching(/^recipes\/bobotie\/hero-[0-9a-f]{8}\.jpg$/) as unknown,
      card: expect.stringMatching(/^recipes\/bobotie\/card-[0-9a-f]{8}\.jpg$/) as unknown,
      credit: null,
      licence: null,
      sourceUrl: null,
      generated: true,
    });
  });

  it('uploads both sizes of every written recipe’s photo, and nothing for the lunch box’s', () => {
    expect(source.photos.map(({ path }) => path.split('/').slice(0, 2).join('/')).sort()).toEqual([
      'recipes/bobotie',
      'recipes/bobotie',
      'recipes/vetkoek',
      'recipes/vetkoek',
    ]);
  });
});
