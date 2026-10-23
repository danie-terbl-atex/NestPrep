import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { PEOPLE } from './access_fixture';
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
 * The catalogue NestPrep publishes (recipes ADR-0001, ADR-0003, lunch-box ADR-0018):
 * `recipes/{id}` and `lunchStarterBoxes/{id}` are nobody's data, so anybody
 * signed in reads them; no client writes them — the catalogue seed does, as
 * the Admin SDK — and a list is bounded.
 */
const RECIPE = 'recipes/banana-oat-bites';
const BOX = 'lunchStarterBoxes/classic-sandwich';

const recipe = {
  name: 'Banana oat bites',
  status: 'published',
  version: 1,
  contexts: ['lunchBox'],
  placement: { lunchBox: 'treat' },
};
const box = { name: 'Classic sandwich box', status: 'published', order: 1, version: 1, picks: {} };

beforeEach(async () => {
  await clearData();
  await givenData(async (db) => {
    await setDoc(doc(db, RECIPE), recipe);
    await setDoc(doc(db, BOX), box);
  });
});

describe('recipes/{recipeId}', () => {
  it('is read by anybody signed in, and by nobody signed out', async () => {
    await assertSucceeds(getDoc(doc(await asUser(PEOPLE.admin.uid), RECIPE)));
    await assertSucceeds(getDoc(doc(await asUser(PEOPLE.cleaner.uid), RECIPE)));
    await assertFails(getDoc(doc(await asSignedOut(), RECIPE)));
  });

  it('is listed only in bounded pages of 200 at most (ADR-0003 §7)', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    await assertSucceeds(getDocs(query(collection(db, 'recipes'), limit(200))));
    await assertFails(getDocs(query(collection(db, 'recipes'), limit(201))));
    await assertFails(getDocs(collection(db, 'recipes')));
  });

  it('lists the published catalogue by name, as the recipes view asks for it', async () => {
    const published = (db: Firestore, pageSize: number): Promise<unknown> =>
      getDocs(
        query(
          collection(db, 'recipes'),
          where('status', '==', 'published'),
          orderBy('name'),
          limit(pageSize),
        ),
      );
    await assertSucceeds(published(await asUser(PEOPLE.cleaner.uid), 200));
    await assertFails(published(await asUser(PEOPLE.admin.uid), 201));
    await assertFails(published(await asSignedOut(), 200));
  });

  it('is written by no client — not an admin, not anybody signed out', async () => {
    for (const db of [await asUser(PEOPLE.admin.uid), await asSignedOut()]) {
      await assertFails(setDoc(doc(db, 'recipes/new-one'), recipe));
      await assertFails(updateDoc(doc(db, RECIPE), { status: 'retired' }));
      await assertFails(deleteDoc(doc(db, RECIPE)));
    }
  });
});

describe('lunchStarterBoxes/{boxId}', () => {
  const published = (db: Firestore, pageSize: number): Promise<unknown> =>
    getDocs(
      query(
        collection(db, 'lunchStarterBoxes'),
        where('status', '==', 'published'),
        orderBy('order'),
        limit(pageSize),
      ),
    );

  it('lets anybody signed in list the published boxes, twenty at most', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    await assertSucceeds(published(db, 20));
    await assertSucceeds(getDoc(doc(db, BOX)));
    await assertFails(published(db, 21));
    await assertFails(getDocs(collection(db, 'lunchStarterBoxes')));
  });

  it('shows nobody signed out a box', async () => {
    const db = await asSignedOut();
    await assertFails(getDoc(doc(db, BOX)));
    await assertFails(published(db, 20));
  });

  it('is written by no client — not an admin, not anybody signed out', async () => {
    for (const db of [await asUser(PEOPLE.admin.uid), await asSignedOut()]) {
      await assertFails(setDoc(doc(db, 'lunchStarterBoxes/mine'), box));
      await assertFails(updateDoc(doc(db, BOX), { order: 0 }));
      await assertFails(deleteDoc(doc(db, BOX)));
    }
  });
});
