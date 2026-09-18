import { beforeEach, describe, expect, it } from 'vitest';

import {
  CallFailed,
  adminAuth,
  adminDb,
  callAs,
  clearFirestore,
  signUp,
  type TestUser,
} from './emulator_harness';

/**
 * The two documents callables, driven the way the app drives them — over HTTP,
 * with a real ID token (BE-14).
 *
 * They exist for the two things Security Rules cannot do (foundation
 * ADR-0002): put household membership somewhere Storage rules can see it, and
 * count what is still in a folder before deleting it.
 */

interface CreatedHousehold {
  householdId: string;
  memberId: string;
}

async function createHousehold(user: TestUser, name = 'The Parkers'): Promise<CreatedHousehold> {
  return callAs<CreatedHousehold>(user, 'createHousehold', {
    name,
    timeZone: 'Africa/Johannesburg',
    adminDisplayName: 'Sam Parent',
    adminColor: 'violet',
  });
}

async function addFolder(householdId: string, name = 'School'): Promise<string> {
  const ref = adminDb()
    .collection('households')
    .doc(householdId)
    .collection('documentFolders')
    .doc();
  await ref.set({ name, createdBy: 'm-anyone', createdAt: new Date() });
  return ref.id;
}

async function addDocument(householdId: string, folderId: string): Promise<string> {
  const ref = adminDb().collection('households').doc(householdId).collection('documents').doc();
  await ref.set({
    folderId,
    name: 'Term letter',
    contentType: 'application/pdf',
    sizeBytes: 120_000,
    uploadedBy: 'm-anyone',
    uploadedAt: new Date(),
  });
  return ref.id;
}

async function claimsOf(user: TestUser): Promise<Record<string, unknown>> {
  const record = await adminAuth().getUser(user.uid);
  return record.customClaims ?? {};
}

async function expectRefusal(promise: Promise<unknown>, reason: string): Promise<void> {
  await expect(promise).rejects.toThrow(CallFailed);
  await promise.catch((error: unknown) => {
    expect(error instanceof CallFailed ? error.reason : undefined).toBe(reason);
  });
}

describe('syncDocumentAccess', () => {
  beforeEach(clearFirestore);

  it('puts the caller"s households and roles on their own token', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);

    await callAs(sam, 'syncDocumentAccess', {});

    expect((await claimsOf(sam))['households']).toEqual({ [householdId]: 'admin' });
  });

  it('gives an account in no household an empty claim rather than no claim', async () => {
    // "No households" is an answer, and it is the one that takes Storage access
    // away again. Leaving the old claim in place would be the bug.
    const nobody = await signUp();

    await callAs(nobody, 'syncDocumentAccess', {});

    expect((await claimsOf(nobody))['households']).toEqual({});
  });

  it('carries every household an account belongs to', async () => {
    const sam = await signUp();
    const first = await createHousehold(sam, 'The Parkers');
    const second = await createHousehold(sam, 'The Other House');

    await callAs(sam, 'syncDocumentAccess', {});

    expect((await claimsOf(sam))['households']).toEqual({
      [first.householdId]: 'admin',
      [second.householdId]: 'admin',
    });
  });

  it('drops a household the account has been removed from', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    await callAs(sam, 'syncDocumentAccess', {});
    expect((await claimsOf(sam))['households']).toEqual({ [householdId]: 'admin' });

    await callAs(sam, 'leaveHousehold', { householdId }).catch(() => undefined);
    // The last admin cannot leave, so take the membership away the way a
    // removal does and prove the next sync notices.
    await adminDb()
      .collection('users')
      .doc(sam.uid)
      .set({ householdIds: [], activeHouseholdId: null }, { merge: true });

    await callAs(sam, 'syncDocumentAccess', {});

    expect((await claimsOf(sam))['households']).toEqual({});
  });

  it('believes the household document, not the account"s list of them', async () => {
    // The list is an index; the uid→role map is the truth every Firestore rule
    // reads. A list that disagrees must not become Storage access (BE-03).
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    await adminDb()
      .collection('users')
      .doc(sam.uid)
      .set({ householdIds: [householdId, 'h-invented'] }, { merge: true });

    await callAs(sam, 'syncDocumentAccess', {});

    expect((await claimsOf(sam))['households']).toEqual({ [householdId]: 'admin' });
  });

  it('refuses a call with no token at all', async () => {
    await expectRefusal(callAs(null, 'syncDocumentAccess', {}), 'notSignedIn');
  });

  it('is safe to call twice', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);

    await callAs(sam, 'syncDocumentAccess', {});
    await callAs(sam, 'syncDocumentAccess', {});

    expect((await claimsOf(sam))['households']).toEqual({ [householdId]: 'admin' });
  });
});

describe('deleteDocumentFolder', () => {
  beforeEach(clearFirestore);

  it('deletes a folder that holds nothing', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    const folderId = await addFolder(householdId);

    await callAs(sam, 'deleteDocumentFolder', { householdId, folderId });

    const folder = await adminDb()
      .collection('households')
      .doc(householdId)
      .collection('documentFolders')
      .doc(folderId)
      .get();
    expect(folder.exists).toBe(false);
  });

  it('refuses a folder that still holds a document, and leaves both alone', async () => {
    // This is the whole reason the callable exists: a rule cannot count a
    // collection, and a folder deleted out from under its documents leaves
    // bytes nobody can see and nobody stops paying for (documents ADR-0001).
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    const folderId = await addFolder(householdId);
    const documentId = await addDocument(householdId, folderId);

    await expectRefusal(
      callAs(sam, 'deleteDocumentFolder', { householdId, folderId }),
      'folderNotEmpty',
    );

    const household = adminDb().collection('households').doc(householdId);
    expect((await household.collection('documentFolders').doc(folderId).get()).exists).toBe(true);
    expect((await household.collection('documents').doc(documentId).get()).exists).toBe(true);
  });

  it('refuses a folder that is not there', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);

    await expectRefusal(
      callAs(sam, 'deleteDocumentFolder', { householdId, folderId: 'never-existed' }),
      'folderNotFound',
    );
  });

  it('refuses somebody who is not in the household', async () => {
    const sam = await signUp();
    const stranger = await signUp();
    const { householdId } = await createHousehold(sam);
    const folderId = await addFolder(householdId);

    await expectRefusal(
      callAs(stranger, 'deleteDocumentFolder', { householdId, folderId }),
      'notAMember',
    );
  });

  it('refuses a member who is not an admin', async () => {
    const sam = await signUp();
    const helper = await signUp();
    const { householdId } = await createHousehold(sam);
    const folderId = await addFolder(householdId);
    await adminDb()
      .collection('households')
      .doc(householdId)
      .set({ members: { [sam.uid]: 'admin', [helper.uid]: 'helper' } }, { merge: true });

    await expectRefusal(
      callAs(helper, 'deleteDocumentFolder', { householdId, folderId }),
      'notAnAdmin',
    );
  });

  it('refuses a household that does not exist, without saying it does not', async () => {
    const sam = await signUp();

    await expectRefusal(
      callAs(sam, 'deleteDocumentFolder', { householdId: 'h-invented', folderId: 'f1' }),
      'notAMember',
    );
  });

  it('refuses a call with no token at all', async () => {
    await expectRefusal(
      callAs(null, 'deleteDocumentFolder', { householdId: 'h1', folderId: 'f1' }),
      'notSignedIn',
    );
  });
});
