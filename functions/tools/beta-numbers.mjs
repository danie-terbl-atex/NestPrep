#!/usr/bin/env node
/**
 * Prints the beta numbers, one row per week, newest first (product-analytics
 * ADR-0001). The same totals the Beta numbers screen shows.
 *
 *     npm run build                                  # this reads lib/, not src/
 *     npm run beta-numbers                           # the last 12 weeks
 *     npm run beta-numbers -- --weeks 26
 *     npm run beta-numbers -- --recount              # recount the last three weeks first
 *
 * Against the real project it uses your Google application-default credentials
 * (`gcloud auth application-default login`) and needs Firestore read access —
 * `--recount` also needs write. Against the emulator, set
 * `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080` first; nothing then reaches the cloud.
 *
 * It prints counts only. There is no household, member or person in any of it.
 */
import { parseArgs } from 'node:util';

import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

import { WEEKLY_TOTALS } from '../lib/product_analytics/analytics_documents.js';
import { readoutTable, storedWeeklyTotals } from '../lib/product_analytics/beta_numbers_readout.js';
import { rollupWeek, weeksToRollUp } from '../lib/product_analytics/weekly_rollup.js';

const PROJECT = process.env.NESTPREP_PROJECT ?? 'nestprep-643b7';

const { values } = parseArgs({
  options: {
    weeks: { type: 'string', default: '12' },
    recount: { type: 'boolean', default: false },
  },
});
const weeks = Number.parseInt(values.weeks, 10);
if (!Number.isInteger(weeks) || weeks < 1 || weeks > 104) {
  console.error('--weeks must be a whole number from 1 to 104');
  process.exit(2);
}

const store = getFirestore(initializeApp({ projectId: PROJECT }));

if (values.recount) {
  const now = new Date();
  for (const week of weeksToRollUp(now)) await rollupWeek(store, week, now);
  console.error(`recounted ${weeksToRollUp(now).join(', ')}\n`);
}

// By the `week` field rather than the document id, though they are the same
// string: Firestore will not scan document ids in descending order.
const snapshot = await store.collection(WEEKLY_TOTALS).orderBy('week', 'desc').limit(weeks).get();

const rows = [];
for (const document of snapshot.docs) {
  const parsed = storedWeeklyTotals.safeParse(document.data());
  if (parsed.success) rows.push(parsed.data);
  else console.error(`skipped ${document.id}: not a weekly totals document`);
}

console.log(readoutTable(rows));
