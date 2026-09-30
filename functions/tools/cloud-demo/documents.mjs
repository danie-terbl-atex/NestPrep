/**
 * Documents (documents ADR-0001 onward): household folders with a few small
 * generated files in Storage, and personal vaults — one passport expiring
 * soon — with the nanny granted Sipho's and Zoë's. Every file is made here,
 * stamped DEMO, and stored where the app looks for it with the uploader's
 * uid in its metadata, as the Storage rules require.
 */
import { createHash } from 'node:crypto';

import { addDays, writeAll } from './context.mjs';
import { WHO, uidOf } from './cast.mjs';
import { cardPicture, pdfDocument } from './placeholder-files.mjs';

const { mom, dad, gran, nanny, lerato, sipho, zoe } = WHO;

const FOLDERS = [
  ['insurance', 'Insurance'],
  ['house', 'House'],
  ['school', 'School'],
  ['medical', 'Medical'],
  ['cars', 'Cars'],
];

const TEAL = [38, 128, 120];
const PLUM = [120, 70, 120];
const AMBER = [214, 150, 40];

/** [id, folder, name, kind, tags, expires in days (null for never), uploadedBy, lines or band] */
const HOUSEHOLD = [
  [
    'home-insurance',
    'insurance',
    'Home insurance schedule 2026',
    'pdf',
    ['insurance', 'house'],
    150,
    mom,
    [
      'Policy DEMO-HOME-0001',
      'Buildings and contents, 12 Oak Street',
      'Excess R2 500',
      'Renews every March',
    ],
  ],
  [
    'car-insurance',
    'insurance',
    'Car insurance — Polo',
    'pdf',
    ['insurance', 'car'],
    62,
    dad,
    ['Policy DEMO-CAR-0002', 'Comprehensive cover', 'Tracker fitted'],
  ],
  [
    'lease',
    'house',
    'Lease — 12 Oak Street',
    'pdf',
    ['lease'],
    240,
    mom,
    ['A made-up lease for the demo household', 'Twelve months, renewable', 'Deposit held in trust'],
  ],
  [
    'geyser',
    'house',
    'Geyser guarantee',
    'pdf',
    ['house'],
    null,
    dad,
    ['150 litre geyser', 'Five-year guarantee', 'Serviced this week'],
  ],
  [
    'planetarium-letter',
    'school',
    'Planetarium tour letter',
    'png',
    ['school', 'Lerato'],
    null,
    mom,
    AMBER,
  ],
  [
    'oakwood-newsletter',
    'school',
    'Oakwood Primary — October newsletter',
    'pdf',
    ['school', 'Sipho'],
    null,
    mom,
    ['Spring term dates', 'Civvies day on Friday', 'Reminder: Oakwood is a nut-free school'],
  ],
  ['licence-disc', 'cars', 'Licence disc — Polo', 'png', ['car'], 9, dad, TEAL],
  ['zoe-clinic', 'medical', 'Zoë — immunisation record', 'png', ['Zoë'], null, mom, PLUM],
];

/** [id, owner, name, kind, tags, expires in days, uploadedBy, lines or band] */
const VAULT = [
  ['passport-naledi', mom, 'Passport', 'png', ['ID'], 12, mom, TEAL],
  ['licence-naledi', mom, "Driver's licence", 'png', ['ID'], 900, mom, AMBER],
  ['licence-pieter', dad, "Driver's licence", 'png', ['ID'], 420, dad, AMBER],
  [
    'medical-aid-pieter',
    dad,
    'Medical aid card',
    'pdf',
    ['medical'],
    null,
    dad,
    ['Oak Medical Aid (demo)', 'Member DEMO-0001', 'Dependants: 4'],
  ],
  [
    'pension-elsa',
    gran,
    'Pension letter',
    'pdf',
    [],
    null,
    gran,
    ['A made-up pension letter', 'For the demo only'],
  ],
  [
    'birth-lerato',
    lerato,
    'Birth certificate',
    'pdf',
    ['ID'],
    null,
    mom,
    ['Unabridged birth certificate (demo)', 'Lerato Botha'],
  ],
  [
    'epipen-sipho',
    sipho,
    'EpiPen prescription',
    'pdf',
    ['medical', 'allergy'],
    40,
    mom,
    ['EpiPen Jr 0.15 mg', 'Severe peanut allergy', 'Dr Pillay (demo)'],
  ],
  ['rth-zoe', zoe, 'Road-to-health booklet', 'png', ['medical'], null, mom, PLUM],
];

