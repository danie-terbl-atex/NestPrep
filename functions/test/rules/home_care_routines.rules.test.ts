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
  DATE,
  HOME,
  KID_DEVICE,
  PEOPLE,
  givenAHouseholdOfEveryRole,
  type Person,
} from './access_fixture';
import {
  ROUTINES,
  givenRoutines,
  routineData,
  tickData,
  tickPath,
} from './home_care_routines_fixture';
import {
  asKid,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  type Firestore,
} from './rules_harness';

/**
 * Room routines by the `homeCare` grant (home-care ADR-0004, household
 * ADR-0003). The cleaner holds `own`: she reads and ticks only the routines
 * whose helper is her profile, and asks for exactly those. The look-only
 * helper holds `view`: she reads every routine and ticks only her own.
 * The carer and the kid hold `none`. Family writes routines and ticks any.
 */

const as = (person: Person): Promise<Firestore> => asUser(PEOPLE[person].uid);

const tablet = (): Promise<Firestore> =>
  asKid(KID_DEVICE, { householdId: 'h-access', memberId: PEOPLE.kid.member });

const CLEANER = PEOPLE.cleaner.member;
const VIEWER = PEOPLE.viewer.member;
const ADMIN = PEOPLE.admin.member;

beforeEach(async () => {
  await clearData();
  await givenAHouseholdOfEveryRole();
  await givenRoutines();
});

describe('reading routines and their ticks', () => {
  it('lets family and the look-only helper read every routine and tick', async () => {
    for (const person of ['admin', 'parent', 'legacyHelper', 'viewer'] as Person[]) {
      const db = await as(person);
      await assertSucceeds(getDoc(doc(db, ROUTINES.nobodys)));
      await assertSucceeds(getDocs(collection(db, `${HOME}/homeCareRoutines`)));
      await assertSucceeds(getDocs(collection(db, `${HOME}/homeCareRoutineTicks`)));
    }
  });

  it('lets the cleaner ask for exactly her own routines and ticks', async () => {
    const db = await as('cleaner');
    await assertSucceeds(getDoc(doc(db, ROUTINES.cleaners)));
    await assertSucceeds(
      getDocs(query(collection(db, `${HOME}/homeCareRoutines`), where('helperId', '==', CLEANER))),
    );
    await assertSucceeds(
      getDocs(
        query(
          collection(db, `${HOME}/homeCareRoutineTicks`),
          where('helperId', '==', CLEANER),
          where('occurrenceDate', '>=', DATE),
        ),
      ),
    );
  });

  it('denies the cleaner somebody else’s routine, tick, and the whole list', async () => {
    const db = await as('cleaner');
    await assertFails(getDoc(doc(db, ROUTINES.nobodys)));
    await assertFails(getDoc(doc(db, tickPath('garage-sweep'))));
    await assertFails(getDocs(collection(db, `${HOME}/homeCareRoutines`)));
    await assertFails(getDocs(collection(db, `${HOME}/homeCareRoutineTicks`)));
  });

  it('denies the carer, the kid and the kid’s tablet any routine', async () => {
    await assertFails(getDoc(doc(await as('carer'), ROUTINES.cleaners)));
    await assertFails(getDoc(doc(await as('kid'), ROUTINES.cleaners)));
    await assertFails(getDoc(doc(await tablet(), ROUTINES.cleaners)));
    await assertFails(getDoc(doc(await tablet(), tickPath('kitchen-daily'))));
  });
});

describe('writing routines', () => {
  const fresh = `${HOME}/homeCareRoutines/lounge-weekly`;

  it('lets family add, change and remove a routine', async () => {
    const db = await as('parent');
    await assertSucceeds(
      setDoc(
        doc(db, fresh),
        routineData(CLEANER, {
          createdBy: PEOPLE.parent.member,
          createdAt: serverTimestamp(),
        }),
      ),
    );
    await assertSucceeds(updateDoc(doc(db, fresh), { cadence: 'deepClean', recurrence: null }));
    await assertSucceeds(deleteDoc(doc(db, fresh)));
  });

  it('refuses a routine the shape does not allow', async () => {
    const db = await as('admin');
    const bad = (overrides: Record<string, unknown>): Record<string, unknown> =>
      routineData(CLEANER, { createdAt: serverTimestamp(), ...overrides });
    await assertFails(setDoc(doc(db, fresh), bad({ cadence: 'hourly' })));
    await assertFails(setDoc(doc(db, fresh), bad({ items: [] })));
    await assertFails(setDoc(doc(db, fresh), bad({ helperId: 'm-nobody' })));
    await assertFails(setDoc(doc(db, fresh), bad({ firstDate: '29/09/2026' })));
    await assertFails(setDoc(doc(db, fresh), bad({ recurrence: 'daily' })));
    await assertFails(setDoc(doc(db, fresh), bad({ createdBy: CLEANER })));
    await assertFails(setDoc(doc(db, fresh), bad({ createdAt: new Date(0) })));
    await assertFails(setDoc(doc(db, fresh), bad({ colour: 'red' })));
  });

  it('never lets a change rewrite who made it', async () => {
    const db = await as('admin');
    await assertFails(updateDoc(doc(db, ROUTINES.cleaners), { createdBy: CLEANER }));
  });

  it('denies every helper, the carer and the kid writing a routine', async () => {
    for (const person of ['cleaner', 'viewer', 'carer', 'kid'] as Person[]) {
      const db = await as(person);
      const by = PEOPLE[person].member;
      await assertFails(
        setDoc(doc(db, fresh), routineData(by, { createdBy: by, createdAt: serverTimestamp() })),
      );
      await assertFails(updateDoc(doc(db, ROUTINES.cleaners), { name: 'Mine now' }));
      await assertFails(deleteDoc(doc(db, ROUTINES.cleaners)));
    }
  });
});

