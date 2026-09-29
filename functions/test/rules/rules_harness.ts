import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
  type RulesTestContext,
} from '@firebase/rules-unit-testing';
import type { Firestore } from 'firebase/firestore';
import {
  deleteObject,
  listAll,
  ref,
  type FirebaseStorage,
  type StorageReference,
} from 'firebase/storage';

export { assertFails, assertSucceeds };
export type { Firestore, FirebaseStorage };

const PROJECT_ID = 'nestprep-643b7';
const RULES_PATH = resolve(import.meta.dirname, '../../../firestore.rules');
const STORAGE_RULES_PATH = resolve(import.meta.dirname, '../../../storage.rules');

let environment: RulesTestEnvironment | undefined;

/**
 * The one emulator pair every rules test shares — Firestore for the metadata,
 * Storage for the bytes. Starting them per file would cost more than the tests
 * do.
 */
export async function rulesEnvironment(): Promise<RulesTestEnvironment> {
  environment ??= await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: readFileSync(RULES_PATH, 'utf8'), host: '127.0.0.1', port: 8080 },
    storage: { rules: readFileSync(STORAGE_RULES_PATH, 'utf8'), host: '127.0.0.1', port: 9199 },
  });
  return environment;
}

export async function clearData(): Promise<void> {
  const active = await rulesEnvironment();
  await active.clearFirestore();
  // Not `active.clearStorage()`: that lists the bucket's *root* and deletes
  // only the objects sitting there, and every object this app keeps is under
  // `households/…`. It cleared nothing, so each test inherited the objects the
  // tests before it wrote — and a denied upload to a reused name passed on
  // "the object already exists" rather than on the rule it was named for.
  await active.withSecurityRulesDisabled(async (context) => {
    await deleteEverythingUnder(ref(context.storage()));
  });
}

async function deleteEverythingUnder(folder: StorageReference): Promise<void> {
  const { items, prefixes } = await listAll(folder);
  await Promise.all(items.map((item) => deleteObject(item)));
  await Promise.all(prefixes.map((prefix) => deleteEverythingUnder(prefix)));
}

export async function closeRulesEnvironment(): Promise<void> {
  await environment?.cleanup();
  environment = undefined;
}

/** Firestore as a signed-in account sees it — the rules apply. */
export async function asUser(uid: string): Promise<Firestore> {
  const context: RulesTestContext = (await rulesEnvironment()).authenticatedContext(uid);
  return context.firestore() as unknown as Firestore;
}

/**
 * Firestore as a kid device sees it: its own uid, carrying the `kidProfile`
 * claim a real one has (accounts ADR-0003). The rules authorise it through the
 * household's `kids` map, not the claim — the claim is here so a rule that
 * reads it (the account document's) is tested against a real kid token.
 */
export async function asKid(
  uid: string,
  kidProfile: { householdId: string; memberId: string },
): Promise<Firestore> {
  const context: RulesTestContext = (await rulesEnvironment()).authenticatedContext(uid, {
    kidProfile,
  });
  return context.firestore() as unknown as Firestore;
}

/** Firestore as nobody sees it: no token at all. */
export async function asSignedOut(): Promise<Firestore> {
  const context: RulesTestContext = (await rulesEnvironment()).unauthenticatedContext();
  return context.firestore() as unknown as Firestore;
}

/**
 * Storage as a signed-in account sees it, carrying the `households` claim that
 * `syncDocumentAccess` writes. Storage rules cannot read Firestore, so this map
 * is the only thing they have to go on (documents ADR-0001) — and a test that
 * passes the wrong one is the test that proves it.
 */
export async function storageAs(
  uid: string,
  households: Record<string, string>,
  access?: Record<string, Record<string, string>>,
): Promise<FirebaseStorage> {
  // No `access` at all is a token minted before household ADR-0003; an empty
  // one is a token that says this account holds no grant anywhere.
  const claims = access === undefined ? { households } : { households, access };
  const context: RulesTestContext = (await rulesEnvironment()).authenticatedContext(uid, claims);
  return context.storage();
}

/** Storage as a signed-in account with no household claim at all. */
export async function storageAsStranger(uid: string): Promise<FirebaseStorage> {
  const context: RulesTestContext = (await rulesEnvironment()).authenticatedContext(uid);
  return context.storage();
}

/** Storage as nobody: no token at all. */
export async function storageAsSignedOut(): Promise<FirebaseStorage> {
  const context: RulesTestContext = (await rulesEnvironment()).unauthenticatedContext();
  return context.storage();
}

/**
 * Writes the setup a test needs with the rules switched off, so a test never
 * has to be allowed to do something in order to check that it is denied.
 */
export async function givenData(seed: (db: Firestore) => Promise<void>): Promise<void> {
  await (
    await rulesEnvironment()
  ).withSecurityRulesDisabled(async (context) => {
    await seed(context.firestore() as unknown as Firestore);
  });
}
