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
  writeBatch,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  HOME,
  KID_DEVICE,
  PEOPLE,
  givenAHouseholdOfEveryRole,
  type Person,
} from './access_fixture';
import {
  JOBS,
  PRODUCT,
  ROOM,
  STEPS,
  eventPath,
  givenHomeCareRecords,
  jobData,
} from './home_care_fixture';
import {
  asKid,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  type Firestore,
} from './rules_harness';

/**
 * Cleaning jobs by the `homeCare` grant (home-care ADR-0001, household
 * ADR-0003). The cleaner holds `own`: she reads and works only the jobs whose
 * helper is her profile, and asks for exactly those. The look-only helper
 * holds `view`: she reads every job and works only her own. The carer and the
 * kid hold `none`. Family does everything, including the review.
 */

const as = (person: Person): Promise<Firestore> => asUser(PEOPLE[person].uid);

const tablet = (): Promise<Firestore> =>
  asKid(KID_DEVICE, { householdId: 'h-access', memberId: PEOPLE.kid.member });

interface Change {
  job: string;
  fields: Record<string, unknown>;
  revision?: number;
  event?: { status: string; by: string; note?: string | null };
}

/** A status change the way the app writes one: the job and its event in one batch. */
function change(db: Firestore, { job, fields, revision, event }: Change): Promise<void> {
  const batch = writeBatch(db);
  batch.update(doc(db, job), { ...fields, updatedAt: serverTimestamp() });
  if (event !== undefined && revision !== undefined) {
    batch.set(doc(db, eventPath(job, revision)), {
      status: event.status,
      by: event.by,
      note: event.note ?? null,
      at: serverTimestamp(),
    });
  }
  return batch.commit();
}

const CLEANER = PEOPLE.cleaner.member;
const ADMIN = PEOPLE.admin.member;
const AFTER = (revision: number): Record<string, unknown> => ({
  photoId: `after-${String(revision)}`,
  width: 1200,
  height: 1600,
});

beforeEach(async () => {
  await clearData();
  await givenAHouseholdOfEveryRole();
  await givenHomeCareRecords();
});

describe('reading rooms and products', () => {
  const readers: Person[] = [
    'admin',
    'parent',
    'legacyMember',
    'legacyHelper',
    'cleaner',
    'viewer',
  ];
  for (const person of readers) {
    it(`lets the ${person} read the rooms and the product guide`, async () => {
      const db = await as(person);
      await assertSucceeds(getDoc(doc(db, ROOM)));
      await assertSucceeds(getDoc(doc(db, PRODUCT)));
    });
  }

  for (const person of ['carer', 'kid'] as Person[]) {
    it(`denies the ${person}, whose grant has no home care in it`, async () => {
      const db = await as(person);
      await assertFails(getDoc(doc(db, ROOM)));
      await assertFails(getDoc(doc(db, PRODUCT)));
    });
  }

  it('denies the kid’s tablet too', async () => {
    await assertFails(getDoc(doc(await tablet(), PRODUCT)));
  });
});

describe('reading jobs', () => {
  it('lets family and the look-only helper read every job and its history', async () => {
    for (const person of ['admin', 'parent', 'legacyHelper', 'viewer'] as Person[]) {
      const db = await as(person);
      await assertSucceeds(getDoc(doc(db, JOBS.nobodys)));
      await assertSucceeds(getDocs(collection(db, `${HOME}/homeCareJobs`)));
      await assertSucceeds(getDocs(collection(db, `${JOBS.nobodys}/events`)));
    }
  });

  it('lets the cleaner read her own job and its history', async () => {
    const db = await as('cleaner');
    await assertSucceeds(getDoc(doc(db, JOBS.cleaners)));
    await assertSucceeds(getDocs(collection(db, `${JOBS.cleaners}/events`)));
  });

  it('lets the cleaner ask for exactly her own jobs', async () => {
    const db = await as('cleaner');
    await assertSucceeds(
      getDocs(query(collection(db, `${HOME}/homeCareJobs`), where('helperId', '==', CLEANER))),
    );
  });

  it('denies the cleaner somebody else’s job, its history, and the whole list', async () => {
    const db = await as('cleaner');
    await assertFails(getDoc(doc(db, JOBS.nobodys)));
    await assertFails(getDocs(collection(db, `${JOBS.nobodys}/events`)));
    await assertFails(getDocs(collection(db, `${HOME}/homeCareJobs`)));
  });

  it('denies the carer, the kid and the kid’s tablet any job', async () => {
    await assertFails(getDoc(doc(await as('carer'), JOBS.cleaners)));
    await assertFails(getDoc(doc(await as('kid'), JOBS.cleaners)));
    await assertFails(getDoc(doc(await tablet(), JOBS.cleaners)));
  });
});

