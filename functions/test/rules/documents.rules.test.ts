import { deleteDoc, doc, getDoc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

/**
 * The metadata half of the documents feature: what a document *is*, and the
 * folder it is filed in. The bytes are in Cloud Storage and have their own
 * rules and their own suite — `storage.rules.test.ts` — because the two layers
 * answer to different evidence (documents ADR-0001).
 *
 * Folders are admin-managed; a document is added by any member and changed or
 * deleted by its uploader or an admin. Deleting a folder is denied to every
 * client, because a rule cannot count the documents still in it — that is
 * `deleteDocumentFolder`, and the emulator suite covers it from the other side.
 */

const SAM = 'uid-sam';
const THANDI = 'uid-thandi';
const STRANGER = 'uid-stranger';
const HOUSEHOLD = 'h1';
const SAM_MEMBER = 'm-sam';
const THANDI_MEMBER = 'm-thandi';
const FOLDERS = `households/${HOUSEHOLD}/documentFolders`;
const DOCUMENTS = `households/${HOUSEHOLD}/documents`;

async function givenTheParkers(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `households/${HOUSEHOLD}`), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [THANDI]: 'helper' },
    });
    await setDoc(doc(db, `households/${HOUSEHOLD}/members/${SAM_MEMBER}`), {
      displayName: 'Sam',
      color: 'violet',
      role: 'admin',
      claimedBy: SAM,
    });
    await setDoc(doc(db, `households/${HOUSEHOLD}/members/${THANDI_MEMBER}`), {
      displayName: 'Thandi',
      color: 'mint',
      role: 'helper',
      claimedBy: THANDI,
    });
    await setDoc(doc(db, `${FOLDERS}/school`), {
      name: 'School',
      createdBy: SAM_MEMBER,
      createdAt: new Date(),
    });
    // Filed by Thandi, so "the uploader" and "an admin" are two different
    // people in every test below.
    await setDoc(doc(db, `${DOCUMENTS}/letter`), {
      folderId: 'school',
      name: 'Term letter',
      contentType: 'application/pdf',
      sizeBytes: 120_000,
      uploadedBy: THANDI_MEMBER,
      uploadedAt: new Date(),
    });
  });
}

const newFolder = {
  name: 'Insurance',
  createdBy: SAM_MEMBER,
  createdAt: serverTimestamp(),
};

const newDocument = {
  folderId: 'school',
  name: 'Report card',
  contentType: 'image/jpeg',
  sizeBytes: 2_400_000,
  uploadedBy: THANDI_MEMBER,
  uploadedAt: serverTimestamp(),
};

describe('documentFolders/{folderId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('lets any member read the folders', async () => {
    await assertSucceeds(getDoc(doc(await asUser(SAM), `${FOLDERS}/school`)));
    await assertSucceeds(getDoc(doc(await asUser(THANDI), `${FOLDERS}/school`)));
  });

  it('denies a stranger reading them', async () => {
    await assertFails(getDoc(doc(await asUser(STRANGER), `${FOLDERS}/school`)));
  });

  it('denies a signed-out caller reading them', async () => {
    await assertFails(getDoc(doc(await asUser('uid-nobody'), `${FOLDERS}/school`)));
  });

  it('lets an admin make a folder', async () => {
    await assertSucceeds(setDoc(doc(await asUser(SAM), `${FOLDERS}/insurance`), newFolder));
  });

  it('denies a helper making one', async () => {
    // A folder is the household's filing cabinet: renaming or removing one
    // changes what everybody else sees (documents ADR-0001).
    await assertFails(
      setDoc(doc(await asUser(THANDI), `${FOLDERS}/insurance`), {
        ...newFolder,
        createdBy: THANDI_MEMBER,
      }),
    );
  });

  it('denies an admin making one in somebody else"s name', async () => {
    await assertFails(
      setDoc(doc(await asUser(SAM), `${FOLDERS}/insurance`), {
        ...newFolder,
        createdBy: THANDI_MEMBER,
      }),
    );
  });

  it('denies a creation time the client chose', async () => {
    await assertFails(
      setDoc(doc(await asUser(SAM), `${FOLDERS}/insurance`), {
        ...newFolder,
        createdAt: new Date('2020-01-01'),
      }),
    );
  });

  it('denies an empty name, and a name longer than one somebody types', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, `${FOLDERS}/insurance`), { ...newFolder, name: '' }));
    await assertFails(
      setDoc(doc(db, `${FOLDERS}/insurance`), { ...newFolder, name: 'x'.repeat(81) }),
    );
  });

  it('denies a field the rule does not name', async () => {
    await assertFails(
      setDoc(doc(await asUser(SAM), `${FOLDERS}/insurance`), { ...newFolder, parentId: 'school' }),
    );
  });

  it('lets an admin rename a folder', async () => {
    await assertSucceeds(updateDoc(doc(await asUser(SAM), `${FOLDERS}/school`), { name: 'Kids' }));
  });

  it('denies a helper renaming one', async () => {
    await assertFails(updateDoc(doc(await asUser(THANDI), `${FOLDERS}/school`), { name: 'Kids' }));
  });

  it('denies changing who made it', async () => {
    await assertFails(
      updateDoc(doc(await asUser(SAM), `${FOLDERS}/school`), { createdBy: THANDI_MEMBER }),
    );
  });

  it('denies every client deleting a folder, admin included', async () => {
    // A rule cannot count what is still in it, and a folder deleted out from
    // under its documents leaves bytes nobody can see and nobody stops paying
    // for. `deleteDocumentFolder` is the only way (documents ADR-0001).
    await assertFails(deleteDoc(doc(await asUser(SAM), `${FOLDERS}/school`)));
    await assertFails(deleteDoc(doc(await asUser(THANDI), `${FOLDERS}/school`)));
  });
});

