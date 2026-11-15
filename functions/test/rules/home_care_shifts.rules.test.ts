import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  HOME,
  KID_DEVICE,
  PEOPLE,
  givenAHouseholdOfEveryRole,
  type Person,
} from './access_fixture';
import { givenHomeCarePremium } from './home_care_fixture';
import {
  asKid,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

/**
 * A helper's shifts (home-care ADR-0007): she clocks herself in and out,
 * family clocks anybody, both instants are the server's, and a shift only
 * ever moves open → ended.
 */

const as = (person: Person): Promise<Firestore> => asUser(PEOPLE[person].uid);

const tablet = (): Promise<Firestore> =>
  asKid(KID_DEVICE, { householdId: 'h-access', memberId: PEOPLE.kid.member });

const CLEANER = PEOPLE.cleaner.member;
const VIEWER = PEOPLE.viewer.member;
const SHIFTS = `${HOME}/homeCareShifts`;
const OPEN = `${HOME}/homeCareShifts/today`;
const VIEWERS_OPEN = `${HOME}/homeCareShifts/veras`;
const ENDED = `${HOME}/homeCareShifts/yesterday`;
const NEW = `${SHIFTS}/new`;

function started(helperId: string, by = helperId): Record<string, unknown> {
  return {
    helperId,
    status: 'open',
    startedAt: serverTimestamp(),
    startedBy: by,
    startedVia: 'app',
    endedAt: null,
    endedBy: null,
    endedVia: null,
  };
}

function ended(by: string): Record<string, unknown> {
  return { status: 'ended', endedAt: serverTimestamp(), endedBy: by, endedVia: 'app' };
}

beforeEach(async () => {
  await clearData();
  await givenAHouseholdOfEveryRole();
  await givenHomeCarePremium();
  await givenData(async (db) => {
    const stored = (helperId: string): Record<string, unknown> => ({
      ...started(helperId),
      startedAt: new Date(),
    });
    await setDoc(doc(db, OPEN), stored(CLEANER));
    await setDoc(doc(db, VIEWERS_OPEN), stored(VIEWER));
    await setDoc(doc(db, ENDED), {
      ...stored(CLEANER),
      status: 'ended',
      endedAt: new Date(),
      endedBy: CLEANER,
      endedVia: 'frame',
    });
  });
});

describe('starting a shift', () => {
  it('lets a helper clock herself in', async () => {
    await assertSucceeds(setDoc(doc(await as('cleaner'), NEW), started(CLEANER)));
    await assertSucceeds(setDoc(doc(await as('viewer'), `${SHIFTS}/new-2`), started(VIEWER)));
  });

  it('lets family clock a helper in, in their own name', async () => {
    const db = await as('parent');
    await assertSucceeds(setDoc(doc(db, NEW), started(CLEANER, PEOPLE.parent.member)));
    await assertSucceeds(
      setDoc(doc(db, `${SHIFTS}/new-2`), started('m-unclaimed', PEOPLE.parent.member)),
    );
  });

  it('denies a helper clocking somebody else in, or in somebody else’s name', async () => {
    const db = await as('cleaner');
    await assertFails(setDoc(doc(db, NEW), started(VIEWER, CLEANER)));
    await assertFails(setDoc(doc(db, NEW), started(CLEANER, PEOPLE.admin.member)));
  });

  it('refuses a start at the client’s time, already ended, or said to be from a frame', async () => {
    const db = await as('cleaner');
    await assertFails(setDoc(doc(db, NEW), { ...started(CLEANER), startedAt: new Date(0) }));
    await assertFails(
      setDoc(doc(db, NEW), { ...started(CLEANER), ...ended(CLEANER), status: 'ended' }),
    );
    await assertFails(setDoc(doc(db, NEW), { ...started(CLEANER), endedAt: new Date() }));
    await assertFails(setDoc(doc(db, NEW), { ...started(CLEANER), startedVia: 'frame' }));
    await assertFails(setDoc(doc(db, NEW), { ...started(CLEANER), note: 'early' }));
  });

  it('refuses a shift for nobody, or with a field missing', async () => {
    const db = await as('admin');
    await assertFails(setDoc(doc(db, NEW), started('m-nobody', PEOPLE.admin.member)));
    const short = Object.fromEntries(
      Object.entries(started(CLEANER, PEOPLE.admin.member)).filter(([key]) => key !== 'endedVia'),
    );
    await assertFails(setDoc(doc(db, NEW), short));
  });

  it('denies the carer, the kid and the tablet', async () => {
    for (const person of ['carer', 'kid'] as Person[]) {
      const own = PEOPLE[person].member;
      await assertFails(setDoc(doc(await as(person), NEW), started(own)));
    }
    await assertFails(setDoc(doc(await tablet(), NEW), started(PEOPLE.kid.member)));
  });
});

describe('ending a shift', () => {
  it('lets a helper clock herself out', async () => {
    await assertSucceeds(updateDoc(doc(await as('cleaner'), OPEN), ended(CLEANER)));
  });

  it('lets family end a shift somebody forgot', async () => {
    await assertSucceeds(updateDoc(doc(await as('admin'), OPEN), ended(PEOPLE.admin.member)));
  });

  it('denies a helper ending somebody else’s, even one she can read', async () => {
    await assertFails(updateDoc(doc(await as('viewer'), OPEN), ended(VIEWER)));
    await assertFails(updateDoc(doc(await as('cleaner'), VIEWERS_OPEN), ended(CLEANER)));
  });

  it('refuses an end at the client’s time, in another name, or from a frame', async () => {
    const db = await as('cleaner');
    await assertFails(updateDoc(doc(db, OPEN), { ...ended(CLEANER), endedAt: new Date(0) }));
    await assertFails(updateDoc(doc(db, OPEN), ended(PEOPLE.admin.member)));
    await assertFails(updateDoc(doc(db, OPEN), { ...ended(CLEANER), endedVia: 'frame' }));
  });

  it('refuses moving the start, the helper, or anything on an ended shift', async () => {
    const db = await as('admin');
    const by = PEOPLE.admin.member;
    await assertFails(updateDoc(doc(db, OPEN), { ...ended(by), startedAt: new Date(0) }));
    await assertFails(updateDoc(doc(db, OPEN), { ...ended(by), helperId: VIEWER }));
    await assertFails(updateDoc(doc(db, OPEN), { startedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db, ENDED), ended(by)));
    await assertFails(updateDoc(doc(db, ENDED), { status: 'open', endedAt: null }));
  });

  it('lets nobody delete one', async () => {
    await assertFails(deleteDoc(doc(await as('admin'), ENDED)));
    await assertFails(deleteDoc(doc(await as('cleaner'), OPEN)));
  });
});

describe('reading shifts', () => {
  it('lets family and a look-only helper read everybody’s', async () => {
    for (const person of ['admin', 'parent', 'viewer', 'legacyHelper'] as Person[]) {
      const db = await as(person);
      await assertSucceeds(getDoc(doc(db, OPEN)));
      await assertSucceeds(getDocs(collection(db, SHIFTS)));
    }
  });

  it('lets the cleaner read only her own, and only by asking for exactly those', async () => {
    const db = await as('cleaner');
    await assertSucceeds(getDoc(doc(db, OPEN)));
    await assertSucceeds(getDocs(query(collection(db, SHIFTS), where('helperId', '==', CLEANER))));
    await assertFails(getDoc(doc(db, VIEWERS_OPEN)));
    await assertFails(getDocs(collection(db, SHIFTS)));
  });

  it('denies whoever has no home care', async () => {
    await assertFails(getDoc(doc(await as('carer'), OPEN)));
    await assertFails(getDoc(doc(await as('kid'), OPEN)));
    await assertFails(getDoc(doc(await tablet(), OPEN)));
  });
});
