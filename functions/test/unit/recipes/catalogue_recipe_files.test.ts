import { copyFileSync, mkdirSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

import { describe, expect, it } from 'vitest';

import {
  CATALOGUE_PHOTOS_DIR,
  CATALOGUE_RECIPES_DIR,
  readCatalogueRecipes,
} from '../../../src/recipes/catalogue_recipe_files';
import { photoObjectPath, readRecipePhotos } from '../../../src/recipes/recipe_photo_files';

/**
 * Recipes ADR-0003: authors write one JSON file per recipe under the repo's
 * `catalogue/`, and the seed reads them from there. A file the loader cannot
 * trust stops the seed with the file's name, never a household.
 */

const FIXTURES = resolve(import.meta.dirname, '../../fixtures/catalogue');
const FIXTURE_RECIPES = join(FIXTURES, 'recipes');
const FIXTURE_PHOTOS = join(FIXTURES, 'recipe-photos');

function recipesDirWith(files: Record<string, string>): string {
  const dir = mkdtempSync(join(tmpdir(), 'nestprep-recipes-'));
  for (const [name, contents] of Object.entries(files)) writeFileSync(join(dir, name), contents);
  return dir;
}

const bobotie = (): string => {
  const dir = recipesDirWith({});
  copyFileSync(join(FIXTURE_RECIPES, 'bobotie.json'), join(dir, 'bobotie.json'));
  return dir;
};

describe('reading the written catalogue', () => {
  it('finds the repo’s catalogue folder from source and from lib/ alike', () => {
    expect(CATALOGUE_RECIPES_DIR).toBe(
      resolve(import.meta.dirname, '../../../../catalogue/recipes'),
    );
    expect(CATALOGUE_PHOTOS_DIR).toBe(
      resolve(import.meta.dirname, '../../../../catalogue/recipe-photos'),
    );
  });

  it('parses every recipe file, in file-name order', () => {
    const recipes = readCatalogueRecipes(FIXTURE_RECIPES);
    expect(recipes.map(({ id }) => id)).toEqual(['bobotie', 'vetkoek']);
    expect(recipes[0]?.placement).toEqual({ dinner: 'main' });
    expect(recipes[1]?.photo?.licence).toBe('CC BY-SA 4.0');
  });

  it('refuses a file not named after the recipe it holds', () => {
    const dir = bobotie();
    copyFileSync(join(dir, 'bobotie.json'), join(dir, 'malva-pudding.json'));
    expect(() => readCatalogueRecipes(dir)).toThrow(/malva-pudding\.json holds the recipe bobotie/);
  });

  it('refuses broken JSON and a recipe that breaks the shape, naming the file', () => {
    expect(() => readCatalogueRecipes(recipesDirWith({ 'a.json': '{ "id": ' }))).toThrow(
      /a\.json is not valid JSON/,
    );
    expect(() => readCatalogueRecipes(recipesDirWith({ 'b.json': '{ "id": "b" }' }))).toThrow(
      /b\.json/,
    );
  });

  it('refuses a file that is not JSON, and passes over hidden ones', () => {
    expect(() => readCatalogueRecipes(recipesDirWith({ 'notes.txt': 'x' }))).toThrow(
      /notes\.txt is not a \.json recipe/,
    );
    const dir = bobotie();
    writeFileSync(join(dir, '.DS_Store'), '');
    expect(readCatalogueRecipes(dir).map(({ id }) => id)).toEqual(['bobotie']);
  });

  it('refuses a missing folder rather than read it as an empty catalogue', () => {
    expect(() => readCatalogueRecipes(join(tmpdir(), 'nestprep-no-such-folder'))).toThrow();
  });
});

describe('reading a recipe’s photos', () => {
  it('names each file in Storage by the recipe and a hash of its content', () => {
    const photos = readRecipePhotos('bobotie', FIXTURE_PHOTOS);
    expect(photos.hero.path).toMatch(/^recipes\/bobotie\/hero-[0-9a-f]{8}\.jpg$/);
    expect(photos.card.path).toMatch(/^recipes\/bobotie\/card-[0-9a-f]{8}\.jpg$/);
    expect(photos.hero.path).toBe(photoObjectPath('bobotie', 'hero', photos.hero.bytes));
  });

  it('gives changed bytes a new name, so no cache serves the old picture', () => {
    const one = photoObjectPath('bobotie', 'hero', new Uint8Array([0xff, 0xd8, 0xff, 1]));
    const two = photoObjectPath('bobotie', 'hero', new Uint8Array([0xff, 0xd8, 0xff, 2]));
    expect(one).not.toBe(two);
  });

  it('refuses a recipe missing a size, or a file that is not a JPEG', () => {
    const dir = mkdtempSync(join(tmpdir(), 'nestprep-photos-'));
    expect(() => readRecipePhotos('bobotie', dir)).toThrow(/bobotie has no .*hero\.jpg/);
    const png = mkdtempSync(join(tmpdir(), 'nestprep-photos-'));
    mkdirSync(join(png, 'bobotie'));
    writeFileSync(join(png, 'bobotie', 'hero.jpg'), new Uint8Array([0x89, 0x50, 0x4e, 0x47]));
    copyFileSync(join(FIXTURE_PHOTOS, 'bobotie', 'card.jpg'), join(png, 'bobotie', 'card.jpg'));
    expect(() => readRecipePhotos('bobotie', png)).toThrow(/bobotie\/hero\.jpg is not a JPEG/);
  });
});
