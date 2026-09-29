import { collection, doc, getDoc, getDocs, query, where } from 'firebase/firestore';
import { beforeAll, describe, it } from 'vitest';

import {
  HOME,
  PEOPLE,
  RECORDS,
  expectsToView,
  givenAHouseholdOfEveryRole,
  type GuardedArea,
  type Person,
} from './access_fixture';
import { asUser, assertFails, assertSucceeds, clearData } from './rules_harness';

/**
 * What each role may **read**, for every role and every guarded collection
 * (household ADR-0003).
 *
 * The expectation is computed from the ADR's table — family sees everything, a
 * grant of `view` or `edit` sees the area, anything else does not, and a
 * helper with no grant keeps what every helper had — so each pair below is
 * either an allowed or a denied case, and both kinds exist for every area.
 * The writes, the `own` scope and the membership rules are in
 * `access_writes.rules.test.ts`.
 */
const everyone = Object.keys(PEOPLE) as Person[];
const areas = Object.keys(RECORDS) as GuardedArea[];

describe('reading a household, by role and by area', () => {
  beforeAll(async () => {
    await clearData();
    await givenAHouseholdOfEveryRole();
  });

  for (const person of everyone) {
    for (const area of areas) {
      const allowed = expectsToView(person, area);
      for (const path of RECORDS[area]) {
        const record = path.slice(HOME.length + 1);
        it(`${allowed ? 'lets' : 'denies'} ${person} read ${record}`, async () => {
          const read = getDoc(doc(await asUser(PEOPLE[person].uid), path));
          await (allowed ? assertSucceeds(read) : assertFails(read));
        });
      }
    }
  }

  it('lets every role read the household and its people, whom every task names', async () => {
    for (const person of everyone) {
      const db = await asUser(PEOPLE[person].uid);
      await assertSucceeds(getDoc(doc(db, HOME)));
      await assertSucceeds(getDocs(collection(db, `${HOME}/members`)));
    }
  });

  it('denies a stranger everything, whatever the household grants anybody', async () => {
    const db = await asUser('uid-stranger');
    await assertFails(getDoc(doc(db, HOME)));
    for (const paths of Object.values(RECORDS)) {
      for (const path of paths) await assertFails(getDoc(doc(db, path)));
    }
  });
});

describe('a helper who may only clean', () => {
  beforeAll(async () => {
    await clearData();
    await givenAHouseholdOfEveryRole();
  });

  it('cannot list the documents or the folders', async () => {
    const db = await asUser(PEOPLE.cleaner.uid);
    await assertFails(getDocs(collection(db, `${HOME}/documents`)));
    await assertFails(getDocs(collection(db, `${HOME}/documentFolders`)));
  });

  it('cannot list the calendar, the groceries, the meals or the to-dos', async () => {
    const db = await asUser(PEOPLE.cleaner.uid);
    for (const name of ['events', 'groceryItems', 'meals', 'mealPlans', 'tasks', 'routines']) {
      await assertFails(getDocs(collection(db, `${HOME}/${name}`)));
    }
  });

  it('while a parent lists all of it', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    for (const name of ['documents', 'events', 'groceryItems', 'tasks', 'routines']) {
      await assertSucceeds(getDocs(collection(db, `${HOME}/${name}`)));
    }
  });
});

describe('`own`: a kid reads their own chores and nobody else’s', () => {
  beforeAll(async () => {
    await clearData();
    await givenAHouseholdOfEveryRole();
  });

  it('reads a task assigned to them', async () => {
    const db = await asUser(PEOPLE.kid.uid);
    await assertSucceeds(getDoc(doc(db, `${HOME}/tasks/homework`)));
  });

  it('does not read a task for somebody else, or one for anyone', async () => {
    const db = await asUser(PEOPLE.kid.uid);
    await assertFails(getDoc(doc(db, `${HOME}/tasks/tax`)));
    await assertFails(getDoc(doc(db, `${HOME}/tasks/bins`)));
  });

  it('lists their chores when it asks for exactly those', async () => {
    const db = await asUser(PEOPLE.kid.uid);
    const mine = query(
      collection(db, `${HOME}/tasks`),
      where('assigneeIds', 'array-contains', PEOPLE.kid.member),
    );
    await assertSucceeds(getDocs(mine));
  });

  it('is refused the whole list, and a list filtered for somebody else', async () => {
    const db = await asUser(PEOPLE.kid.uid);
    await assertFails(getDocs(collection(db, `${HOME}/tasks`)));
    const theirs = query(
      collection(db, `${HOME}/tasks`),
      where('assigneeIds', 'array-contains', PEOPLE.admin.member),
    );
    await assertFails(getDocs(theirs));
  });

  it('lists what they have done, and not what anybody else has', async () => {
    const db = await asUser(PEOPLE.kid.uid);
    const done = collection(db, `${HOME}/taskCompletions`);
    await assertSucceeds(getDocs(query(done, where('completedFor', '==', PEOPLE.kid.member))));
    await assertFails(getDocs(query(done, where('completedFor', '==', PEOPLE.admin.member))));
    await assertFails(getDocs(done));
  });

  it('cannot read the routines, which schedule everybody', async () => {
    await assertFails(getDoc(doc(await asUser(PEOPLE.kid.uid), RECORDS.todos[1])));
  });
});