describe('ticking a day', () => {
  const tick = (
    routineId: string,
    helperId: string,
    by: string,
    done: string[] = ['i1'],
  ): Record<string, unknown> => tickData(routineId, helperId, { updatedBy: by, doneItemIds: done });

  it('lets the cleaner tick and untick her own routine’s day', async () => {
    const db = await as('cleaner');
    const path = tickPath('kitchen-daily');
    await assertSucceeds(setDoc(doc(db, path), tick('kitchen-daily', CLEANER, CLEANER)));
    await assertSucceeds(
      setDoc(doc(db, path), tick('kitchen-daily', CLEANER, CLEANER, ['i1', 'i2'])),
    );
    await assertSucceeds(setDoc(doc(db, path), tick('kitchen-daily', CLEANER, CLEANER, [])));
  });

  it('lets the look-only helper tick only her own routine', async () => {
    const db = await as('viewer');
    await assertSucceeds(
      setDoc(doc(db, tickPath('windows-weekly')), tick('windows-weekly', VIEWER, VIEWER)),
    );
    await assertFails(
      setDoc(doc(db, tickPath('kitchen-daily')), tick('kitchen-daily', CLEANER, VIEWER)),
    );
  });

  it('lets family tick anybody’s routine, in their own name', async () => {
    const db = await as('admin');
    await assertSucceeds(
      setDoc(doc(db, tickPath('garage-sweep')), tick('garage-sweep', 'm-unclaimed', ADMIN)),
    );
    await assertFails(
      setDoc(doc(db, tickPath('garage-sweep')), tick('garage-sweep', 'm-unclaimed', CLEANER)),
    );
  });

  it('denies the cleaner ticking somebody else’s routine', async () => {
    const db = await as('cleaner');
    await assertFails(
      setDoc(doc(db, tickPath('garage-sweep')), tick('garage-sweep', 'm-unclaimed', CLEANER)),
    );
  });

  it('refuses a tick filed under a helper who is not the routine’s', async () => {
    const db = await as('admin');
    await assertFails(
      setDoc(doc(db, tickPath('kitchen-daily')), tick('kitchen-daily', VIEWER, ADMIN)),
    );
  });

  it('refuses a tick whose id is not its routine and its day', async () => {
    const db = await as('cleaner');
    await assertFails(
      setDoc(
        doc(db, `${HOME}/homeCareRoutineTicks/kitchen-daily_2026-01-01`),
        tick('kitchen-daily', CLEANER, CLEANER),
      ),
    );
  });

  it('refuses more items done than the routine has', async () => {
    const db = await as('cleaner');
    await assertFails(
      setDoc(
        doc(db, tickPath('kitchen-daily')),
        tick('kitchen-daily', CLEANER, CLEANER, ['i1', 'i2', 'i3', 'i4']),
      ),
    );
  });

  it('refuses a tick for a routine that does not exist', async () => {
    const db = await as('admin');
    await assertFails(setDoc(doc(db, tickPath('gone')), tick('gone', CLEANER, ADMIN)));
  });

  it('refuses a client’s clock and a tick in the future’s shape', async () => {
    const db = await as('cleaner');
    await assertFails(
      setDoc(doc(db, tickPath('kitchen-daily')), {
        ...tick('kitchen-daily', CLEANER, CLEANER),
        updatedAt: new Date(0),
      }),
    );
  });

  it('denies the carer, the kid and the tablet any tick', async () => {
    for (const db of [await as('carer'), await as('kid'), await tablet()]) {
      await assertFails(
        setDoc(doc(db, tickPath('kitchen-daily')), tick('kitchen-daily', CLEANER, CLEANER)),
      );
    }
  });

  it('lets only family remove a tick', async () => {
    await assertFails(deleteDoc(doc(await as('cleaner'), tickPath('kitchen-daily'))));
    await assertSucceeds(deleteDoc(doc(await as('parent'), tickPath('kitchen-daily'))));
  });
});
