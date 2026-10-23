import {
  FieldValue,
  type DocumentReference,
  type Firestore,
  type UpdateData,
} from 'firebase-admin/firestore';

import { SEED_FOODS } from '../lunch_photos/seed_foods';
import {
  LUNCH_STARTER_BOXES,
  MAX_STARTER_BOXES,
  starterBoxSource,
} from '../lunch_starter_boxes/starter_box';
import { starterBoxDocument } from '../lunch_starter_boxes/starter_box_document';
import { STARTER_BOXES } from '../lunch_starter_boxes/starter_boxes';
import { CATALOGUE_PHOTOS_DIR, CATALOGUE_RECIPES_DIR } from '../recipes/catalogue_recipe_files';
import { RECIPES, type Recipe } from '../recipes/recipe';
import { catalogueRecipeSources, recipeCatalogue } from '../recipes/recipe_catalogue';
import { recipeDocument } from '../recipes/recipe_document';
import { readRecipePhotos, type PhotoObject } from '../recipes/recipe_photo_files';
import {
  planCatalogue,
  storedCatalogueEntry,
  type CatalogueEntry,
  type StoredCatalogueEntry,
} from './catalogue_plan';
import { publishRecipePhotos, type PhotoStore, type PhotoSummary } from './publish_recipe_photos';

/** Far above any catalogue NestPrep writes by hand; a read that reaches it stops the seed (BE-08). */
const MAX_STORED = 400;

/** Firestore's limit on the writes in one batch. */
const BATCH_LIMIT = 500;

export interface CatalogueSummary {
  readonly collection: string;
  readonly published: number;
  readonly retired: number;
  readonly unchanged: number;
}

export interface PublishSummary {
  readonly collections: readonly CatalogueSummary[];
  readonly photos: PhotoSummary;
}

/** Everything the catalogue publishes: each collection's documents, and the recipes' photo files. */
export interface CatalogueSource {
  readonly entries: Readonly<Record<string, readonly CatalogueEntry[]>>;
  readonly photos: readonly PhotoObject[];
}

/** Where the written recipes and their photos are read from; the repo's `catalogue/` unless a test or a check says otherwise. */
export interface CatalogueDirs {
  readonly recipes: string;
  readonly photos: string;
}

const REPO_CATALOGUE: CatalogueDirs = {
  recipes: CATALOGUE_RECIPES_DIR,
  photos: CATALOGUE_PHOTOS_DIR,
};

interface StagedWrite {
  readonly ref: DocumentReference;
  readonly data: UpdateData<Record<string, unknown>>;
  readonly kind: 'set' | 'update';
}

/** Every recipe and starter box in source, as the documents and photo files they publish to. */
export function catalogueSource(dirs: CatalogueDirs = REPO_CATALOGUE): CatalogueSource {
  const recipes = recipeCatalogue(catalogueRecipeSources(dirs.recipes));
  const boxes = STARTER_BOXES.map((box) => starterBoxSource.parse(box));
  if (boxes.length > MAX_STARTER_BOXES) {
    throw new Error(`the app reads at most ${String(MAX_STARTER_BOXES)} starter boxes`);
  }
  const photos: PhotoObject[] = [];
  const recipeEntry = (recipe: Recipe): CatalogueEntry => {
    const files = recipe.photo === null ? null : readRecipePhotos(recipe.id, dirs.photos);
    if (files !== null) photos.push(files.hero, files.card);
    const paths = files === null ? null : { hero: files.hero.path, card: files.card.path };
    return { id: recipe.id, fields: recipeDocument(recipe, paths) };
  };
  return {
    entries: {
      [RECIPES]: [...recipes.values()].map(recipeEntry),
      [LUNCH_STARTER_BOXES]: boxes.map((box) => ({
        id: box.id,
        fields: starterBoxDocument(box, { recipes, seedFoods: SEED_FOODS }),
      })),
    },
    photos,
  };
}

/**
 * Publishes the catalogue: the recipes' photos to Storage first, then the
 * recipe and starter-box documents — new and changed entries at their next
 * version, entries gone from source retired. Safe to run again: an unchanged
 * catalogue uploads and writes nothing. With `write: false` it only says what
 * it would do. Run by the emulator seed and by `tools/seed-catalogue.mjs`.
 */
export async function publishCatalogue(
  store: Firestore,
  objects: PhotoStore,
  { write, dirs = REPO_CATALOGUE }: { readonly write: boolean; readonly dirs?: CatalogueDirs },
): Promise<PublishSummary> {
  const { entries, photos } = catalogueSource(dirs);
  const photoSummary = await publishRecipePhotos(objects, photos, { write });
  const staged: StagedWrite[] = [];
  const collections: CatalogueSummary[] = [];
  for (const [collection, collectionEntries] of Object.entries(entries)) {
    collections.push(await stageCollection(store, staged, collection, collectionEntries));
  }
  if (write) await commitInBatches(store, staged);
  return { collections, photos: photoSummary };
}

/**
 * One batch while the catalogue fits Firestore's 500 writes (BE-07); past
 * that, consecutive batches. Every entry is its own document and the plan is
 * idempotent, so a run cut off between two batches is finished by running it
 * again — nothing is half-written inside a document.
 */
async function commitInBatches(store: Firestore, staged: readonly StagedWrite[]): Promise<void> {
  for (let start = 0; start < staged.length; start += BATCH_LIMIT) {
    const batch = store.batch();
    for (const { ref, data, kind } of staged.slice(start, start + BATCH_LIMIT)) {
      if (kind === 'set') batch.set(ref, data);
      else batch.update(ref, data);
    }
    await batch.commit();
  }
}

async function stageCollection(
  store: Firestore,
  staged: StagedWrite[],
  collection: string,
  entries: readonly CatalogueEntry[],
): Promise<CatalogueSummary> {
  const snapshot = await store.collection(collection).limit(MAX_STORED).get();
  if (snapshot.size >= MAX_STORED)
    throw new Error(`${collection} holds ${String(MAX_STORED)} or more documents`);
  const stored = new Map<string, StoredCatalogueEntry>(
    snapshot.docs.map((doc) => [
      doc.id,
      storedCatalogueEntry(`${collection}/${doc.id}`, doc.data()),
    ]),
  );
  const plan = planCatalogue(entries, stored);
  const updatedAt = FieldValue.serverTimestamp();
  for (const write of plan.writes) {
    const ref = store.collection(collection).doc(write.id);
    staged.push(
      write.kind === 'publish'
        ? {
            ref,
            kind: 'set',
            data: { ...write.fields, status: 'published', version: write.version, updatedAt },
          }
        : { ref, kind: 'update', data: { status: 'retired', version: write.version, updatedAt } },
    );
  }
  const retired = plan.writes.filter((write) => write.kind === 'retire').length;
  return {
    collection,
    published: plan.writes.length - retired,
    retired,
    unchanged: plan.unchanged,
  };
}
