import {
  deleteDoc,
  doc,
  getDoc,
  increment,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { CLEO, KID, MIA, NOMSA, SAM, STRANGER } from './family_fixture';
import { WEEK, ZOLA, givenTheLunchHousehold, kidsTablet } from './lunch_box_fixture';
import { GROCERIES, PACKED, PANTRY, TUESDAY, givenTheLibrary } from './lunch_planning_fixture';
import { asUser, assertFails, assertSucceeds, clearData, givenData } from './rules_harness';

/**
 * The pantry (lunch-box ADR-0006): boxes' worth per library item, stocked at
 * `lunch` edit, read at view; a box marked packed takes its portions out in
 * the same batch, once, and never below nothing. And the one change to
 * groceries it needs: a line nobody typed says where it came from.
 */

beforeEach(async () => {
  await clearData();
  await givenTheLunchHousehold();
  await givenTheLibrary();
});

const entry = (portions: number, updatedBy = 'm-sam'): object => ({
  portions,
  updatedBy,
  updatedAt: serverTimestamp(),
});

const packed = (childId: string, itemIds: string[] = ['apple']): object => ({
  childId,
  date: TUESDAY,
  week: WEEK,
  itemIds,
  by: 'm-sam',
  at: serverTimestamp(),
});

async function givenStock(itemId: string, portions: number): Promise<void> {
  await givenData(async (db) => {
    await setDoc(doc(db, `${PANTRY}/${itemId}`), {
      portions,
      updatedBy: 'm-sam',
      updatedAt: new Date(),
    });
  });
}

describe('lunchPantry/{itemId}', () => {
  it('family stocks a library item in their own name, at the server’s time', async () => {
    await assertSucceeds(setDoc(doc(await asUser(SAM), `${PANTRY}/apple`), entry(5)));
    await assertSucceeds(setDoc(doc(await asUser(MIA), `${PANTRY}/wrap`), entry(2, 'm-mia')));
  });

  it('refuses a carer, a tablet, a cleaner and a stranger', async () => {
    for (const db of [
      await asUser(NOMSA),
      await kidsTablet(),
      await asUser(CLEO),
      await asUser(STRANGER),
    ]) {
      await assertFails(setDoc(doc(db, `${PANTRY}/apple`), entry(5)));
    }
  });

  it('refuses something that is not in the library', async () => {
    await assertFails(setDoc(doc(await asUser(SAM), `${PANTRY}/sushi`), entry(5)));
  });

  it('refuses a pantry below nothing, past 99, a fraction or another’s name', async () => {
    const db = await asUser(SAM);
    for (const bad of [
      entry(-1),
      entry(100),
      entry(2.5),
      entry(3, 'm-mia'),
      { ...entry(3), updatedAt: new Date() },
      { ...entry(3), note: 'hidden' },
    ]) {
      await assertFails(setDoc(doc(db, `${PANTRY}/apple`), bad));
    }
  });

  it('is read by view, not by a tablet on own', async () => {
    await givenStock('apple', 4);
    await assertSucceeds(getDoc(doc(await asUser(NOMSA), `${PANTRY}/apple`)));
    await assertFails(getDoc(doc(await kidsTablet(), `${PANTRY}/apple`)));
    await assertFails(getDoc(doc(await asUser(CLEO), `${PANTRY}/apple`)));
  });

  it('is taken out by family and not by a carer', async () => {
    await givenStock('apple', 4);
    await assertFails(deleteDoc(doc(await asUser(NOMSA), `${PANTRY}/apple`)));
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), `${PANTRY}/apple`)));
  });
});

describe('lunchPacked/{childId}_{date}', () => {
  it('a packed box and its portions leave the pantry in one batch', async () => {
    await givenStock('apple', 3);
    const db = await asUser(SAM);
    const batch = writeBatch(db);
    batch.set(doc(db, `${PACKED}/${ZOLA}_${TUESDAY}`), packed(ZOLA));
    batch.update(doc(db, `${PANTRY}/apple`), {
      portions: increment(-1),
      updatedBy: 'm-sam',
      updatedAt: serverTimestamp(),
    });
    await assertSucceeds(batch.commit());
  });

  it('the same box cannot be packed twice', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, `${PACKED}/${ZOLA}_${TUESDAY}`), packed(ZOLA)));
    await assertFails(setDoc(doc(db, `${PACKED}/${ZOLA}_${TUESDAY}`), packed(ZOLA)));
    await assertFails(updateDoc(doc(db, `${PACKED}/${ZOLA}_${TUESDAY}`), { itemIds: ['wrap'] }));
  });

  it('a batch that would take the pantry below nothing is refused whole', async () => {
    await givenStock('apple', 0);
    const db = await asUser(SAM);
    const batch = writeBatch(db);
    batch.set(doc(db, `${PACKED}/${ZOLA}_${TUESDAY}`), packed(ZOLA));
    batch.update(doc(db, `${PANTRY}/apple`), {
      portions: increment(-1),
      updatedBy: 'm-sam',
      updatedAt: serverTimestamp(),
    });
    await assertFails(batch.commit());
    await givenData(async (seeded) => {
      const snapshot = await getDoc(doc(seeded, `${PACKED}/${ZOLA}_${TUESDAY}`));
      if (snapshot.exists()) throw new Error('the packed record was written');
    });
  });

  it('refuses a record for somebody who is not a child, or whose id lies', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, `${PACKED}/m-sam_${TUESDAY}`), packed('m-sam')));
    await assertFails(setDoc(doc(db, `${PACKED}/${KID}_${TUESDAY}`), packed(ZOLA)));
    await assertFails(
      setDoc(doc(db, `${PACKED}/${ZOLA}_${TUESDAY}`), {
        ...packed(ZOLA),
        itemIds: ['a', 'b', 'c', 'd', 'e', 'f'],
      }),
    );
  });

  it('a carer and a tablet cannot mark packed; family can undo', async () => {
    for (const db of [await asUser(NOMSA), await kidsTablet()]) {
      await assertFails(setDoc(doc(db, `${PACKED}/${ZOLA}_${TUESDAY}`), packed(ZOLA)));
    }
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, `${PACKED}/${ZOLA}_${TUESDAY}`), packed(ZOLA)));
    await assertFails(deleteDoc(doc(await asUser(NOMSA), `${PACKED}/${ZOLA}_${TUESDAY}`)));
    await assertSucceeds(deleteDoc(doc(db, `${PACKED}/${ZOLA}_${TUESDAY}`)));
  });
});

describe('a grocery line the pantry adds', () => {
  const line = (source?: string): object => ({
    name: 'Apple',
    quantity: 'for 3 lunch boxes',
    addedBy: 'm-sam',
    addedAt: serverTimestamp(),
    boughtAt: null,
    boughtBy: null,
    ...(source === undefined ? {} : { source }),
  });

  it('says it came from the pantry or lunch, or says nothing', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, `${GROCERIES}/g1`), line('pantry')));
    await assertSucceeds(setDoc(doc(db, `${GROCERIES}/g2`), line('lunch')));
    await assertSucceeds(setDoc(doc(db, `${GROCERIES}/g3`), line()));
  });

  it('refuses any other source', async () => {
    const db = await asUser(SAM);
    for (const bad of ['typed', 'ai', '', 3]) {
      await assertFails(setDoc(doc(db, `${GROCERIES}/g1`), line(bad as string)));
    }
  });
});
