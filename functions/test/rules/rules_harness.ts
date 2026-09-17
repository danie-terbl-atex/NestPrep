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

export { assertFails, assertSucceeds };
export type { Firestore };

const PROJECT_ID = 'nestprep-643b7';
const RULES_PATH = resolve(import.meta.dirname, '../../../firestore.rules');

let environment: RulesTestEnvironment | undefined;

/**
 * The one Firestore emulator instance every rules test shares. Starting it per
 * file would cost more than the tests do.
 */
export async function rulesEnvironment(): Promise<RulesTestEnvironment> {
  environment ??= await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: readFileSync(RULES_PATH, 'utf8'), host: '127.0.0.1', port: 8080 },
  });
  return environment;
}

export async function clearData(): Promise<void> {
  await (await rulesEnvironment()).clearFirestore();
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

/** Firestore as nobody sees it: no token at all. */
export async function asSignedOut(): Promise<Firestore> {
  const context: RulesTestContext = (await rulesEnvironment()).unauthenticatedContext();
  return context.firestore() as unknown as Firestore;
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
