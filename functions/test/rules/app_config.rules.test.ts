import { collection, deleteDoc, doc, getDoc, getDocs, setDoc, updateDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
} from './rules_harness';

/**
 * The V2 switches (foundation ADR-0014): one document anybody may read and
 * no client may write. Home care's three switches are its first readers on
 * this branch; documents' share links carry the same checks on theirs.
 */
const FLAGS = 'appConfig/flags';

beforeEach(async () => {
  await clearData();
  await givenData(async (db) => {
    await setDoc(doc(db, FLAGS), { homeCareRoutines: true });
  });
});

describe('appConfig/{configId}', () => {
  it('anybody reads the switches, signed in or not', async () => {
    await assertSucceeds(getDoc(doc(await asUser('uid-stranger'), FLAGS)));
    await assertSucceeds(getDoc(doc(await asSignedOut(), FLAGS)));
  });

  it('nobody lists the collection or reads another config document', async () => {
    const db = await asUser('uid-sam');
    await assertFails(getDocs(collection(db, 'appConfig')));
    await assertFails(getDoc(doc(db, 'appConfig/secrets')));
  });

  it('nobody writes a switch from the app, not even an admin', async () => {
    const db = await asUser('uid-sam');
    await assertFails(setDoc(doc(db, FLAGS), { homeCareStock: false }));
    await assertFails(updateDoc(doc(db, FLAGS), { homeCareHelperLanguage: true }));
    await assertFails(deleteDoc(doc(db, FLAGS)));
  });
});
