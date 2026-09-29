#!/usr/bin/env node
/**
 * Lets one account read the beta numbers — in the app's Beta numbers screen —
 * by setting the `analyticsReader` custom claim on it (product-analytics
 * ADR-0001). `firestore.rules` is what enforces it; the app only uses it to
 * decide whether to offer the screen.
 *
 *     npm run build
 *     npm run grant-analytics-reader -- you@example.com
 *     npm run grant-analytics-reader -- you@example.com --revoke
 *
 * Against the real project it uses your Google application-default credentials
 * and needs permission to manage Firebase Auth users. Against the emulator, set
 * `FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099` first.
 *
 * Other claims on the account (the `households` claim Storage rules read) are
 * kept: custom claims are written whole, so this merges rather than replaces.
 * The account signs out and in again, or waits up to an hour, before the app
 * sees the change — a token carries the claims it was minted with.
 */
import { parseArgs } from 'node:util';

import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

import { READER_CLAIM } from '../lib/product_analytics/analytics_documents.js';

const PROJECT = process.env.NESTPREP_PROJECT ?? 'nestprep-643b7';

const { values, positionals } = parseArgs({
  allowPositionals: true,
  options: { revoke: { type: 'boolean', default: false } },
});
const [email] = positionals;
if (email === undefined || !email.includes('@')) {
  console.error('usage: npm run grant-analytics-reader -- <email> [--revoke]');
  process.exit(2);
}

const auth = getAuth(initializeApp({ projectId: PROJECT }));
const user = await auth.getUserByEmail(email);
const others = Object.entries(user.customClaims ?? {}).filter(([name]) => name !== READER_CLAIM);
const claims = Object.fromEntries(values.revoke ? others : [...others, [READER_CLAIM, true]]);
await auth.setCustomUserClaims(user.uid, claims);

console.log(`${values.revoke ? 'revoked from' : 'granted to'} account ${user.uid}`);