describe('documents/{documentId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('lets everybody in the household read everything in it', async () => {
    // Household ADR-0001: no per-item privacy. This is that decision, tested.
    await assertSucceeds(getDoc(doc(await asUser(SAM), `${DOCUMENTS}/letter`)));
    await assertSucceeds(getDoc(doc(await asUser(THANDI), `${DOCUMENTS}/letter`)));
  });

  it('denies a stranger reading one', async () => {
    await assertFails(getDoc(doc(await asUser(STRANGER), `${DOCUMENTS}/letter`)));
  });

  it('lets any member add one in their own name', async () => {
    await assertSucceeds(setDoc(doc(await asUser(THANDI), `${DOCUMENTS}/report`), newDocument));
  });

  it('denies adding one in somebody else"s name', async () => {
    await assertFails(
      setDoc(doc(await asUser(THANDI), `${DOCUMENTS}/report`), {
        ...newDocument,
        uploadedBy: SAM_MEMBER,
      }),
    );
  });

  it('denies an upload time the client chose', async () => {
    await assertFails(
      setDoc(doc(await asUser(THANDI), `${DOCUMENTS}/report`), {
        ...newDocument,
        uploadedAt: new Date('2020-01-01'),
      }),
    );
  });

  it('denies a type NestPrep does not keep', async () => {
    const db = await asUser(THANDI);
    for (const contentType of ['application/zip', 'text/html', 'application/octet-stream', '']) {
      await assertFails(setDoc(doc(db, `${DOCUMENTS}/report`), { ...newDocument, contentType }));
    }
  });

  it('accepts every type it does keep', async () => {
    const db = await asUser(THANDI);
    for (const contentType of [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/heic',
      'image/webp',
    ]) {
      await assertSucceeds(
        setDoc(doc(db, `${DOCUMENTS}/report-${contentType.replace('/', '-')}`), {
          ...newDocument,
          contentType,
        }),
      );
    }
  });

  it('denies a size past the cap, or one that is not a size at all', async () => {
    const db = await asUser(THANDI);
    // The cap that matters is on the bytes, in `storage.rules`; this one stops
    // a metadata row that describes something nobody could have uploaded.
    await assertFails(
      setDoc(doc(db, `${DOCUMENTS}/report`), { ...newDocument, sizeBytes: 20 * 1024 * 1024 + 1 }),
    );
    await assertFails(setDoc(doc(db, `${DOCUMENTS}/report`), { ...newDocument, sizeBytes: 0 }));
    await assertFails(
      setDoc(doc(db, `${DOCUMENTS}/report`), { ...newDocument, sizeBytes: 'a lot' }),
    );
  });

  it('accepts a document exactly at the cap', async () => {
    await assertSucceeds(
      setDoc(doc(await asUser(THANDI), `${DOCUMENTS}/report`), {
        ...newDocument,
        sizeBytes: 20 * 1024 * 1024,
      }),
    );
  });

  it('denies a document filed in no folder', async () => {
    await assertFails(
      setDoc(doc(await asUser(THANDI), `${DOCUMENTS}/report`), { ...newDocument, folderId: '' }),
    );
  });

  it('denies a field the rule does not name', async () => {
    await assertFails(
      setDoc(doc(await asUser(THANDI), `${DOCUMENTS}/report`), {
        ...newDocument,
        storagePath: 'somewhere/else',
      }),
    );
  });

  it('lets the uploader rename it and move it between folders', async () => {
    await assertSucceeds(
      updateDoc(doc(await asUser(THANDI), `${DOCUMENTS}/letter`), {
        name: 'Term 3 letter',
        folderId: 'school',
      }),
    );
  });

  it('lets an admin rename somebody else"s', async () => {
    await assertSucceeds(
      updateDoc(doc(await asUser(SAM), `${DOCUMENTS}/letter`), { name: 'Term 3 letter' }),
    );
  });

  it('denies changing what the bytes are', async () => {
    const db = await asUser(THANDI);
    await assertFails(updateDoc(doc(db, `${DOCUMENTS}/letter`), { contentType: 'image/png' }));
    await assertFails(updateDoc(doc(db, `${DOCUMENTS}/letter`), { sizeBytes: 1 }));
    await assertFails(updateDoc(doc(db, `${DOCUMENTS}/letter`), { uploadedBy: SAM_MEMBER }));
  });

  it('lets the uploader delete it', async () => {
    await assertSucceeds(deleteDoc(doc(await asUser(THANDI), `${DOCUMENTS}/letter`)));
  });

  it('lets an admin delete somebody else"s', async () => {
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), `${DOCUMENTS}/letter`)));
  });

  it('denies a stranger deleting one', async () => {
    await assertFails(deleteDoc(doc(await asUser(STRANGER), `${DOCUMENTS}/letter`)));
  });

  it('denies a member who is neither the uploader nor an admin', async () => {
    await givenData(async (db: Firestore) => {
      await setDoc(doc(db, `households/${HOUSEHOLD}`), {
        name: 'The Parkers',
        timeZone: 'Africa/Johannesburg',
        members: { [SAM]: 'admin', [THANDI]: 'helper', 'uid-kim': 'member' },
      });
      await setDoc(doc(db, `households/${HOUSEHOLD}/members/m-kim`), {
        displayName: 'Kim',
        color: 'sky',
        role: 'member',
        claimedBy: 'uid-kim',
      });
    });

    const kim = await asUser('uid-kim');
    await assertSucceeds(getDoc(doc(kim, `${DOCUMENTS}/letter`)));
    await assertFails(updateDoc(doc(kim, `${DOCUMENTS}/letter`), { name: 'Mine now' }));
    await assertFails(deleteDoc(doc(kim, `${DOCUMENTS}/letter`)));
  });
});
