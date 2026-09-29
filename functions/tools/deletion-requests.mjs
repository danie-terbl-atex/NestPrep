#!/usr/bin/env node
/**
 * Deals with the account-deletion requests made on the public web page, for
 * people who no longer have the app (accounts ADR-0006; Google Play's
 * data-deletion URL).
 *
 *     npm run build
 *     npm run deletion-requests                                  # list what is open
 *     npm run deletion-requests -- --erase <requestId> --confirm # erase that account
 *     npm run deletion-requests -- --close <requestId>           # nothing to erase; forget it
 *
 * **Before `--erase`, confirm by email that the address is the person's** —
 * reply from the privacy address and wait for their answer. The form is open
 * to anybody, so a request alone proves nothing. `--erase` then runs the very
 * erasure the app's Delete my account runs: households handed over or ended
 * exactly as the in-app preview would have said, which this tool prints first.
 * The request, which is the only place the address was kept, is deleted when
 * the account is; `accountDeletions/{uid}` records that it was honoured.
 *
 * Against the real project it uses your Google application-default credentials
 * (`gcloud auth application-default login`). Against the emulator set
 * `FIRESTORE_EMULATOR_HOST`, `FIREBASE_AUTH_EMULATOR_HOST` and
 * `FIREBASE_STORAGE_EMULATOR_HOST`. `NESTPREP_PROJECT` overrides the project id.
 */
import { parseArgs } from 'node:util';

import { initializeApp } from 'firebase-admin/app';

const PROJECT = process.env.NESTPREP_PROJECT ?? 'nestprep-643b7';
process.env.GCLOUD_PROJECT ??= PROJECT;
initializeApp({ projectId: PROJECT });

const { accountAuth } = await import('../lib/account_data/account_auth.js');
const { readDeletionPlan } = await import('../lib/account_data/deletion_plan.js');
const { ACCOUNT_DELETION_REQUESTS } = await import('../lib/account_data/deletion_requests.js');
const { eraseAccount, liveErasureDeps } = await import('../lib/account_data/erase_account.js');
const { db } = await import('../lib/shared/firestore.js');

const { values } = parseArgs({
  options: {
    erase: { type: 'string' },
    close: { type: 'string' },
    confirm: { type: 'boolean', default: false },
  },
});

const store = db();
const requests = store.collection(ACCOUNT_DELETION_REQUESTS);

async function describe(email) {
  const uid = await accountAuth().uidForEmail(email);
  if (uid === null) return { uid, plan: null };
  return { uid, plan: await readDeletionPlan(store, uid, new Date()) };
}

function summarise(plan) {
  if (plan === null) return 'no account with this address';
  if (plan.households.length === 0) return 'an account in no household';
  return plan.households.map((h) => `${h.name}: ${h.outcome.kind}`).join('; ');
}

if (values.close !== undefined) {
  const batch = store.batch();
  batch.delete(requests.doc(values.close));
  await batch.commit();
  console.log(`closed request ${values.close}; nothing was erased`);
} else if (values.erase !== undefined) {
  const request = await requests.doc(values.erase).get();
  const email = request.get('email');
  if (!request.exists || typeof email !== 'string') {
    console.error(`no open request ${values.erase}`);
    process.exit(2);
  }
  const { uid, plan } = await describe(email);
  console.log(`request ${values.erase}: ${summarise(plan)}`);
  if (uid === null) {
    console.error('nothing to erase — close the request instead, once you have told them');
    process.exit(2);
  }
  if (!values.confirm) {
    console.log('re-run with --confirm to erase, once the address is confirmed as theirs');
    process.exit(0);
  }
  const summary = await eraseAccount(liveErasureDeps(), { uid, via: 'webRequest' });
  const batch = store.batch();
  batch.delete(requests.doc(values.erase));
  await batch.commit();
  console.log(`erased account ${uid}:`, summary);
} else {
  const open = await requests.where('status', '==', 'open').limit(100).get();
  if (open.empty) console.log('no open deletion requests');
  for (const request of open.docs) {
    const { plan } = await describe(request.get('email'));
    const at = request.get('requestedAt')?.toDate().toISOString() ?? '?';
    console.log(`${request.id}  ${at}  ${request.get('email')}  — ${summarise(plan)}`);
  }
}
