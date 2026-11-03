#!/usr/bin/env node
import { parseArgs } from 'node:util';

import { Timestamp } from 'firebase-admin/firestore';

import { PROJECT_OPTIONS, premiumAdmin, refuse } from './premium-admin.mjs';

const { values } = parseArgs({
  options: { voucher: { type: 'string' }, email: { type: 'string' }, ...PROJECT_OPTIONS },
});
if (values.voucher === undefined || values.email === undefined) {
  refuse('usage: npm run premium:repoint-voucher -- --voucher <orderId_n> --email <address>');
}

const { store, pepper, target } = await premiumAdmin(values);
const { emailHashOf, maskEmail, normEmail } =
  await import('../lib/premium_vouchers/premium_hashes.js');
const { storedVoucher, voucherRef } = await import('../lib/premium_vouchers/voucher_documents.js');

const email = normEmail(values.email);
if (email === null) refuse('--email is not an email address');
const emailHash = await emailHashOf(pepper, email);
const emailMasked = maskEmail(email);

const outcome = await store.runTransaction(async (transaction) => {
  const ref = voucherRef(store, values.voucher);
  const snapshot = await transaction.get(ref);
  if (!snapshot.exists) return 'not found';
  const parsed = storedVoucher.safeParse(snapshot.data());
  if (!parsed.success) return 'unreadable';
  if (parsed.data.kind !== 'frame') return 'not a frame voucher';
  if (parsed.data.status !== 'waiting') return `already ${parsed.data.status}`;
  transaction.update(ref, {
    emailHash,
    emailMasked,
    reassignCount: 0,
    reassignedAt: Timestamp.now(),
  });
  return 'repointed';
});

if (outcome !== 'repointed') refuse(`not changed in ${target}: the voucher is ${outcome}`);
console.log(`voucher ${values.voucher} in ${target} now waits for ${emailMasked}, moves reset`);
