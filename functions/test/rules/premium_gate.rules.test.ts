import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { Timestamp, doc, setDoc, type Firestore } from 'firebase/firestore';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

import { FIRESTORE_AT } from './rules_harness';

/**
 * `hasPremium(householdId)` — the one line a premium feature adds to its
 * rules (subscriptions ADR-0001). Lunch-box's learning loop and prep list are
 * its first callers and are not built yet, so the helper is exercised here
 * exactly as written in `rules/firestore/shared/entitlement.rules`, behind a
 * probe collection whose only rule is the helper. It runs under a project id
 * of its own, so the probe never exists in the app's rules.
 */
const PROBE_PROJECT = 'nestprep-premium-probe';
const PARTIAL = resolve(import.meta.dirname, '../../../rules/firestore/shared/entitlement.rules');
const HOUSEHOLD = 'h1';
const ENTITLEMENT = `households/${HOUSEHOLD}/entitlement/current`;
const PROBE = `households/${HOUSEHOLD}/premiumProbe/p1`;

function probeRules(): string {
  return `rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
${readFileSync(PARTIAL, 'utf8')}
    match /households/{householdId}/premiumProbe/{id} {
      allow write: if hasPremium(householdId);
    }
  }
}
`;
}

let environment: RulesTestEnvironment;

beforeAll(async () => {
  environment = await initializeTestEnvironment({
    projectId: PROBE_PROJECT,
    firestore: { rules: probeRules(), ...FIRESTORE_AT },
  });
});

afterAll(async () => {
  await environment.cleanup();
});

async function givenEntitlement(fields: Record<string, unknown> | null): Promise<void> {
  await environment.withSecurityRulesDisabled(async (context) => {
    if (fields !== null) {
      await setDoc(doc(context.firestore() as unknown as Firestore, ENTITLEMENT), fields);
    }
  });
}

async function probeWrite(): Promise<void> {
  const db = environment.authenticatedContext('uid-sam').firestore() as unknown as Firestore;
  await setDoc(doc(db, PROBE), { at: 1 });
}

const DAY = 24 * 60 * 60 * 1000;

describe('hasPremium', () => {
  beforeEach(async () => {
    await environment.clearFirestore();
  });

  it('holds while premiumUntil is still ahead of the request', async () => {
    await givenEntitlement({ premiumUntil: Timestamp.fromMillis(Date.now() + DAY) });
    await assertSucceeds(probeWrite());
  });

  it('does not hold once premiumUntil has passed — a lapse needs no job', async () => {
    await givenEntitlement({ premiumUntil: Timestamp.fromMillis(Date.now() - 60_000) });
    await assertFails(probeWrite());
  });

  it('does not hold for a household that never had premium', async () => {
    await givenEntitlement(null);
    await assertFails(probeWrite());
  });

  it('does not hold when premiumUntil is null, missing or not a time', async () => {
    for (const fields of [
      { premiumUntil: null, status: 'expired' },
      { status: 'active' },
      { premiumUntil: '2099-01-01T00:00:00Z' },
      { premiumUntil: Date.now() + DAY },
    ]) {
      await environment.clearFirestore();
      await givenEntitlement(fields);
      await assertFails(probeWrite());
    }
  });
});
