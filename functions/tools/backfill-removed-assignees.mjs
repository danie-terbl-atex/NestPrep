#!/usr/bin/env node
/**
 * Takes profiles that are no longer in their household off every task and
 * routine still assigned to them, once, for what was removed before
 * `removeMember` did it itself (todos ADR-0008).
 *
 *     npm run build
 *     npm run backfill:removed-assignees                 # dry run: what would change
 *     npm run backfill:removed-assignees -- --confirm    # write them
 *
 * Safe to run again. Prints counts only, never a household's id or name.
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
const { ASSIGNEE_FIELDS } = await import('../lib/chore_points/forget_assignee.js');
const { db } = await import('../lib/shared/firestore.js');

const { values } = parseArgs({ options: { confirm: { type: 'boolean', default: false } } });

const store = db();
const households = await store.collection(HOUSEHOLDS).select().get();
const tally = { households: households.size, affected: 0, documents: 0, ids: 0 };

for (const household of households.docs) {
  const members = await household.ref.collection(MEMBERS).select().get();
  const present = new Set(members.docs.map((member) => member.id));
  let affected = false;
  for (const [collection, field] of ASSIGNEE_FIELDS) {
    const docs = await household.ref.collection(collection).select(field).get();
    let batch = store.batch();
    let pending = 0;
    for (const doc of docs.docs) {
      const ids = doc.get(field);
      if (!Array.isArray(ids)) continue;
      const kept = ids.filter((id) => present.has(id));
      if (kept.length === ids.length) continue;
      affected = true;
      tally.documents += 1;
      tally.ids += ids.length - kept.length;
      if (!values.confirm) continue;
      batch.update(doc.ref, { [field]: kept });
      pending += 1;
      if (pending === 400) {
        await batch.commit();
        batch = store.batch();
        pending = 0;
      }
    }
    if (pending > 0) await batch.commit();
  }
  if (affected) tally.affected += 1;
}

const target = process.env.FIRESTORE_EMULATOR_HOST ?? `project ${PROJECT}`;
console.log(`${values.confirm ? 'backfilled' : 'dry run against'} ${target}`);
console.log(`households: ${tally.households}`);
console.log(`  with a removed profile still assigned: ${tally.affected}`);
console.log(`  tasks and routines: ${tally.documents}${values.confirm ? ' (cleaned)' : ''}`);
console.log(`  assignments to removed profiles: ${tally.ids}`);
if (!values.confirm) console.log('nothing was written; pass -- --confirm to write');