/** Vaults the nanny may read: the two she might need at the clinic or school. */
const GRANTS = [sipho, zoe];

function fileFor(kind, name, content) {
  if (kind === 'pdf') return { bytes: pdfDocument(name, content), contentType: 'application/pdf' };
  return { bytes: cardPicture(480, 300, content), contentType: 'image/png' };
}

/** The same download token for the same object on every run. */
function tokenFor(path) {
  const hex = createHash('sha256').update(path).digest('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20, 32)}`;
}

async function upload(bucket, path, file, uploadedBy) {
  await bucket.file(path).save(file.bytes, {
    contentType: file.contentType,
    resumable: false,
    metadata: {
      metadata: { uploadedByUid: uidOf(uploadedBy), firebaseStorageDownloadTokens: tokenFor(path) },
    },
  });
}

export async function seedDocuments(ctx) {
  const { day, at, col, cast, bucket, today } = ctx;
  const expiry = (days) => (days === null ? null : addDays(today, days));
  const docs = FOLDERS.map(([id, name]) => [
    col('documentFolders').doc(`demo-${id}`),
    { name, createdBy: mom, createdAt: at(day(-40), '20:00') },
  ]);

  for (const [id, folder, name, kind, tags, expires, by, content] of HOUSEHOLD) {
    const documentId = `demo-${id}`;
    const file = fileFor(kind, name, content);
    await upload(bucket, `households/${cast.householdId}/documents/${documentId}`, file, by);
    docs.push([
      col('documents').doc(documentId),
      {
        folderId: `demo-${folder}`,
        name,
        contentType: file.contentType,
        sizeBytes: file.bytes.length,
        uploadedBy: by,
        uploadedAt: at(day(-12), '21:00'),
        tags,
        expiresOn: expiry(expires),
      },
    ]);
  }

  for (const [id, owner, name, kind, tags, expires, by, content] of VAULT) {
    const documentId = `demo-${id}`;
    const file = fileFor(kind, name, content);
    await upload(bucket, `households/${cast.householdId}/vaults/${owner}/${documentId}`, file, by);
    docs.push([
      col('vaults').doc(owner).collection('vaultDocuments').doc(documentId),
      {
        name,
        contentType: file.contentType,
        sizeBytes: file.bytes.length,
        uploadedBy: by,
        uploadedAt: at(day(-15), '21:30'),
        tags,
        expiresOn: expiry(expires),
      },
    ]);
  }
  for (const owner of GRANTS) {
    docs.push([
      col('vaults').doc(owner).collection('grants').doc(uidOf(nanny)),
      { memberId: nanny, grantedBy: mom, grantedAt: at(day(-10), '19:00') },
    ]);
  }
  docs.push([
    col('vaults').doc(mom).collection('views').doc('demo-view-passport'),
    {
      documentId: 'demo-passport-naledi',
      documentName: 'Passport',
      viewerMemberId: dad,
      viewerRole: 'parent',
      viewedAt: at(day(-1), '08:15'),
    },
  ]);

  await writeAll(ctx.store, docs);
  return `documents: ${String(FOLDERS.length)} folders, ${String(HOUSEHOLD.length)} household files and ${String(VAULT.length)} vault files in Storage, ${String(GRANTS.length)} vault grants`;
}
