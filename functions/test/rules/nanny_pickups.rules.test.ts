import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { HOME, HOUSEHOLD, KID_DEVICE, PEOPLE } from './access_fixture';
import { CARER, CHILD } from './nanny_fixture';
import { V2_PATHS, givenAHubWithTwoCarers } from './nanny_v2_fixture';
import {
  asKid,
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
} from './rules_harness';

/**
 * Who may collect each child, and the school-run schedule (nanny-hub
 * ADR-0005). Family alone decides who a child may be released to — a carer
 * at `edit` writes the rest of the hub but never this list — and whoever
 * reads the hub reads it, so the carer at the door can check.
 */

const DATE = '2026-10-02';

function person(
  createdBy: string,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    name: 'Gogo Dlamini',
    relationship: 'Grandmother',
    idNote: 'Grey hair, drives a white Polo',
    phone: '+27 82 555 0100',
    photoId: null,
    childIds: [CHILD],
    createdBy,
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

function run(updatedBy: string, overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    childId: CHILD,
    weekday: 1,
    personId: 'gogo',
    memberId: null,
    atMinute: 870,
    place: 'Oakwood Primary gate',
    updatedBy,
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

function change(
  updatedBy: string,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    childId: CHILD,
    date: DATE,
    personId: null,
    memberId: CARER.member,
    atMinute: 780,
    note: 'Half day',
    updatedBy,
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

beforeEach(async () => {
  await clearData();
  await givenAHubWithTwoCarers();
  const by = PEOPLE.admin.member;
  await givenData(async (db) => {
    await setDoc(doc(db, V2_PATHS.person), { ...person(by), createdAt: new Date() });
    await setDoc(doc(db, V2_PATHS.run), { ...run(by), updatedAt: new Date() });
    await setDoc(doc(db, V2_PATHS.change), { ...change(by), updatedAt: new Date() });
  });
});

const PARENT = PEOPLE.parent;
const all = [V2_PATHS.person, V2_PATHS.run, V2_PATHS.change];

describe('reading who may collect', () => {
  it('lets family, the carer and a helper at view read all three', async () => {
    for (const uid of [PEOPLE.admin.uid, PARENT.uid, CARER.uid, PEOPLE.viewer.uid]) {
      const db = await asUser(uid);
      for (const path of all) await assertSucceeds(getDoc(doc(db, path)));
      await assertSucceeds(getDocs(collection(db, `${HOME}/nannyPickupPeople`)));
    }
  });

  it('refuses whoever the hub is closed to, the kid’s tablet, strangers and nobody', async () => {
    const tablet = await asKid(KID_DEVICE, { householdId: HOUSEHOLD, memberId: CHILD });
    for (const db of [
      await asUser(PEOPLE.cleaner.uid),
      await asUser(PEOPLE.kid.uid),
      tablet,
      await asUser('uid-stranger'),
      await asSignedOut(),
    ]) {
      for (const path of all) await assertFails(getDoc(doc(db, path)));
    }
  });
});

describe('family decides who may collect', () => {
  it('lets a parent add, change and remove a person', async () => {
    const db = await asUser(PARENT.uid);
    await assertSucceeds(
      setDoc(doc(db, `${HOME}/nannyPickupPeople/uncle`), person(PARENT.member, { name: 'Sipho' })),
    );
    await assertSucceeds(
      updateDoc(doc(db, V2_PATHS.person), { relationship: 'Granny', childIds: [] }),
    );
    await assertSucceeds(deleteDoc(doc(db, V2_PATHS.person)));
  });

  it('refuses the carer — at edit — adding, changing or removing anybody', async () => {
    const db = await asUser(CARER.uid);
    await assertFails(
      setDoc(doc(db, `${HOME}/nannyPickupPeople/friend`), person(CARER.member, { name: 'Lulu' })),
    );
    await assertFails(updateDoc(doc(db, V2_PATHS.person), { childIds: [] }));
    await assertFails(deleteDoc(doc(db, V2_PATHS.person)));
  });

  it('refuses a person with no name or relationship, a bad phone or photo, or too much', async () => {
    const db = await asUser(PARENT.uid);
    const path = doc(db, `${HOME}/nannyPickupPeople/uncle`);
    const by = PARENT.member;
    await assertFails(setDoc(path, person(by, { name: '' })));
    await assertFails(setDoc(path, person(by, { relationship: 'x'.repeat(41) })));
    await assertFails(setDoc(path, person(by, { idNote: 'x'.repeat(201) })));
    await assertFails(setDoc(path, person(by, { phone: 'call me' })));
    await assertFails(setDoc(path, person(by, { photoId: '../elsewhere' })));
    await assertFails(setDoc(path, person(by, { childIds: Array(11).fill(CHILD) })));
    await assertFails(setDoc(path, person(PEOPLE.admin.member)));
    await assertFails(setDoc(path, person(by, { createdAt: new Date() })));
    await assertFails(setDoc(path, person(by, { approved: true })));
    await assertFails(updateDoc(doc(db, V2_PATHS.person), { createdBy: by }));
  });
});

describe('the school-run schedule', () => {
  it('lets a parent set and clear who collects on a weekday', async () => {
    const db = await asUser(PARENT.uid);
    await assertSucceeds(
      setDoc(
        doc(db, `${HOME}/nannySchoolRuns/${CHILD}_3`),
        run(PARENT.member, { weekday: 3, personId: null, memberId: CARER.member }),
      ),
    );
    await assertSucceeds(
      setDoc(doc(db, V2_PATHS.run), run(PARENT.member, { atMinute: null, place: null })),
    );
    await assertSucceeds(deleteDoc(doc(db, V2_PATHS.run)));
  });

  it('refuses the carer setting or clearing one', async () => {
    const db = await asUser(CARER.uid);
    await assertFails(setDoc(doc(db, V2_PATHS.run), run(CARER.member, { personId: 'friend' })));
    await assertFails(deleteDoc(doc(db, V2_PATHS.run)));
  });

  it('refuses a run naming two collectors or none, a day that is not a weekday, or a wrong id', async () => {
    const db = await asUser(PARENT.uid);
    const by = PARENT.member;
    await assertFails(setDoc(doc(db, V2_PATHS.run), run(by, { memberId: CARER.member })));
    await assertFails(setDoc(doc(db, V2_PATHS.run), run(by, { personId: null })));
    await assertFails(
      setDoc(doc(db, `${HOME}/nannySchoolRuns/${CHILD}_0`), run(by, { weekday: 0 })),
    );
    await assertFails(
      setDoc(doc(db, `${HOME}/nannySchoolRuns/${CHILD}_8`), run(by, { weekday: 8 })),
    );
    await assertFails(setDoc(doc(db, `${HOME}/nannySchoolRuns/${CHILD}_2`), run(by)));
    await assertFails(setDoc(doc(db, `${HOME}/nannySchoolRuns/someone_1`), run(by)));
    await assertFails(setDoc(doc(db, V2_PATHS.run), run(by, { atMinute: 1440 })));
    await assertFails(setDoc(doc(db, V2_PATHS.run), run(by, { place: 'x'.repeat(81) })));
    await assertFails(setDoc(doc(db, V2_PATHS.run), run(by, { updatedAt: new Date() })));
  });
});

describe('a change for one date', () => {
  it('lets a parent say who collects, or that nobody does, on one date', async () => {
    const db = await asUser(PARENT.uid);
    await assertSucceeds(setDoc(doc(db, V2_PATHS.change), change(PARENT.member)));
    await assertSucceeds(
      setDoc(
        doc(db, `${HOME}/nannyPickupChanges/${CHILD}_2026-10-05`),
        change(PARENT.member, { date: '2026-10-05', memberId: null, note: 'Sick at home' }),
      ),
    );
    await assertSucceeds(deleteDoc(doc(db, V2_PATHS.change)));
  });

  it('refuses the carer changing one', async () => {
    const db = await asUser(CARER.uid);
    await assertFails(setDoc(doc(db, V2_PATHS.change), change(CARER.member)));
    await assertFails(deleteDoc(doc(db, V2_PATHS.change)));
  });

  it('refuses a bad date, a mismatched id, or two collectors', async () => {
    const db = await asUser(PARENT.uid);
    const by = PARENT.member;
    await assertFails(
      setDoc(doc(db, `${HOME}/nannyPickupChanges/${CHILD}_2 Oct`), change(by, { date: '2 Oct' })),
    );
    await assertFails(
      setDoc(doc(db, `${HOME}/nannyPickupChanges/${CHILD}_2026-10-09`), change(by)),
    );
    await assertFails(setDoc(doc(db, V2_PATHS.change), change(by, { personId: 'gogo' })));
    await assertFails(setDoc(doc(db, V2_PATHS.change), change(by, { note: 'x'.repeat(201) })));
  });
});
