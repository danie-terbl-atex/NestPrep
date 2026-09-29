import { deleteDoc, doc, getDoc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { CLEO, MIA, NOMSA, OLIVIA, SAM, STRANGER } from './family_fixture';
import {
  APPLE,
  FAVOURITES,
  ITEMS,
  PREP,
  WEEK,
  WRAP,
  ZOLA,
  givenTheLunchHousehold,
  kidsTablet,
} from './lunch_box_fixture';
import { asUser, assertFails, assertSucceeds, clearData, givenData } from './rules_harness';

/**
 * The rest of lunch-box (lunch-box ADR-0001, ADR-0003): the household's
 * library, a child's go-to boxes and the Sunday prep ticks — all the `lunch`
 * grant, `edit` to change and `view` to read.
 */

beforeEach(async () => {
  await clearData();
  await givenTheLunchHousehold();
  await givenData(async (db) => {
    await setDoc(doc(db, `${ITEMS}/apple`), {
      name: 'Apple',
      nameKey: 'apple',
      slot: 'fruit',
      allergens: [],
      addedBy: 'm-sam',
      createdAt: new Date(),
    });
  });
});

const newItem = {
  name: 'Peanut butter sandwich',
  nameKey: 'peanut butter sandwich',
  slot: 'main',
  allergens: ['peanut', 'wheat'],
  prepAhead: false,
  prepNote: null,
  archived: false,
  seedKey: null,
  addedBy: 'm-sam',
  createdAt: serverTimestamp(),
};

describe('lunchItems/{itemId}', () => {
  it('family adds an item in their own name, saying what is in it', async () => {
    await assertSucceeds(setDoc(doc(await asUser(SAM), `${ITEMS}/pb`), newItem));
    await assertSucceeds(
      setDoc(doc(await asUser(MIA), `${ITEMS}/pb2`), { ...newItem, addedBy: 'm-mia' }),
    );
  });

  it('refuses a stranger’s, a carer’s and a tablet’s', async () => {
    for (const db of [await asUser(STRANGER), await asUser(NOMSA), await kidsTablet()]) {
      await assertFails(setDoc(doc(db, `${ITEMS}/pb`), newItem));
    }
  });

  it('refuses one in somebody else’s name, or that dates itself', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, `${ITEMS}/pb`), { ...newItem, addedBy: 'm-mia' }));
    await assertFails(setDoc(doc(db, `${ITEMS}/pb`), { ...newItem, createdAt: new Date() }));
  });

  it('refuses an item the checks could not read', async () => {
    const db = await asUser(SAM);
    for (const bad of [
      { slot: 'dessert' },
      { allergens: ['lupin'] },
      { allergens: 'peanut' },
      { nameKey: 'Peanut Butter Sandwich' },
      { name: '' },
      { name: 'x'.repeat(61) },
      { prepNote: 'x'.repeat(141) },
      { archived: true },
      { price: 12 },
    ]) {
      await assertFails(setDoc(doc(db, `${ITEMS}/bad`), { ...newItem, ...bad }));
    }
  });

  it('family edits what it contains and puts it away', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(updateDoc(doc(db, `${ITEMS}/apple`), { allergens: ['sesame'] }));
    await assertSucceeds(updateDoc(doc(db, `${ITEMS}/apple`), { archived: true }));
  });

  it('never moves its slot or its author, and is never deleted', async () => {
    const db = await asUser(SAM);
    await assertFails(updateDoc(doc(db, `${ITEMS}/apple`), { slot: 'veg' }));
    await assertFails(updateDoc(doc(db, `${ITEMS}/apple`), { addedBy: 'm-mia' }));
    await assertFails(deleteDoc(doc(db, `${ITEMS}/apple`)));
  });

  it('a carer reads the library and changes nothing in it', async () => {
    const db = await asUser(NOMSA);
    await assertSucceeds(getDoc(doc(db, `${ITEMS}/apple`)));
    await assertFails(updateDoc(doc(db, `${ITEMS}/apple`), { archived: true }));
  });

  it('a cleaner, a tablet at own and another household read nothing', async () => {
    for (const db of [await asUser(CLEO), await kidsTablet(), await asUser(OLIVIA)]) {
      await assertFails(getDoc(doc(db, `${ITEMS}/apple`)));
    }
  });
});

