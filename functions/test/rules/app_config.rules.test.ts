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
 * ADR-0014). Nothing in it is private, so anybody signed in reads it; it is
 * changed in the console and never by a client, and no other document in the
 * collection — `appConfig/ai`, the AI caps (foundation ADR-0015), included —
 * opens at all. `appConfig/lunchAisle`, the Checkers lunchbox shelves *Plan
 * my week* reads (lunch-box ADR-0013), is read and refused the same way.
 */
const FLAGS = 'appConfig/flags';

beforeEach(async () => {
  await clearData();
  await givenData(async (db) => {
    await setDoc(doc(db, FLAGS), { nannyPickups: true });
  });
});

describe('the feature flags', () => {
  it('are read by anybody signed in, and by nobody signed out', async () => {
    await assertSucceeds(getDoc(doc(await asUser(PEOPLE.admin.uid), FLAGS)));
    await assertFails(getDoc(doc(await asSignedOut(), FLAGS)));
  });

  it('let anybody signed in read the lunchbox shelves, and nobody write them', async () => {
    const AISLE = 'appConfig/lunchAisle';
    await givenData(async (db) => {
      await setDoc(doc(db, AISLE), { shelves: [] });
    });
    const admin = await asUser(PEOPLE.admin.uid);
    await assertSucceeds(getDoc(doc(admin, AISLE)));
    await assertFails(getDoc(doc(await asSignedOut(), AISLE)));
    await assertFails(setDoc(doc(admin, AISLE), { shelves: [] }));
    await assertFails(deleteDoc(doc(admin, AISLE)));
  });

  it('keep the AI caps closed to every client', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, 'appConfig/ai'), { enabled: true });
    });
    await assertFails(getDoc(doc(await asUser(PEOPLE.admin.uid), 'appConfig/ai')));
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
