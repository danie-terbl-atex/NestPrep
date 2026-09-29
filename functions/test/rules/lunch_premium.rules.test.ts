import { doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { KID, SAM } from './family_fixture';
import {
  APPLE,
  PREP,
  WEEK,
  WRAP,
  ZOLA,
  givenLunchPremium,
  givenTheFreeChild,
  givenTheLunchHousehold,
  planOf,
  planPath,
} from './lunch_box_fixture';
import { asUser, assertFails, assertSucceeds, clearData, givenData } from './rules_harness';

/**
 * Where lunch-box's free tier ends (lunch-box ADR-0009, subscriptions
 * ADR-0001): a free household plans the one child `setChildProfile`
 * recorded, marks nothing eaten and ticks no prep list; premium does all
 * three. A lapse is free again, and keeps reading what it made.
 */

beforeEach(async () => {
  await clearData();
  await givenTheLunchHousehold();
  await givenTheFreeChild(KID);
});

const markEaten = {
  'feedback.2': { verdict: 'ate', items: {}, by: 'm-sam', at: serverTimestamp() },
};

describe('a free household', () => {
  it('plans its one child’s week', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, planPath(KID)), planOf(KID, { '1_fruit': APPLE })));
    await assertSucceeds(updateDoc(doc(db, planPath(KID)), { 'slots.2_fruit': APPLE }));
  });

  it('plans no other child’s, new or already there', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, planPath(ZOLA)), planOf(ZOLA, { '1_main': WRAP })));
    await givenData(async (admin) => {
      await setDoc(doc(admin, planPath(ZOLA)), planOf(ZOLA, { '1_main': WRAP }));
    });
    await assertFails(updateDoc(doc(db, planPath(ZOLA)), { 'slots.2_main': WRAP }));
  });

  it('marks nothing eaten — the learning loop is premium', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, planPath(KID)), planOf(KID, { '2_fruit': APPLE })));
    await assertFails(updateDoc(doc(db, planPath(KID)), markEaten));
    await assertFails(
      setDoc(doc(db, planPath(KID)), {
        ...planOf(KID),
        feedback: { '2': { verdict: 'ate', items: {}, by: 'm-sam', at: serverTimestamp() } },
      }),
    );
  });

  it('ticks no prep list', async () => {
    await assertFails(setDoc(doc(await asUser(SAM), `${PREP}/${WEEK}`), { done: ['apple'] }));
  });

  it('with a record that names nobody, plans nobody', async () => {
    await givenData(async (admin) => {
      await setDoc(doc(admin, 'households/h1/entitlement/freeChild'), {});
    });
    await assertFails(
      setDoc(doc(await asUser(SAM), planPath(ZOLA)), planOf(ZOLA, { '1_main': WRAP })),
    );
  });
});

describe('a free household that has not marked a child since the record began', () => {
  // The file's own set-up recorded a free child; this household has none.
  beforeEach(async () => {
    await clearData();
    await givenTheLunchHousehold();
  });

  it('is not held to a child it never chose — the next marking records one', async () => {
    await assertSucceeds(
      setDoc(doc(await asUser(SAM), planPath(ZOLA)), planOf(ZOLA, { '1_main': WRAP })),
    );
  });
});

describe('a premium household', () => {
  beforeEach(() => givenLunchPremium());

  it('plans every child, learns from what came home and keeps the prep list', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, planPath(ZOLA)), planOf(ZOLA, { '2_main': WRAP })));
    await assertSucceeds(updateDoc(doc(db, planPath(ZOLA)), markEaten));
    await assertSucceeds(setDoc(doc(db, `${PREP}/${WEEK}`), { done: ['apple'] }));
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

describe('a household whose premium lapsed', () => {
  beforeEach(() => givenLunchPremium('lapsed'));

  it('is free again: the one child, nothing marked, no prep', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, planPath(KID)), planOf(KID, { '1_fruit': APPLE })));
    await assertFails(setDoc(doc(db, planPath(ZOLA)), planOf(ZOLA, { '1_main': WRAP })));
    await assertFails(updateDoc(doc(db, planPath(KID)), markEaten));
    await assertFails(setDoc(doc(db, `${PREP}/${WEEK}`), { done: [] }));
  });
});