const favourite = {
  childId: ZOLA,
  name: 'Friday special',
  picks: { main: WRAP, fruit: APPLE },
  createdBy: 'm-sam',
  createdAt: serverTimestamp(),
};

describe('lunchFavourites/{favouriteId}', () => {
  it('family keeps a go-to box for a child', async () => {
    await assertSucceeds(setDoc(doc(await asUser(SAM), `${FAVOURITES}/f1`), favourite));
  });

  it('refuses one for an adult, empty, with an unknown slot, or in another’s name', async () => {
    const db = await asUser(SAM);
    for (const bad of [
      { childId: 'm-sam' },
      { picks: {} },
      { picks: { dessert: APPLE } },
      { picks: { main: { itemId: 'x', name: 'X', allergens: ['lupin'] } } },
      { createdBy: 'm-mia' },
      { name: 'x'.repeat(41) },
    ]) {
      await assertFails(setDoc(doc(db, `${FAVOURITES}/bad`), { ...favourite, ...bad }));
    }
  });

  it('family renames and removes one; a carer only reads', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${FAVOURITES}/f1`), { ...favourite, createdAt: new Date() });
    });
    const carer = await asUser(NOMSA);
    await assertSucceeds(getDoc(doc(carer, `${FAVOURITES}/f1`)));
    await assertFails(updateDoc(doc(carer, `${FAVOURITES}/f1`), { name: 'Mine' }));
    await assertFails(deleteDoc(doc(carer, `${FAVOURITES}/f1`)));
    const parent = await asUser(MIA);
    await assertSucceeds(updateDoc(doc(parent, `${FAVOURITES}/f1`), { name: 'Monday' }));
    await assertFails(updateDoc(doc(parent, `${FAVOURITES}/f1`), { childId: 'm-kid' }));
    await assertSucceeds(deleteDoc(doc(parent, `${FAVOURITES}/f1`)));
  });

  it('a cleaner and a stranger read none', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${FAVOURITES}/f1`), { ...favourite, createdAt: new Date() });
    });
    for (const uid of [CLEO, STRANGER]) {
      await assertFails(getDoc(doc(await asUser(uid), `${FAVOURITES}/f1`)));
    }
  });
});

describe('lunchPrep/{week}', () => {
  it('family ticks the week’s prep', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, `${PREP}/${WEEK}`), { done: ['apple'] }));
    await assertSucceeds(setDoc(doc(db, `${PREP}/${WEEK}`), { done: [] }, { merge: true }));
  });

  it('only under a week, with nothing but the ticks', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, `${PREP}/next-week`), { done: [] }));
    await assertFails(setDoc(doc(db, `${PREP}/${WEEK}`), { done: [], by: 'm-sam' }));
    await assertFails(setDoc(doc(db, `${PREP}/${WEEK}`), { done: 'apple' }));
  });

  it('a carer reads it and ticks nothing; a cleaner reads nothing', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${PREP}/${WEEK}`), { done: [] });
    });
    const carer = await asUser(NOMSA);
    await assertSucceeds(getDoc(doc(carer, `${PREP}/${WEEK}`)));
    await assertFails(setDoc(doc(carer, `${PREP}/${WEEK}`), { done: ['apple'] }));
    await assertFails(getDoc(doc(await asUser(CLEO), `${PREP}/${WEEK}`)));
  });

  it('is never deleted', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${PREP}/${WEEK}`), { done: [] });
    });
    await assertFails(deleteDoc(doc(await asUser(SAM), `${PREP}/${WEEK}`)));
  });
});
