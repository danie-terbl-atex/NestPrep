import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import { beforeAll, describe, it } from 'vitest';

import {
  AVA,
  BEN,
  DATE,
  HOME,
  MIA,
  OLD,
  avasTablet,
  bensTablet,
  completion,
  givenAKidsHousehold,
  miasTablet,
  oldTablet,
} from './kid_fixture';
import { assertFails, assertSucceeds } from './rules_harness';

/**
 * A kid device holds the grant of the kid profile it is bound to (accounts
 * ADR-0004): what a parent chooses in the access editor is what the child's
 * tablet can open, through the same `canView` / `canEdit` / `own` every helper
 * and carer goes through — and a profile that is no longer a kid leaves its
 * devices with nothing.
 */

beforeAll(givenAKidsHousehold);

describe('and what its grant opens — the kid defaults', () => {
  it('the calendar and the grocery list, to look at', async () => {
    const db = await miasTablet();
    await assertSucceeds(getDoc(doc(db, `${HOME}/events/dentist`)));
    await assertSucceeds(getDocs(collection(db, `${HOME}/groceryItems`)));
  });

  it('but writes neither, because view is not edit', async () => {
    const db = await miasTablet();
    await assertFails(
      setDoc(doc(db, `${HOME}/groceryItems/sweets`), {
        name: 'Sweets',
        quantity: null,
        addedBy: MIA,
        addedAt: serverTimestamp(),
        boughtAt: null,
        boughtBy: null,
      }),
    );
    await assertFails(updateDoc(doc(db, `${HOME}/events/dentist`), { title: 'No dentist' }));
  });
});

describe('a parent changes the grant, and the device follows it', () => {
  it('todos at view: every task, and no ticking', async () => {
    const db = await avasTablet();
    await assertSucceeds(getDocs(collection(db, `${HOME}/tasks`)));
    await assertFails(
      setDoc(
        doc(db, `${HOME}/taskCompletions/ava-reading_${DATE}`),
        completion('ava-reading', AVA, AVA),
      ),
    );
  });

  it('meals at none: no library, no plan', async () => {
    const db = await avasTablet();
    await assertFails(getDoc(doc(db, `${HOME}/meals/pasta`)));
    await assertFails(getDoc(doc(db, `${HOME}/mealPlans/2026-09-28`)));
  });

  it('groceries at edit: adds an item as herself, never as somebody else', async () => {
    const db = await avasTablet();
    const item = (addedBy: string): object => ({
      name: 'Apples',
      quantity: null,
      addedBy,
      addedAt: serverTimestamp(),
      boughtAt: null,
      boughtBy: null,
    });
    await assertSucceeds(setDoc(doc(db, `${HOME}/groceryItems/apples`), item(AVA)));
    await assertFails(setDoc(doc(db, `${HOME}/groceryItems/pears`), item('m-sam')));
  });

  it('no grant at all: the household and its own profile, and nothing else', async () => {
    const db = await bensTablet();
    await assertSucceeds(getDoc(doc(db, HOME)));
    await assertSucceeds(getDoc(doc(db, `${HOME}/members/${BEN}`)));
    await assertFails(
      getDocs(query(collection(db, `${HOME}/tasks`), where('assigneeIds', 'array-contains', BEN))),
    );
    await assertFails(getDoc(doc(db, `${HOME}/meals/pasta`)));
    await assertFails(getDoc(doc(db, `${HOME}/events/dentist`)));
  });

  it('a profile moved off `kid`: its devices hold nothing, whatever it still stores', async () => {
    const db = await oldTablet();
    await assertFails(
      getDocs(query(collection(db, `${HOME}/tasks`), where('assigneeIds', 'array-contains', OLD))),
    );
    await assertFails(getDoc(doc(db, `${HOME}/meals/pasta`)));
    await assertFails(getDoc(doc(db, `${HOME}/routines/r-morning`)));
  });
});
