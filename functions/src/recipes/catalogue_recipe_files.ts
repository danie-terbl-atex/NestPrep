import { readdirSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { z } from 'zod';

import { recipeSource, type Recipe } from './recipe';

/**
 * Where authors write NestPrep's recipes (recipes ADR-0003): one JSON file per
 * recipe, and its two photos, in the repo's `catalogue/` — outside
 * `functions/`, so a Functions deploy carries neither. Resolved from this
 * file, which sits two folders under `functions/` both as source (`src/recipes/`)
 * and compiled (`lib/recipes/`), so the tests and the seed find the same place.
 */
export const CATALOGUE_DIR = resolve(__dirname, '../../../catalogue');
export const CATALOGUE_RECIPES_DIR = resolve(CATALOGUE_DIR, 'recipes');
export const CATALOGUE_PHOTOS_DIR = resolve(CATALOGUE_DIR, 'recipe-photos');

const JSON_FILE = /^(.+)\.json$/;

/**
 * Every recipe in [dir], parsed (ENG-09), in file-name order. A file that is
 * not JSON, does not parse, breaks the shape, or is not named after its id
 * throws with its name — the seed stops, and no household sees half a
 * catalogue. Hidden files (`.DS_Store`) are not recipes. A missing directory
 * throws too: an empty catalogue would retire every published recipe.
 */
export function readCatalogueRecipes(dir: string = CATALOGUE_RECIPES_DIR): Recipe[] {
  return readdirSync(dir)
    .filter((file) => !file.startsWith('.'))
    .sort()
    .map((file) => readRecipeFile(dir, file));
}

function readRecipeFile(dir: string, file: string): Recipe {
  const id = JSON_FILE.exec(file)?.[1];
  if (id === undefined) throw new Error(`catalogue/recipes/${file} is not a .json recipe`);
  const parsed = recipeSource.safeParse(parsedJson(dir, file));
  if (!parsed.success) {
    throw new Error(`catalogue/recipes/${file}: ${z.prettifyError(parsed.error)}`);
  }
  if (parsed.data.id !== id) {
    throw new Error(`catalogue/recipes/${file} holds the recipe ${parsed.data.id}`);
  }
  return parsed.data;
}

function parsedJson(dir: string, file: string): unknown {
  try {
    return JSON.parse(readFileSync(resolve(dir, file), 'utf8'));
  } catch (error) {
    throw new Error(`catalogue/recipes/${file} is not valid JSON`, { cause: error });
  }
}
