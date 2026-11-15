import {
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { HOME, PEOPLE, givenAHouseholdOfEveryRole } from './access_fixture';
import {
  JOBS,
  PRODUCT,
  ROOM,
  eventPath,
  givenHomeCarePremium,
  givenHomeCareRecords,
  jobData,
} from './home_care_fixture';
import {
  ROUTINES,
  givenRoutines,
  routineData,
  tickData,
  tickPath,
} from './home_care_routines_fixture';
import {
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

/**
 * Home care is Premium in full (subscriptions ADR-0008, ADR-0009): a
 * household without it adds and changes nothing there, and still reads and
 * removes everything it made. Clocking out is the one change left free, so a
 * shift left open when Premium ended can still be closed.
 */

const ADMIN = PEOPLE.admin.member;
const CLEANER = PEOPLE.cleaner.member;
const SHIFTS = `${HOME}/homeCareShifts`;
const OPEN_SHIFT = `${SHIFTS}/today`;
const LANGUAGE = `${HOME}/homeCareHelpers/m-unclaimed`;
const NEW_JOB = `${HOME}/homeCareJobs/stain`;

const family = (): Promise<Firestore> => asUser(PEOPLE.admin.uid);
const cleaner = (): Promise<Firestore> => asUser(PEOPLE.cleaner.uid);

function clockedIn(helperId: string): Record<string, unknown> {
  return {
    helperId,
    status: 'open',
    startedAt: serverTimestamp(),
    startedBy: helperId,
    startedVia: 'app',
    endedAt: null,
    endedBy: null,
    endedVia: null,
  };
}

function language(code: string, by: string): Record<string, unknown> {
  return { language: code, updatedBy: by, updatedAt: serverTimestamp() };
}

async function createJob(): Promise<void> {
  const db = await family();
  const batch = writeBatch(db);
  batch.set(doc(db, NEW_JOB), {
    ...jobData(CLEANER),
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  batch.set(doc(db, eventPath(NEW_JOB, 0)), {
    status: 'assigned',
    by: ADMIN,
    note: null,
    at: serverTimestamp(),
  });
  return batch.commit();
}

async function startJob(): Promise<void> {
  const db = await cleaner();
  const batch = writeBatch(db);
  batch.update(doc(db, JOBS.cleaners), {
    doneStepIds: ['s1'],
    status: 'inProgress',
    revision: 1,
    updatedAt: serverTimestamp(),
  });
  batch.set(doc(db, eventPath(JOBS.cleaners, 1)), {
    status: 'inProgress',
    by: CLEANER,
    note: null,
    at: serverTimestamp(),
  });
  return batch.commit();
}

const PREMIUM_WRITES: readonly (readonly [string, () => Promise<unknown>])[] = [
  [
    'a new room',
    async (): Promise<unknown> =>
      setDoc(doc(await family(), `${HOME}/homeCareRooms/bath`), {
        name: 'Main bathroom',
        kind: 'bathroom',
        createdBy: ADMIN,
        createdAt: serverTimestamp(),
      }),
  ],
  [
    'a renamed room',
    async (): Promise<unknown> => updateDoc(doc(await family(), ROOM), { name: 'Scullery' }),
  ],
  [
    'a new product',
    async (): Promise<unknown> =>
      setDoc(doc(await family(), `${HOME}/homeCareProducts/andy`), {
        name: 'Handy Andy',
        kind: 'allPurpose',
        whereKept: null,
        note: null,
        keepFromChildren: false,
        keepFromPets: false,
        createdBy: ADMIN,
        createdAt: serverTimestamp(),
      }),
  ],
  [
    'a changed product',
    async (): Promise<unknown> =>
      updateDoc(doc(await family(), PRODUCT), { whereKept: 'Top shelf' }),
  ],
  [
    'a stock level',
    async (): Promise<unknown> =>
      updateDoc(doc(await cleaner(), PRODUCT), {
        stock: 'low',
        stockChangedBy: CLEANER,
        stockChangedAt: serverTimestamp(),
      }),
  ],
  ['a new job with its first event', createJob],
  [
    'a job’s changed details',
    async (): Promise<unknown> =>
      updateDoc(doc(await family(), JOBS.cleaners), {
        title: 'Oven, inside and out',
        updatedAt: serverTimestamp(),
      }),
  ],
  [
    'a ticked step',
    async (): Promise<unknown> =>
      updateDoc(doc(await family(), JOBS.cleaners), {
        doneStepIds: ['s1'],
        updatedAt: serverTimestamp(),
      }),
  ],
  ['a job started, with its event', startJob],
  [
    'a new routine',
    async (): Promise<unknown> =>
      setDoc(
        doc(await family(), `${HOME}/homeCareRoutines/lounge-weekly`),
        routineData(CLEANER, { createdAt: serverTimestamp() }),
      ),
  ],
  [
    'a changed routine',
    async (): Promise<unknown> =>
      updateDoc(doc(await family(), ROUTINES.cleaners), { cadence: 'weekly' }),
  ],
  [
    'a routine’s ticked day',
    async (): Promise<unknown> =>
      setDoc(doc(await cleaner(), tickPath('kitchen-daily')), tickData('kitchen-daily', CLEANER)),
  ],
  [
    'a first tick on another day',
    async (): Promise<unknown> =>
      setDoc(
        doc(await cleaner(), tickPath('kitchen-daily', '2026-09-30')),
        tickData('kitchen-daily', CLEANER, { occurrenceDate: '2026-09-30' }),
      ),
  ],
  [
    'a shift clocked in',
    async (): Promise<unknown> => setDoc(doc(await cleaner(), `${SHIFTS}/new`), clockedIn(CLEANER)),
  ],
  [
    'a helper’s own language',
    async (): Promise<unknown> =>
      setDoc(doc(await cleaner(), `${HOME}/homeCareHelpers/${CLEANER}`), language('zu', CLEANER)),
  ],
  [
    'a helper’s changed language',
    async (): Promise<unknown> => setDoc(doc(await family(), LANGUAGE), language('xh', ADMIN)),
  ],
];

const STILL_REMOVED: readonly (readonly [string, () => Promise<unknown>])[] = [
  ['a room', async (): Promise<unknown> => deleteDoc(doc(await family(), ROOM))],
  ['a product', async (): Promise<unknown> => deleteDoc(doc(await family(), PRODUCT))],
  ['a job', async (): Promise<unknown> => deleteDoc(doc(await family(), JOBS.cleaners))],
  [
    'a job’s history',
    async (): Promise<unknown> => deleteDoc(doc(await family(), eventPath(JOBS.cleaners, 0))),
  ],
  ['a routine', async (): Promise<unknown> => deleteDoc(doc(await family(), ROUTINES.cleaners))],
  [
    'a routine’s ticked day',
    async (): Promise<unknown> => deleteDoc(doc(await family(), tickPath('kitchen-daily'))),
  ],
  ['a helper’s language', async (): Promise<unknown> => deleteDoc(doc(await family(), LANGUAGE))],
];

beforeEach(async () => {
  await clearData();
  await givenAHouseholdOfEveryRole();
  await givenHomeCareRecords();
  await givenRoutines();
  await givenData(async (db) => {
    await setDoc(doc(db, OPEN_SHIFT), { ...clockedIn(CLEANER), startedAt: new Date() });
    await setDoc(doc(db, LANGUAGE), { ...language('ny', ADMIN), updatedAt: new Date() });
  });
});

describe('a Premium household', () => {
  it.each(PREMIUM_WRITES)('writes %s', async (_, write) => {
    await assertSucceeds(write());
  });
});

describe.each(['free', 'lapsed'] as const)('a %s household and home care', (state) => {
  beforeEach((): Promise<void> => givenHomeCarePremium(state));

  it.each(PREMIUM_WRITES)('is refused %s', async (_, write) => {
    await assertFails(write());
  });

  it.each(STILL_REMOVED)('still removes %s', async (_, remove) => {
    await assertSucceeds(remove());
  });

  it('still reads everything it made', async () => {
    const db = await family();
    for (const path of [
      ROOM,
      PRODUCT,
      JOBS.cleaners,
      eventPath(JOBS.cleaners, 0),
      ROUTINES.cleaners,
      tickPath('kitchen-daily'),
      OPEN_SHIFT,
      LANGUAGE,
    ]) {
      await assertSucceeds(getDoc(doc(db, path)));
    }
    await assertSucceeds(getDoc(doc(await cleaner(), JOBS.cleaners)));
    await assertSucceeds(getDoc(doc(await cleaner(), OPEN_SHIFT)));
  });

  it('still lets a helper clock out of the shift she left open', async () => {
    await assertSucceeds(
      updateDoc(doc(await cleaner(), OPEN_SHIFT), {
        status: 'ended',
        endedAt: serverTimestamp(),
        endedBy: CLEANER,
        endedVia: 'app',
      }),
    );
  });

  it('still lets family end a shift somebody forgot', async () => {
    await assertSucceeds(
      updateDoc(doc(await family(), OPEN_SHIFT), {
        status: 'ended',
        endedAt: serverTimestamp(),
        endedBy: ADMIN,
        endedVia: 'app',
      }),
    );
  });
});
