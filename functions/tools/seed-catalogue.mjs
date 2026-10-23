#!/usr/bin/env node
/**
 * Publishes NestPrep's own catalogue — the recipes and the ready-made starter
 * boxes (recipes ADR-0001, ADR-0003, lunch-box ADR-0018) — from the Functions'
 * source and the repo's `catalogue/` (`lib/catalogue/publish_catalogue.js`)
 * into `recipes/` and `lunchStarterBoxes/`, and each recipe's photos into
 * Storage at `recipes/<id>/`. Ids are fixed; a changed entry goes up a
 * version; an entry removed from source is retired, never deleted; a photo
 * already uploaded is skipped. Safe to run again: an unchanged catalogue
 * writes nothing. It touches no household.
 *
 * The emulator seed (`seed-emulator.mjs`) runs the same function on every
 * start. Against the real project this is a dry run unless confirmed:
 *
 *     npm run build && npm run seed:catalogue                 # what would change
 *     npm run build && npm run seed:catalogue -- --confirm    # write it
 *
 * Needs Google application-default credentials for the project
 * (`gcloud auth application-default login`); `NESTPREP_PROJECT` overrides the
 * project id. With `FIRESTORE_EMULATOR_HOST` set it writes the emulator
 * instead, photos included (`FIREBASE_STORAGE_EMULATOR_HOST`, default
 * 127.0.0.1:9199) — never the real bucket. Prints counts only.
 */
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { applicationDefault, initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { publishCatalogue } = require('../lib/catalogue/publish_catalogue.js');
const { bucketName, objectStore } = require('../lib/shared/storage.js');

const PROJECT = process.env.NESTPREP_PROJECT ?? 'nestprep-643b7';
const emulator = process.env.FIRESTORE_EMULATOR_HOST;
const write = emulator !== undefined || process.argv.includes('--confirm');

process.env.GCLOUD_PROJECT ??= PROJECT;
process.env.GOOGLE_CLOUD_PROJECT ??= PROJECT;
// The emulator needs no credentials; without this the SDK first probes for a
// cloud metadata server a laptop does not have, and warns after a timeout.
if (emulator) process.env.METADATA_SERVER_DETECTION ??= 'none';
// Firestore in the emulator with photos in the real bucket would be the worst
// of both: point Storage at the emulator whenever Firestore is.
if (emulator) process.env.FIREBASE_STORAGE_EMULATOR_HOST ??= '127.0.0.1:9199';
const storageBucket = bucketName();
initializeApp(
  emulator
    ? { projectId: PROJECT, storageBucket }
    : { credential: applicationDefault(), projectId: PROJECT, storageBucket },
);
const target = emulator ? `the emulator at ${emulator}` : `the cloud project ${PROJECT}`;

// `objectStore()` takes the default app initialised above, so Firestore and
// Storage are the same project.
const { collections, photos } = await publishCatalogue(getFirestore(), objectStore(), { write });
console.log(`${write ? 'published to' : 'dry run against'} ${target} (bucket ${storageBucket})`);
console.log(`  photos: ${photos.uploaded} uploaded, ${photos.present} already there`);
for (const { collection, published, retired, unchanged } of collections) {
  console.log(
    `  ${collection}: ${published} published, ${retired} retired, ${unchanged} unchanged`,
  );
}
if (!write) console.log('\nnothing written — run again with `-- --confirm` to write it');
