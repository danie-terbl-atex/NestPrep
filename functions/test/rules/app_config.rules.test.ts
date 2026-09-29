import { deleteDoc, doc, getDoc, setDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { PEOPLE } from './access_fixture';
import {
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
} from './rules_harness';

/**
 * `appConfig/flags` switches V2 capabilities on and off (foundation
 * ADR-0014). Nothing in it is private, so anybody reads it, signed in or
 * not; it is changed in the console and never by a client, and no other
 * document in the collection opens at all.
 */
const FLAGS = 'appConfig/flags';

beforeEach(async () => {
  await clearData();
  await givenData(async (db) => {
    await setDoc(doc(db, FLAGS), { nannyPickups: true });
  });
});

describe('the feature flags', () => {
  it('are read by anybody, signed in or not', async () => {
    for (const db of [await asUser(PEOPLE.admin.uid), await asSignedOut()]) {
      await assertSucceeds(getDoc(doc(db, FLAGS)));
    }
  });

  it('opens no other document in the collection', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, 'appConfig/other'), { anything: true });
    });
    await assertFails(getDoc(doc(await asUser(PEOPLE.admin.uid), 'appConfig/other')));
  });

  it('are written by nobody — not an admin, not anybody else', async () => {
    for (const db of [await asUser(PEOPLE.admin.uid), await asSignedOut()]) {
      await assertFails(setDoc(doc(db, FLAGS), { nannyPickups: false }));
      await assertFails(setDoc(doc(db, 'appConfig/other'), { anything: true }));
      await assertFails(deleteDoc(doc(db, FLAGS)));
    }
  });
});
