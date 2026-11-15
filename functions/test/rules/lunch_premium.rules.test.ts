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

import { KID, SAM } from './family_fixture';
import {
  APPLE,
  FAVOURITES,
  ITEMS,
  MONDAY,
  PREP,
  WEEK,
  WRAP,
  ZOLA,
  givenLunchPremium,
  givenTheLunchHousehold,
  kidsTablet,
  pick,
  planOf,
  planPath,
} from './lunch_box_fixture';
import { CHOICES, PACKED, PANTRY, TUESDAY, givenTheLibrary } from './lunch_planning_fixture';
import {
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

/**
 * Lunch boxes are Premium, every part (subscriptions ADR-0008, ADR-0009): a
 * free household — or one whose Premium lapsed — creates and updates nothing
 * in any lunch collection, as a parent or as a kid device, and still reads
 * and removes what it made. A Premium household does all of it.
 */

const BANANA = pick('banana', 'Banana');

const markEaten = {
  'feedback.2': { verdict: 'ate', items: {}, by: 'm-sam', at: serverTimestamp() },
};

const newItem = {
  name: 'Banana',
  nameKey: 'banana',
  slot: 'fruit',
  allergens: [],
  archived: false,
  addedBy: 'm-sam',
  createdAt: serverTimestamp(),
};

const favourite = {
  childId: ZOLA,
  name: 'Friday special',
  picks: { main: WRAP, fruit: APPLE },
  createdBy: 'm-sam',
  createdAt: serverTimestamp(),
};

const stock = { portions: 3, updatedBy: 'm-sam', updatedAt: serverTimestamp() };

const packed = {
  childId: ZOLA,
  date: TUESDAY,
  week: WEEK,
  itemIds: ['apple'],
  by: 'm-sam',
  at: serverTimestamp(),
};

const choicesPath = (childId: string): string => `${CHOICES}/${childId}_${WEEK}`;

const options = {
  childId: ZOLA,
  week: WEEK,
  options: { '2_main': [WRAP, APPLE] },
  chosen: {},
  editedDay: '2',
  updatedBy: 'm-sam',
  updatedAt: serverTimestamp(),
};

const moreOptions = {
  'options.2_fruit': [APPLE, BANANA],
  editedDay: '2',
  updatedBy: 'm-sam',
  updatedAt: serverTimestamp(),
};

/** The chooser's batch: the plan's slot, and the choice recorded as theirs. */
async function choose(db: Firestore, key: string, option: object): Promise<void> {
  const batch = writeBatch(db);
  batch.set(
    doc(db, planPath(KID)),
    { childId: KID, week: WEEK, weekStart: MONDAY, slots: { [key]: option } },
    { mergeFields: ['childId', 'week', 'weekStart', `slots.${key}`] },
  );
  batch.update(doc(db, choicesPath(KID)), {
    [`chosen.${key}`]: (option as { itemId: string }).itemId,
    chosenKey: key,
  });
  await batch.commit();
}

/**
 * The plan half of a choice with no choices write beside it: the choices
 * document already names the slot, so `hasPremium` on the kid's plan rules is
 * all that stands between a free household's kid device and this write.
 */
async function givenTheSlotIsAlreadyNamed(): Promise<void> {
  await givenData(async (db) => {
    await updateDoc(doc(db, choicesPath(KID)), { chosenKey: '2_fruit' });
  });
}

const newPlanAlone = (db: Firestore): Promise<void> =>
  setDoc(doc(db, planPath(KID)), planOf(KID, { '2_fruit': APPLE }));

const oldPlanAlone = (db: Firestore): Promise<void> =>
  updateDoc(doc(db, planPath(KID)), { 'slots.2_fruit': BANANA });

async function givenTheKidsEmptyPlan(): Promise<void> {
  await givenData(async (db) => {
    await setDoc(doc(db, planPath(KID)), planOf(KID));
  });
}

/** What a household made while it had Premium, one document per collection. */
async function givenWhatItMade(): Promise<void> {
  await givenData(async (db) => {
    await setDoc(doc(db, planPath(ZOLA)), planOf(ZOLA, { '1_main': WRAP }));
    await setDoc(doc(db, `${FAVOURITES}/f1`), { ...favourite, createdAt: new Date() });
    await setDoc(doc(db, `${PREP}/${WEEK}`), { done: [] });
    await setDoc(doc(db, `${PANTRY}/apple`), { ...stock, updatedAt: new Date() });
    await setDoc(doc(db, `${PACKED}/${ZOLA}_${TUESDAY}`), { ...packed, at: new Date() });
    await setDoc(doc(db, choicesPath(ZOLA)), { ...options, updatedAt: new Date() });
    await setDoc(doc(db, choicesPath(KID)), {
      ...options,
      childId: KID,
      options: { '2_fruit': [APPLE, BANANA] },
      updatedAt: new Date(),
    });
  });
}

beforeEach(async () => {
  await clearData();
  await givenTheLunchHousehold();
  await givenTheLibrary();
});

async function isRefusedEveryLunchWrite(): Promise<void> {
  const db = await asUser(SAM);
  await assertFails(setDoc(doc(db, `${ITEMS}/banana`), newItem));
  await assertFails(updateDoc(doc(db, `${ITEMS}/apple`), { archived: true }));
  await assertFails(setDoc(doc(db, planPath(KID)), planOf(KID, { '1_fruit': APPLE })));
  await assertFails(updateDoc(doc(db, planPath(ZOLA)), { 'slots.2_main': WRAP }));
  await assertFails(updateDoc(doc(db, planPath(ZOLA)), markEaten));
  await assertFails(setDoc(doc(db, `${FAVOURITES}/f2`), favourite));
  await assertFails(updateDoc(doc(db, `${FAVOURITES}/f1`), { name: 'Monday' }));
  await assertFails(setDoc(doc(db, `${PREP}/${WEEK}`), { done: ['apple'] }));
  await assertFails(setDoc(doc(db, `${PREP}/2026-W41`), { done: [] }));
  await assertFails(setDoc(doc(db, `${PANTRY}/wrap`), stock));
  await assertFails(updateDoc(doc(db, `${PANTRY}/apple`), { ...stock, portions: 1 }));
  await assertFails(setDoc(doc(db, `${PACKED}/${KID}_${TUESDAY}`), { ...packed, childId: KID }));
  await assertFails(
    setDoc(doc(db, `${CHOICES}/${ZOLA}_2026-W41`), { ...options, week: '2026-W41' }),
  );
  await assertFails(updateDoc(doc(db, choicesPath(ZOLA)), moreOptions));
}

async function stillReadsAndRemoves(): Promise<void> {
  const db = await asUser(SAM);
  for (const path of [
    `${ITEMS}/apple`,
    planPath(ZOLA),
    `${FAVOURITES}/f1`,
    `${PREP}/${WEEK}`,
    `${PANTRY}/apple`,
    `${PACKED}/${ZOLA}_${TUESDAY}`,
    choicesPath(ZOLA),
  ]) {
    await assertSucceeds(getDoc(doc(db, path)));
  }
  await assertSucceeds(getDoc(doc(await kidsTablet(), choicesPath(KID))));
  for (const path of [
    `${FAVOURITES}/f1`,
    `${PANTRY}/apple`,
    `${PACKED}/${ZOLA}_${TUESDAY}`,
    choicesPath(ZOLA),
  ]) {
    await assertSucceeds(deleteDoc(doc(db, path)));
  }
}

describe('a free household', () => {
  beforeEach(() => givenWhatItMade());

  it('creates and updates nothing in any lunch collection', () => isRefusedEveryLunchWrite());

  it('still reads what it made, and removes what could always be removed', () =>
    stillReadsAndRemoves());

  it('its kid device chooses nothing, new plan or old', async () => {
    const tablet = await kidsTablet();
    await assertFails(choose(tablet, '2_fruit', APPLE));
    await givenData(async (db) => {
      await setDoc(doc(db, planPath(KID)), planOf(KID));
    });
    await assertFails(choose(tablet, '2_fruit', APPLE));
    await assertFails(
      updateDoc(doc(tablet, choicesPath(KID)), { 'chosen.2_fruit': 'apple', chosenKey: '2_fruit' }),
    );
  });

  it('its kid device writes no plan on its own, new or old', async () => {
    await givenTheSlotIsAlreadyNamed();
    const tablet = await kidsTablet();
    await assertFails(newPlanAlone(tablet));
    await givenTheKidsEmptyPlan();
    await assertFails(oldPlanAlone(tablet));
  });
});

describe('a household whose Premium lapsed', () => {
  beforeEach(async () => {
    await givenWhatItMade();
    await givenLunchPremium('lapsed');
  });

  it('is free again: nothing created, nothing updated', () => isRefusedEveryLunchWrite());

  it('keeps reading what it made', () => stillReadsAndRemoves());

  it('its kid device chooses nothing', async () => {
    await assertFails(choose(await kidsTablet(), '2_fruit', APPLE));
  });

  it('its kid device writes no plan on its own, new or old', async () => {
    await givenTheSlotIsAlreadyNamed();
    const tablet = await kidsTablet();
    await assertFails(newPlanAlone(tablet));
    await givenTheKidsEmptyPlan();
    await assertFails(oldPlanAlone(tablet));
  });
});

describe('a Premium household', () => {
  beforeEach(async () => {
    await givenWhatItMade();
    await givenLunchPremium();
  });

  it('writes every lunch collection', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, `${ITEMS}/banana`), newItem));
    await assertSucceeds(updateDoc(doc(db, `${ITEMS}/apple`), { archived: true }));
    await assertSucceeds(setDoc(doc(db, planPath(KID)), planOf(KID, { '1_fruit': APPLE })));
    await assertSucceeds(updateDoc(doc(db, planPath(ZOLA)), { 'slots.2_main': WRAP }));
    await assertSucceeds(updateDoc(doc(db, planPath(ZOLA)), markEaten));
    await assertSucceeds(setDoc(doc(db, `${FAVOURITES}/f2`), favourite));
    await assertSucceeds(updateDoc(doc(db, `${FAVOURITES}/f1`), { name: 'Monday' }));
    await assertSucceeds(setDoc(doc(db, `${PREP}/${WEEK}`), { done: ['apple'] }));
    await assertSucceeds(setDoc(doc(db, `${PREP}/2026-W41`), { done: [] }));
    await assertSucceeds(setDoc(doc(db, `${PANTRY}/wrap`), stock));
    await assertSucceeds(updateDoc(doc(db, `${PANTRY}/apple`), { ...stock, portions: 1 }));
    await assertSucceeds(
      setDoc(doc(db, `${PACKED}/${KID}_${TUESDAY}`), { ...packed, childId: KID }),
    );
    await assertSucceeds(
      setDoc(doc(db, `${CHOICES}/${ZOLA}_2026-W41`), { ...options, week: '2026-W41' }),
    );
    await assertSucceeds(updateDoc(doc(db, choicesPath(ZOLA)), moreOptions));
  });

  it('its kid device chooses from what a parent approved, as its own profile', async () => {
    const tablet = await kidsTablet();
    await assertSucceeds(choose(tablet, '2_fruit', APPLE));
    await assertSucceeds(choose(tablet, '2_fruit', BANANA));
  });

  it('its kid device writes the plan on its own once the slot is named', async () => {
    await givenTheSlotIsAlreadyNamed();
    const tablet = await kidsTablet();
    await assertSucceeds(newPlanAlone(tablet));
    await assertSucceeds(oldPlanAlone(tablet));
  });

  it('fills a week a day per write, the most one write carries (lunch-box ADR-0010)', async () => {
    // The heaviest child there is: allergies, a nut-free diet and a nut-free
    // school, so every pick is checked against the most. Firestore stops a
    // request at 1000 expressions; a day's five slots fit, a week's do not.
    const db = await asUser(SAM);
    for (const day of ['1', '2', '3', '4', '5']) {
      const slots: Record<string, object> = {};
      for (const slot of ['main', 'fruit', 'veg', 'snack', 'treat']) {
        slots[`${day}_${slot}`] = APPLE;
      }
      await assertSucceeds(
        setDoc(doc(db, planPath(KID)), { ...planOf(KID), slots }, { merge: true }),
      );
    }
  });
});
