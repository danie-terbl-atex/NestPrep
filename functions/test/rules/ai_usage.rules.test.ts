import { deleteDoc, doc, getDoc, getDocs, collection, setDoc, updateDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { SAM, THANDI, givenAHouseholdOfTwo } from './household_fixture';
import {
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

/**
 * The AI ledger and the app configuration (foundation ADR-0014, ADR-0015).
 *
 * The ledger is the cap: a household that could write its own `aiUsage`
 * could reset its month, and one that could read it would see uids — so no
 * client does either, not even the household's admin. The flags are a list
 * of switches anybody signed in may read and nobody may write; the AI switch
 * and its caps are for Functions alone.
 */

const MONTH = '2026-09';
let home = '';

beforeEach(async () => {
  await clearData();
  home = await givenAHouseholdOfTwo();
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `${home}/aiUsage/${MONTH}`), { calls: 3, attempts: 4 });
    await setDoc(doc(db, `${home}/aiUsage/${MONTH}/calls/c1`), {
      feature: 'schoolLetter',
      tier: 'free',
      uid: SAM,
      status: 'succeeded',
    });
    await setDoc(doc(db, 'appConfig/flags'), { snapSchoolLetter: true });
    await setDoc(doc(db, 'appConfig/ai'), { enabled: true, monthlyCalls: { free: 10 } });
    await setDoc(doc(db, 'aiEmulator/schoolLetter'), { reply: '{"events":[]}' });
  });
});

describe('a household’s AI usage', () => {
  it('cannot be read by the household’s own admin', async () => {
    const sam = await asUser(SAM);
    await assertFails(getDoc(doc(sam, `${home}/aiUsage/${MONTH}`)));
    await assertFails(getDocs(collection(sam, `${home}/aiUsage`)));
    await assertFails(getDoc(doc(sam, `${home}/aiUsage/${MONTH}/calls/c1`)));
  });

  it('cannot be reset, raised or written by anybody in the household', async () => {
    for (const uid of [SAM, THANDI]) {
      const db = await asUser(uid);
      await assertFails(updateDoc(doc(db, `${home}/aiUsage/${MONTH}`), { calls: 0 }));
      await assertFails(deleteDoc(doc(db, `${home}/aiUsage/${MONTH}`)));
      await assertFails(setDoc(doc(db, `${home}/aiUsage/2026-10`), { calls: 0, attempts: 0 }));
      await assertFails(
        setDoc(doc(db, `${home}/aiUsage/${MONTH}/calls/c2`), { status: 'succeeded' }),
      );
    }
  });

  it('cannot be read signed out', async () => {
    await assertFails(getDoc(doc(await asSignedOut(), `${home}/aiUsage/${MONTH}`)));
  });
});

describe('the V2 flags', () => {
  it('can be read by anybody signed in, a helper included', async () => {
    await assertSucceeds(getDoc(doc(await asUser(SAM), 'appConfig/flags')));
    await assertSucceeds(getDoc(doc(await asUser(THANDI), 'appConfig/flags')));
    await assertSucceeds(getDoc(doc(await asUser('uid-stranger'), 'appConfig/flags')));
  });

  it('cannot be read signed out', async () => {
    await assertFails(getDoc(doc(await asSignedOut(), 'appConfig/flags')));
  });

  it('cannot be switched by any client, an admin included', async () => {
    const sam = await asUser(SAM);
    await assertFails(updateDoc(doc(sam, 'appConfig/flags'), { snapSchoolLetter: false }));
    await assertFails(setDoc(doc(sam, 'appConfig/flags'), { snapSchoolLetter: true }));
    await assertFails(deleteDoc(doc(sam, 'appConfig/flags')));
  });
});

describe('the AI switch and caps', () => {
  it('cannot be read by a client — the caps are nobody’s business but the server’s', async () => {
    await assertFails(getDoc(doc(await asUser(SAM), 'appConfig/ai')));
  });

  it('cannot be raised or switched by a client', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(sam, 'appConfig/ai'), { monthlyCalls: { free: 1000 } }));
    await assertFails(setDoc(doc(sam, 'appConfig/other'), { anything: true }));
  });

  it('nor can the emulator’s canned answers be read or planted', async () => {
    const sam = await asUser(SAM);
    await assertFails(getDoc(doc(sam, 'aiEmulator/schoolLetter')));
    await assertFails(setDoc(doc(sam, 'aiEmulator/schoolLetter'), { reply: '{}' }));
  });
});
