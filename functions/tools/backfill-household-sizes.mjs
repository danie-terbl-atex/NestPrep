#!/usr/bin/env node
/**
 * Writes `households/{h}/entitlement/size` for every household that exists,
 * once, after the Functions that keep it are deployed (subscriptions
 * ADR-0008). A household made or changed since then already has it.
 *
 *     npm run build
 *     npm run backfill:household-sizes                 # dry run: what would change
 *     npm run backfill:household-sizes -- --confirm    # write them
 *
 * Safe to run again: each household is counted afresh by the same code the
 * trigger runs. Prints counts only, never a household's id or name.
 *
 * Against the real project it uses your Google application-default credentials
 * (`gcloud auth application-default login`). Against the emulator set
 * `FIRESTORE_EMULATOR_HOST`. `NESTPREP_PROJECT` overrides the project id.
 */
import { parseArgs } from 'node:util';

import { initializeApp } from 'firebase-admin/app';

const PROJECT = process.env.NESTPREP_PROJECT ?? 'nestprep-643b7';
process.env.GCLOUD_PROJECT ??= PROJECT;
initializeApp({ projectId: PROJECT });

const { HOUSEHOLDS, MEMBERS } = await import('../lib/household/documents.js');
const { recountHouseholdSize } = await import('../lib/household/keep_household_size.js');
const { db } = await import('../lib/shared/firestore.js');
const { householdSizeRef } = await import('../lib/subscriptions/subscription_documents.js');

const { values } = parseArgs({ options: { confirm: { type: 'boolean', default: false } } });

const FREE_PEOPLE = 4;
const store = db();
const households = await store.collection(HOUSEHOLDS).select().get();
const tally = { households: households.size, missing: 0, stale: 0, right: 0, overFour: 0 };

for (const household of households.docs) {
  const counted = await household.ref.collection(MEMBERS).count().get();
  const count = counted.data().count;
  const stored = (await householdSizeRef(store, household.id).get()).get('count');
  if (count > FREE_PEOPLE) tally.overFour += 1;
  if (stored === count) {
    tally.right += 1;
    continue;
  }
  if (stored === undefined) tally.missing += 1;
  else tally.stale += 1;
  if (values.confirm) await recountHouseholdSize(store, household.id);
}

const target = process.env.FIRESTORE_EMULATOR_HOST ?? `project ${PROJECT}`;
console.log(`${values.confirm ? 'backfilled' : 'dry run against'} ${target}`);
console.log(`households: ${tally.households}`);
console.log(`  already right: ${tally.right}`);
console.log(`  no size yet: ${tally.missing}${values.confirm ? ' (written)' : ''}`);
console.log(`  wrong size: ${tally.stale}${values.confirm ? ' (rewritten)' : ''}`);
console.log(`  holding more than ${FREE_PEOPLE} people: ${tally.overFour}`);
if (!values.confirm) console.log('nothing was written; pass -- --confirm to write');