describe('the room and product library', () => {
  const room = (by: string, kind = 'bathroom'): Record<string, unknown> => ({
    name: 'Main bathroom',
    kind,
    createdBy: by,
    createdAt: serverTimestamp(),
  });
  const product = (
    by: string,
    overrides: Record<string, unknown> = {},
  ): Record<string, unknown> => ({
    name: 'Handy Andy',
    kind: 'allPurpose',
    whereKept: 'Laundry cupboard',
    note: null,
    keepFromChildren: false,
    keepFromPets: false,
    createdBy: by,
    createdAt: serverTimestamp(),
    ...overrides,
  });

  it('lets a parent add, rename and remove a room and a product', async () => {
    const db = await as('parent');
    const by = PEOPLE.parent.member;
    await assertSucceeds(setDoc(doc(db, `${HOME}/homeCareRooms/bath`), room(by)));
    await assertSucceeds(updateDoc(doc(db, `${HOME}/homeCareRooms/bath`), { name: 'Guest bath' }));
    await assertSucceeds(setDoc(doc(db, `${HOME}/homeCareProducts/andy`), product(by)));
    await assertSucceeds(
      updateDoc(doc(db, PRODUCT), { whereKept: 'Top shelf', keepFromPets: false }),
    );
    await assertSucceeds(deleteDoc(doc(db, `${HOME}/homeCareRooms/bath`)));
    await assertSucceeds(deleteDoc(doc(db, `${HOME}/homeCareProducts/andy`)));
  });

  it('refuses a kind the safety catalogue does not know', async () => {
    const db = await as('admin');
    await assertFails(setDoc(doc(db, `${HOME}/homeCareRooms/bath`), room(ADMIN, 'dungeon')));
    await assertFails(
      setDoc(doc(db, `${HOME}/homeCareProducts/x`), product(ADMIN, { kind: 'mystery' })),
    );
  });

  it('refuses a product without both safety flags', async () => {
    const db = await as('admin');
    const withoutPets = product(ADMIN);
    delete withoutPets.keepFromPets;
    await assertFails(setDoc(doc(db, `${HOME}/homeCareProducts/x`), withoutPets));
  });

  it('refuses a room written in somebody else’s name', async () => {
    const db = await as('parent');
    await assertFails(setDoc(doc(db, `${HOME}/homeCareRooms/bath`), room(ADMIN)));
  });

  it('denies the cleaner and the look-only helper any change to the library', async () => {
    for (const person of ['cleaner', 'viewer'] as Person[]) {
      const db = await as(person);
      const by = PEOPLE[person].member;
      await assertFails(setDoc(doc(db, `${HOME}/homeCareRooms/bath`), room(by)));
      await assertFails(setDoc(doc(db, `${HOME}/homeCareProducts/x`), product(by)));
      await assertFails(updateDoc(doc(db, PRODUCT), { name: 'Bleach' }));
      await assertFails(deleteDoc(doc(db, ROOM)));
    }
  });
});

