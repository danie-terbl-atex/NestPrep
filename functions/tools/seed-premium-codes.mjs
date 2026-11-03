#!/usr/bin/env node
import { randomBytes } from 'node:crypto';
import { existsSync, unlinkSync, writeFileSync } from 'node:fs';
import { userInfo } from 'node:os';
import { resolve } from 'node:path';
import { parseArgs } from 'node:util';

import { initializeApp } from 'firebase-admin/app';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';

const REAL_PROJECT = 'nestprep-643b7';
const UNIQUE_LENGTH = 12;
const MAX_UNIQUE = 5000;
const BATCH_SIZE = 400;

const { values } = parseArgs({
  options: {
    shared: { type: 'string' },
    unique: { type: 'string' },
    out: { type: 'string' },
    label: { type: 'string' },
    days: { type: 'string' },
    'max-claims': { type: 'string' },
    from: { type: 'string' },
    until: { type: 'string' },
    eligibility: { type: 'string', default: 'newToPremium' },
    partner: { type: 'string' },
    test: { type: 'boolean', default: false },
    by: { type: 'string' },
    project: { type: 'string' },
    yes: { type: 'boolean', default: false },
  },
});

function refuse(message) {
  console.error(message);
  process.exit(2);
}

const real = values.project !== undefined;
if (real && (values.project !== REAL_PROJECT || !values.yes)) {
  refuse(`the real project needs exactly --project ${REAL_PROJECT} --yes`);
}
if (real && process.env.FIRESTORE_EMULATOR_HOST !== undefined) {
  refuse('FIRESTORE_EMULATOR_HOST is set: unset it for the real project, or drop --project');
}
if (!real) process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
process.env.GCLOUD_PROJECT ??= REAL_PROJECT;

const { EMULATOR_PEPPER } = await import('../lib/premium_vouchers/premium_config.js');
const { codeHashOf, normCode } = await import('../lib/premium_vouchers/premium_hashes.js');
const { PREMIUM_CODES } = await import('../lib/premium_vouchers/voucher_documents.js');
const { generateReadableCode } = await import('../lib/shared/readable_code.js');

const pepper = real ? (process.env.PREMIUM_EMAIL_PEPPER ?? '').trim() : EMULATOR_PEPPER;
if (pepper === '' || pepper === 'unset') refuse('PREMIUM_EMAIL_PEPPER is not set');

if ((values.shared === undefined) === (values.unique === undefined)) {
  refuse('give exactly one of --shared <CODE> or --unique <count> --out <file.csv>');
}
const label = (values.label ?? '').trim();
if (label === '' || label.length > 80) refuse('--label is required, at most 80 characters');
const days = wholeNumber(values.days, '--days', 1, 3650);
const maxClaims =
  values['max-claims'] === undefined
    ? null
    : wholeNumber(values['max-claims'], '--max-claims', 1, 1_000_000);
if (!['any', 'newToPremium'].includes(values.eligibility)) {
  refuse('--eligibility is any or newToPremium');
}
const validFrom = values.from === undefined ? new Date() : sastInstant(values.from, '00:00:00.000');
const validUntil = values.until === undefined ? null : sastInstant(values.until, '23:59:59.999');
if (validUntil !== null && validUntil <= validFrom) refuse('--until must be after --from');
const partnerId = values.partner?.trim();
if (partnerId === '') refuse('--partner needs an id');

function wholeNumber(raw, name, min, max) {
  const value = Number(raw);
  if (!Number.isInteger(value) || value < min || value > max) {
    refuse(`${name} must be a whole number from ${String(min)} to ${String(max)}`);
  }
  return value;
}

function sastInstant(day, time) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(day)) refuse(`${day} is not a YYYY-MM-DD date`);
  const instant = new Date(`${day}T${time}+02:00`);
  if (Number.isNaN(instant.getTime())) refuse(`${day} is not a date`);
  return instant;
}

const store = getFirestore(initializeApp({ projectId: REAL_PROJECT }));
const now = Timestamp.now();
const base = {
  label,
  days,
  claimCount: 0,
  validFrom: Timestamp.fromDate(validFrom),
  validUntil: validUntil === null ? null : Timestamp.fromDate(validUntil),
  status: 'active',
  eligibility: values.eligibility,
  attribution: partnerId === undefined ? null : { partnerId },
  isTest: values.test,
  createdAt: now,
  createdBy: values.by ?? userInfo().username,
};
const target = real
  ? `project ${REAL_PROJECT}`
  : `the emulator at ${process.env.FIRESTORE_EMULATOR_HOST}`;

if (values.shared !== undefined) {
  const code = normCode(values.shared);
  if (code === null) refuse('a code is 4 to 20 letters and numbers');
  const ref = store.collection(PREMIUM_CODES).doc(await codeHashOf(pepper, code));
  const batch = store.batch();
  batch.create(ref, { ...base, shape: 'shared', display: code, batchId: null, maxClaims });
  try {
    await batch.commit();
  } catch (error) {
    refuse(`not created: ${error.code === 6 ? 'that code already exists' : error.message}`);
  }
  console.log(`one shared code created in ${target} (${label}, ${String(days)} days)`);
} else {
  const count = wholeNumber(values.unique, '--unique', 1, MAX_UNIQUE);
  if (values.out === undefined) refuse('--unique needs --out <file.csv> for the plain codes');
  const out = resolve(values.out);
  if (existsSync(out)) refuse(`${out} already exists; choose a new file`);

  const codes = new Set();
  while (codes.size < count) codes.add(generateReadableCode(UNIQUE_LENGTH));
  const batchId = `batch-${new Date().toISOString().slice(0, 10)}-${randomBytes(3).toString('hex')}`;
  const formatted = [...codes].map((code) => code.match(/.{4}/g).join('-'));
  const rows = formatted.map(
    (code) => `${code},${batchId},"${label.replaceAll('"', '""')}",${String(days)}`,
  );
  writeFileSync(out, `code,batchId,label,days\n${rows.join('\n')}\n`, { flag: 'wx', mode: 0o600 });

  let written = 0;
  try {
    const all = [...codes];
    for (let start = 0; start < all.length; start += BATCH_SIZE) {
      const batch = store.batch();
      for (const code of all.slice(start, start + BATCH_SIZE)) {
        batch.create(store.collection(PREMIUM_CODES).doc(await codeHashOf(pepper, code)), {
          ...base,
          shape: 'unique',
          display: null,
          batchId,
          maxClaims: maxClaims ?? 1,
        });
      }
      await batch.commit();
      written += Math.min(BATCH_SIZE, all.length - start);
    }
  } catch (error) {
    unlinkSync(out);
    refuse(
      `stopped after ${String(written)} of ${String(count)} codes (${error.message}); ` +
        `the CSV was removed, and the written codes of ${batchId} should be archived`,
    );
  }
  console.log(
    `${String(count)} unique codes created in ${target} as ${batchId}; plain codes in ${out}`,
  );
}
