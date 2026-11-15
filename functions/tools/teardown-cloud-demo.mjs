#!/usr/bin/env node
/**
 * Removes exactly what `seed-cloud-demo.mjs` made (foundation ADR-0019), and
 * nothing else:
 *
 * - the demo household document and everything under it;
 * - its files in Storage (`households/<demo id>/…`) and the demo accounts'
 *   exports (`accountExports/<demo uid>/…`);
 * - the demo accounts — only where the address is still the cast's — and
 *   their `users/` documents;
 * - the rows the Functions derived about the demo household at top level
 *   (analytics, invites, codes), found by `householdId ==` the demo id.
 *
 * `appConfig/flags` stays: it is the project's switchboard, not demo data.
 * Every id is checked to start with `demo-` before anything is read.
 *
 *     npm run teardown:cloud-demo                (dry run: says what it would remove)
 *     npm run teardown:cloud-demo -- --confirm   (removes it)
 *
 * `--free` removes the free demo family of `seed-cloud-free-demo.mjs` instead,
 * the same way, with every id checked to start with `free-`.
 */
import { CLOUD_CAST } from './cloud-demo/cast.mjs';
import { assertScope, connect } from './cloud-demo/admin.mjs';
import { FREE_CAST, FREE_PREFIX } from './cloud-demo/free-cast.mjs';

const confirmed = process.argv.includes('--confirm');
const free = process.argv.includes('--free');
const cast = free ? FREE_CAST : CLOUD_CAST;
assertScope(cast, free ? FREE_PREFIX : 'demo-');
const { target, store, auth, bucket } = connect();
const householdId = cast.householdId;
console.log(
  `${confirmed ? 'removing' : 'dry run — would remove'} the ${free ? 'free ' : ''}demo family from ${target}\n`,
);

/** Top-level collections whose rows about a household carry its id. */
const DERIVED = [
  'analyticsHouseholdWeeks',
  'analyticsConversions',
  'invites',
  'kidPairings',
  'referralCodes',
  'documentShareTokens',
  'calendarFeeds',
  'coParentInvites',
];

const household = store.collection('households').doc(householdId);
const subcollections = await household.listCollections();
console.log(
  `household ${householdId}: ${(await household.get()).exists ? 'present' : 'absent'}, ${String(subcollections.length)} collections under it`,
);
if (confirmed) await store.recursiveDelete(household);

const prefixes = [
  `households/${householdId}/`,
  ...cast.people.map((person) => `accountExports/${person.uid}/`),
];
for (const prefix of prefixes) {
  const [files] = await bucket.getFiles({ prefix });
  console.log(`storage ${prefix}: ${String(files.length)} files`);
  if (confirmed && files.length > 0) await bucket.deleteFiles({ prefix });
}

const cohort = store.collection('analyticsHouseholds').doc(householdId);
if ((await cohort.get()).exists) {
  console.log(`analyticsHouseholds/${householdId}`);
  if (confirmed) await cohort.delete();
}
for (const name of DERIVED) {
  const rows = await store.collection(name).where('householdId', '==', householdId).get();
  if (rows.empty) continue;
  console.log(`${name}: ${String(rows.size)} rows about ${householdId}`);
  if (confirmed) for (const row of rows.docs) await row.ref.delete();
}

for (const { uid, email } of cast.people) {
  const userDoc = store.collection('users').doc(uid);
  console.log(`users/${uid}: ${(await userDoc.get()).exists ? 'present' : 'absent'}`);
  if (confirmed) await store.recursiveDelete(userDoc);
  const account = await auth.getUser(uid).catch((error) => {
    if (error?.code === 'auth/user-not-found') return null;
    throw error;
  });
  if (account === null) continue;
  if (account.email !== email) {
    console.log(`account ${uid} now has another address; left alone`);
    continue;
  }
  console.log(`account ${email} (${uid})`);
  if (confirmed) await auth.deleteUser(uid);
}
console.log(confirmed ? '\ndone' : '\nnothing removed — pass --confirm to remove it');