describe('creating a job', () => {
  const NEW = `${HOME}/homeCareJobs/stain`;

  function create(db: Firestore, data: Record<string, unknown>, withEvent = true): Promise<void> {
    const batch = writeBatch(db);
    batch.set(doc(db, NEW), {
      ...data,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    if (withEvent) {
      batch.set(doc(db, eventPath(NEW, 0)), {
        status: 'assigned',
        by: data.createdBy,
        note: null,
        at: serverTimestamp(),
      });
    }
    return batch.commit();
  }

  it('lets a parent assign a job with its first history event', async () => {
    await assertSucceeds(create(await as('admin'), jobData(CLEANER)));
  });

  it('refuses a job with no history event', async () => {
    await assertFails(create(await as('admin'), jobData(CLEANER), false));
  });

  it('refuses a job that starts anywhere but assigned', async () => {
    const db = await as('admin');
    await assertFails(create(db, jobData(CLEANER, { status: 'approved' })));
    await assertFails(create(db, jobData(CLEANER, { revision: 3 })));
    await assertFails(create(db, jobData(CLEANER, { doneStepIds: ['s1'] })));
  });

  it('refuses a helper who is not in the household, and a date that is not a date', async () => {
    const db = await as('admin');
    await assertFails(create(db, jobData('m-nobody')));
    await assertFails(create(db, jobData(CLEANER, { dueDate: '29/09/2026' })));
  });

  it('refuses a job with no steps, or a before photo under another name', async () => {
    const db = await as('admin');
    await assertFails(create(db, jobData(CLEANER, { steps: [] })));
    await assertFails(
      create(db, jobData(CLEANER, { beforePhoto: { photoId: 'after-1', width: 10, height: 10 } })),
    );
  });

  it('refuses a job made in somebody else’s name', async () => {
    const db = await as('parent');
    await assertFails(create(db, jobData(CLEANER)));
  });

  it('denies the cleaner and the look-only helper', async () => {
    await assertFails(create(await as('cleaner'), jobData(CLEANER, { createdBy: CLEANER })));
    await assertFails(
      create(await as('viewer'), jobData(CLEANER, { createdBy: PEOPLE.viewer.member })),
    );
  });
});

describe('the helper working through her job', () => {
  it('ticks steps, starting the job with the first', async () => {
    const db = await as('cleaner');
    await assertSucceeds(
      change(db, {
        job: JOBS.cleaners,
        fields: { doneStepIds: ['s1'], status: 'inProgress', revision: 1 },
        revision: 1,
        event: { status: 'inProgress', by: CLEANER },
      }),
    );
    await assertSucceeds(change(db, { job: JOBS.cleaners, fields: { doneStepIds: ['s1', 's2'] } }));
    await assertSucceeds(change(db, { job: JOBS.cleaners, fields: { doneStepIds: ['s2'] } }));
  });

  it('refuses a start with no history event', async () => {
    const db = await as('cleaner');
    await assertFails(
      change(db, {
        job: JOBS.cleaners,
        fields: { doneStepIds: ['s1'], status: 'inProgress', revision: 1 },
      }),
    );
  });

  it('refuses a history event that does not match the change', async () => {
    const db = await as('cleaner');
    await assertFails(
      change(db, {
        job: JOBS.cleaners,
        fields: { doneStepIds: ['s1'], status: 'inProgress', revision: 1 },
        revision: 1,
        event: { status: 'approved', by: CLEANER },
      }),
    );
    await assertFails(
      change(db, {
        job: JOBS.cleaners,
        fields: { doneStepIds: ['s1'], status: 'inProgress', revision: 1 },
        revision: 1,
        event: { status: 'inProgress', by: ADMIN },
      }),
    );
  });

  it('hands in with every step ticked and an after photo', async () => {
    const db = await as('cleaner');
    await assertSucceeds(
      change(db, {
        job: JOBS.cleaners,
        fields: {
          doneStepIds: ['s1', 's2'],
          status: 'submitted',
          revision: 1,
          afterPhoto: AFTER(1),
        },
        revision: 1,
        event: { status: 'submitted', by: CLEANER },
      }),
    );
  });

  it('refuses a hand-in with a step left, or an after photo under the wrong name', async () => {
    const db = await as('cleaner');
    await assertFails(
      change(db, {
        job: JOBS.cleaners,
        fields: { doneStepIds: ['s1'], status: 'submitted', revision: 1, afterPhoto: AFTER(1) },
        revision: 1,
        event: { status: 'submitted', by: CLEANER },
      }),
    );
    await assertFails(
      change(db, {
        job: JOBS.cleaners,
        fields: {
          doneStepIds: ['s1', 's2'],
          status: 'submitted',
          revision: 1,
          afterPhoto: AFTER(7),
        },
        revision: 1,
        event: { status: 'submitted', by: CLEANER },
      }),
    );
  });

  it('refuses her approving her own work, or changing what the job says', async () => {
    const db = await as('cleaner');
    await assertFails(
      change(db, {
        job: JOBS.cleaners,
        fields: { status: 'approved', revision: 1 },
        revision: 1,
        event: { status: 'approved', by: CLEANER },
      }),
    );
    await assertFails(change(db, { job: JOBS.cleaners, fields: { title: 'Nothing' } }));
    await assertFails(
      change(db, { job: JOBS.cleaners, fields: { helperId: PEOPLE.viewer.member } }),
    );
  });

  it('denies her anybody else’s job', async () => {
    const db = await as('cleaner');
    await assertFails(change(db, { job: JOBS.nobodys, fields: { doneStepIds: ['s1'] } }));
  });

  it('lets the look-only helper work her own job but nobody else’s', async () => {
    const db = await as('viewer');
    await assertSucceeds(change(db, { job: JOBS.viewers, fields: { doneStepIds: ['s1'] } }));
    await assertFails(change(db, { job: JOBS.cleaners, fields: { doneStepIds: ['s1'] } }));
  });

  it('denies the carer and the kid', async () => {
    for (const person of ['carer', 'kid'] as Person[]) {
      await assertFails(
        change(await as(person), { job: JOBS.cleaners, fields: { doneStepIds: ['s1'] } }),
      );
    }
  });
});

describe('reviewing a job that was handed in', () => {
  beforeEach(async () => {
    await givenHomeCareRecords({
      cleaners: {
        status: 'submitted',
        revision: 2,
        doneStepIds: ['s1', 's2'],
        afterPhoto: AFTER(2),
      },
    });
  });

  it('lets a parent approve it', async () => {
    await assertSucceeds(
      change(await as('parent'), {
        job: JOBS.cleaners,
        fields: { status: 'approved', revision: 3 },
        revision: 3,
        event: { status: 'approved', by: PEOPLE.parent.member },
      }),
    );
  });

  it('lets a parent send it back with a note the history carries', async () => {
    await assertSucceeds(
      change(await as('admin'), {
        job: JOBS.cleaners,
        fields: { status: 'sentBack', revision: 3, reviewNote: 'The corner is still greasy' },
        revision: 3,
        event: { status: 'sentBack', by: ADMIN, note: 'The corner is still greasy' },
      }),
    );
  });

  it('refuses sending it back with no note, or a history note that differs', async () => {
    const db = await as('admin');
    await assertFails(
      change(db, {
        job: JOBS.cleaners,
        fields: { status: 'sentBack', revision: 3, reviewNote: '' },
        revision: 3,
        event: { status: 'sentBack', by: ADMIN, note: '' },
      }),
    );
    await assertFails(
      change(db, {
        job: JOBS.cleaners,
        fields: { status: 'sentBack', revision: 3, reviewNote: 'Again please' },
        revision: 3,
        event: { status: 'sentBack', by: ADMIN, note: 'Something else' },
      }),
    );
  });

  it('refuses editing what a handed-in job says', async () => {
    await assertFails(
      change(await as('admin'), { job: JOBS.cleaners, fields: { title: 'Changed' } }),
    );
  });

  it('denies the look-only helper and the cleaner the review', async () => {
    for (const person of ['viewer', 'cleaner'] as Person[]) {
      await assertFails(
        change(await as(person), {
          job: JOBS.cleaners,
          fields: { status: 'approved', revision: 3 },
          revision: 3,
          event: { status: 'approved', by: PEOPLE[person].member },
        }),
      );
    }
  });

  it('refuses approving a job nobody has handed in', async () => {
    await assertFails(
      change(await as('admin'), {
        job: JOBS.nobodys,
        fields: { status: 'approved', revision: 1 },
        revision: 1,
        event: { status: 'approved', by: ADMIN },
      }),
    );
  });
});

describe('changing and removing a job', () => {
  it('lets a parent change the details of a job still with the helper', async () => {
    await assertSucceeds(
      change(await as('admin'), {
        job: JOBS.cleaners,
        fields: {
          title: 'Oven and hob',
          dueDate: '2026-10-02',
          steps: [...STEPS, { id: 's3', text: 'Dry' }],
        },
      }),
    );
  });

  it('lets a parent delete a job and its history, and nobody else', async () => {
    await assertFails(deleteDoc(doc(await as('cleaner'), JOBS.cleaners)));
    await assertFails(deleteDoc(doc(await as('viewer'), eventPath(JOBS.cleaners, 0))));
    const db = await as('admin');
    await assertSucceeds(deleteDoc(doc(db, eventPath(JOBS.cleaners, 0))));
    await assertSucceeds(deleteDoc(doc(db, JOBS.cleaners)));
  });

  it('never lets anybody rewrite a history event', async () => {
    await assertFails(
      updateDoc(doc(await as('admin'), eventPath(JOBS.cleaners, 0)), { status: 'approved' }),
    );
  });
});
