import { Timestamp } from 'firebase-admin/firestore';

import {
  adminDb,
  adminStorage,
  callAs,
  httpFunctionUrl,
  signUp,
  type TestUser,
} from './emulator_harness';

/**
 * The Parkers, set up for shared links (documents ADR-0006): Sam the admin,
 * Alex a parent, Thandi a helper with a vault of her own and a grant to read
 * Emma's, Emma a child with no account — and real bytes in Storage for Emma's
 * medical aid card and the household's insurance policy.
 */
export interface SharingParkers {
  readonly householdId: string;
  readonly sam: TestUser;
  readonly alex: TestUser;
  readonly thandi: TestUser;
}

export const CARD_BYTES = Buffer.from('%PDF-1.4 the medical aid card');
export const POLICY_BYTES = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3, 4]);

export async function givenSharingParkers(): Promise<SharingParkers> {
  const [sam, alex, thandi] = await Promise.all([signUp(), signUp(), signUp()]);
  const household = adminDb().collection('households').doc();
  await household.set({
    name: 'The Parkers',
    timeZone: 'Africa/Johannesburg',
    members: { [sam.uid]: 'admin', [alex.uid]: 'parent', [thandi.uid]: 'helper' },
  });
  for (const [id, role, claimedBy] of [
    ['m-sam', 'admin', sam.uid],
    ['m-alex', 'parent', alex.uid],
    ['m-thandi', 'helper', thandi.uid],
    ['m-emma', 'kid', null],
  ] as const) {
    await household.collection('members').doc(id).set({
      displayName: id,
      color: 'violet',
      role,
      claimedBy,
    });
  }
  await household.collection('vaults').doc('m-emma').collection('grants').doc(thandi.uid).set({
    memberId: 'm-thandi',
    grantedBy: 'm-sam',
    grantedAt: new Date(),
  });
  await household.collection('vaults').doc('m-emma').collection('vaultDocuments').doc('card').set({
    name: 'Emma medical aid card',
    contentType: 'application/pdf',
    sizeBytes: CARD_BYTES.length,
    uploadedBy: 'm-sam',
    uploadedAt: new Date(),
  });
  await household
    .collection('vaults')
    .doc('m-thandi')
    .collection('vaultDocuments')
    .doc('permit')
    .set({
      name: 'Work permit',
      contentType: 'application/pdf',
      sizeBytes: CARD_BYTES.length,
      uploadedBy: 'm-thandi',
      uploadedAt: new Date(),
    });
  await household.collection('documents').doc('policy').set({
    folderId: 'f-insurance',
    name: 'Car insurance',
    contentType: 'image/jpeg',
    sizeBytes: POLICY_BYTES.length,
    uploadedBy: 'm-sam',
    uploadedAt: new Date(),
  });
  const h = `households/${household.id}`;
  await putObject(`${h}/vaults/m-emma/card`, CARD_BYTES, 'application/pdf');
  await putObject(`${h}/vaults/m-thandi/permit`, CARD_BYTES, 'application/pdf');
  await putObject(`${h}/documents/policy`, POLICY_BYTES, 'image/jpeg');
  return { householdId: household.id, sam, alex, thandi };
}

/**
 * Writes the bytes to both names the project's default bucket can have: the
 * emulator's Functions read whichever their `FIREBASE_CONFIG` names, and that
 * depends on whether the CLI could fetch the project's config.
 */
async function putObject(path: string, bytes: Buffer, contentType: string): Promise<void> {
  for (const bucket of ['nestprep-643b7.appspot.com', 'nestprep-643b7.firebasestorage.app']) {
    await adminStorage().bucket(bucket).file(path).save(bytes, { contentType });
  }
}

export interface ShareOptions {
  readonly ownerMemberId?: string | null;
  readonly documentId?: string;
  readonly lifetimeHours?: number | null;
  readonly shiftId?: string | null;
  readonly pin?: string | null;
}

export interface MadeShare {
  readonly shareId: string;
  readonly url: string;
  readonly expiresAt: string;
}

/** Emma's card for a day, unless told otherwise. */
export function share(
  user: TestUser,
  householdId: string,
  options: ShareOptions = {},
): Promise<MadeShare> {
  return callAs<MadeShare>(user, 'createDocumentShare', {
    householdId,
    ownerMemberId: options.ownerMemberId === undefined ? 'm-emma' : options.ownerMemberId,
    documentId: options.documentId ?? 'card',
    lifetimeHours: options.lifetimeHours === undefined ? 24 : options.lifetimeHours,
    shiftId: options.shiftId ?? null,
    pin: options.pin ?? null,
  });
}

/** The token a link carries — the only credential its receiver has. */
export function tokenOf(url: string): string {
  return new URL(url).searchParams.get('t') ?? '';
}

/** What a browser gets for the link, with the query the page adds. */
export function open(token: string, extra = ''): Promise<Response> {
  return fetch(`${httpFunctionUrl('documentShare')}?t=${token}${extra}`);
}

export function submitPin(token: string, pin: string): Promise<Response> {
  return fetch(`${httpFunctionUrl('documentShare')}?t=${token}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ pin }).toString(),
  });
}

/** The file query the page links to, pass and all. */
export function fileQueryIn(html: string): string {
  const match = /(?:src|href)="\?t=[^"&]+&amp;file=1([^"]*)"/.exec(html);
  return `&file=1${(match?.[1] ?? '').replace(/&amp;/g, '&')}`;
}

export async function shareDoc(
  householdId: string,
  shareId: string,
): Promise<Record<string, unknown>> {
  const snapshot = await adminDb().doc(`households/${householdId}/documentShares/${shareId}`).get();
  return snapshot.data() ?? {};
}

export async function expire(householdId: string, shareId: string): Promise<void> {
  await adminDb()
    .doc(`households/${householdId}/documentShares/${shareId}`)
    .update({ expiresAt: Timestamp.fromMillis(Date.now() - 1000) });
}
