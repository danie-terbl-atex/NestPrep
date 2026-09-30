/**
 * The admin app the cloud demo tools run as: the real project, with Google
 * application-default credentials (`gcloud auth application-default login`,
 * or `GOOGLE_APPLICATION_CREDENTIALS`). Initialised before anything from
 * `lib/` asks for it, so the Functions' own code (`adminApp()`) reuses it.
 * Nothing here is a secret; the one password lives in `app/demo_logins.json`.
 */
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';

import { CLOUD_CAST } from './cast.mjs';

const require = createRequire(import.meta.url);
const { applicationDefault, initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');

export const PROJECT = process.env.NESTPREP_PROJECT ?? 'nestprep-643b7';
const BUCKET = `${PROJECT}.firebasestorage.app`;
const LOGINS = resolve(import.meta.dirname, '../../../app/demo_logins.json');

/** Refuses anything that is not the demo household and the demo accounts. */
export function assertDemoScope() {
  const ids = [CLOUD_CAST.householdId, ...CLOUD_CAST.people.map((person) => person.uid)];
  const stray = ids.filter((id) => !id.startsWith('demo-'));
  if (stray.length > 0) throw new Error(`refusing: not a demo id: ${stray.join(', ')}`);
}

export function connect() {
  assertDemoScope();
  process.env.GCLOUD_PROJECT ??= PROJECT;
  process.env.GOOGLE_CLOUD_PROJECT ??= PROJECT;
  const app = initializeApp({
    credential: applicationDefault(),
    projectId: PROJECT,
    storageBucket: BUCKET,
  });
  const target = process.env.FIRESTORE_EMULATOR_HOST
    ? `the emulator at ${process.env.FIRESTORE_EMULATOR_HOST}`
    : `the cloud project ${PROJECT}`;
  return {
    target,
    store: getFirestore(app),
    auth: getAuth(app),
    bucket: getStorage(app).bucket(BUCKET),
  };
}

/**
 * The demo password, from the gitignored defines file the demo build reads,
 * after checking every address in it is the one the cast signs in with.
 */
export function demoPassword() {
  let logins;
  try {
    logins = JSON.parse(readFileSync(LOGINS, 'utf8'));
  } catch (error) {
    throw new Error(`cannot read ${LOGINS} — create it first (see the vault note)`, {
      cause: error,
    });
  }
  const password = logins.NESTPREP_DEMO_PASSWORD;
  if (typeof password !== 'string' || password.length < 16) {
    throw new Error('NESTPREP_DEMO_PASSWORD in demo_logins.json must be at least 16 characters');
  }
  for (const { loginKey, email } of CLOUD_CAST.people) {
    if (logins[`NESTPREP_DEMO_EMAIL_${loginKey}`] !== email) {
      throw new Error(`demo_logins.json NESTPREP_DEMO_EMAIL_${loginKey} is not ${email}`);
    }
  }
  return password;
}
