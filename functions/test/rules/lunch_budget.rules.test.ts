import { deleteDoc, doc, getDoc, serverTimestamp, setDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { CLEO, MIA, NOMSA, SAM, STRANGER } from './family_fixture';
import { givenTheLunchHousehold, kidsTablet } from './lunch_box_fixture';
import {
  BUDGET,
  PRICES,
  givenLapsedPremium,
  givenPremium,
  givenTheLibrary,
} from './lunch_planning_fixture';
import { asUser, assertFails, assertSucceeds, clearData, givenData } from './rules_harness';

/**
 * Budget mode (lunch-box ADR-0007): prices per library item and a weekly
 * budget, in whole rand cents. Every write needs premium as well as `lunch`
 * at edit; reading needs only `lunch` at view, so a lapsed household keeps
 * what it wrote (subscriptions ADR-0001).
 */

beforeEach(async () => {
  await clearData();
  await givenTheLunchHousehold();
  await givenTheLibrary();
});

const price = (cents: number, portions = 1, updatedBy = 'm-sam'): object => ({
  cents,
  portions,
  currency: 'ZAR',
  updatedBy,
  updatedAt: serverTimestamp(),
});

const budget = (cents: number): object => ({
  cents,
  currency: 'ZAR',
  updatedBy: 'm-sam',
  updatedAt: serverTimestamp(),
});

describe('lunchPrices/{itemId}', () => {
  it('a premium household prices a box and a pack', async () => {
    await givenPremium();
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, `${PRICES}/apple`), price(650)));
    await assertSucceeds(setDoc(doc(db, `${PRICES}/wrap`), price(4200, 8)));
    await assertSucceeds(setDoc(doc(await asUser(MIA), `${PRICES}/apple`), price(700, 1, 'm-mia')));
  });

  it('a free household, or one whose premium ran out, cannot', async () => {
    await assertFails(setDoc(doc(await asUser(SAM), `${PRICES}/apple`), price(650)));
    await givenLapsedPremium();
    await assertFails(setDoc(doc(await asUser(SAM), `${PRICES}/apple`), price(650)));
  });

  it('refuses a carer, a tablet and a stranger even with premium', async () => {
    await givenPremium();
    for (const db of [await asUser(NOMSA), await kidsTablet(), await asUser(STRANGER)]) {
      await assertFails(setDoc(doc(db, `${PRICES}/apple`), price(650)));
    }
  });

  it('refuses money that is not whole cents in rand, and odd shapes', async () => {
    await givenPremium();
    const db = await asUser(SAM);
    for (const bad of [
      price(6.5),
      price(-1),
      price(500001),
      price(650, 0),
      price(650, 101),
      price(650, 1, 'm-mia'),
      { ...price(650), currency: 'USD' },
      { ...price(650), updatedAt: new Date() },
      { ...price(650), rands: 6.5 },
    ]) {
      await assertFails(setDoc(doc(db, `${PRICES}/apple`), bad));
    }
    await assertFails(setDoc(doc(db, `${PRICES}/sushi`), price(650)));
  });

  it('a lapsed household still reads its prices, and a carer reads them', async () => {
    await givenData(async (seeded) => {
      await setDoc(doc(seeded, `${PRICES}/apple`), {
        cents: 650,
        portions: 1,
        currency: 'ZAR',
        updatedBy: 'm-sam',
        updatedAt: new Date(),
      });
    });
    await givenLapsedPremium();
    await assertSucceeds(getDoc(doc(await asUser(SAM), `${PRICES}/apple`)));
    await assertSucceeds(getDoc(doc(await asUser(NOMSA), `${PRICES}/apple`)));
    await assertFails(getDoc(doc(await kidsTablet(), `${PRICES}/apple`)));
    await assertFails(getDoc(doc(await asUser(CLEO), `${PRICES}/apple`)));
  });

  it('removing a price needs lunch at edit, not premium', async () => {
    await givenData(async (seeded) => {
      await setDoc(doc(seeded, `${PRICES}/apple`), { cents: 650, portions: 1 });
    });
    await assertFails(deleteDoc(doc(await asUser(NOMSA), `${PRICES}/apple`)));
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), `${PRICES}/apple`)));
  });
});

describe('lunchBudget/weekly', () => {
  it('a premium household sets a weekly budget', async () => {
    await givenPremium();
    await assertSucceeds(setDoc(doc(await asUser(SAM), `${BUDGET}/weekly`), budget(25000)));
  });

  it('only as `weekly`, only with premium, only R1 to R100 000', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, `${BUDGET}/weekly`), budget(25000)));
    await givenPremium();
    await assertFails(setDoc(doc(db, `${BUDGET}/monthly`), budget(25000)));
    for (const bad of [budget(99), budget(10000001), budget(250.5)]) {
      await assertFails(setDoc(doc(db, `${BUDGET}/weekly`), bad));
    }
  });

  it('a carer reads it and cannot set it', async () => {
    await givenPremium();
    await assertSucceeds(setDoc(doc(await asUser(SAM), `${BUDGET}/weekly`), budget(25000)));
    await assertSucceeds(getDoc(doc(await asUser(NOMSA), `${BUDGET}/weekly`)));
    await assertFails(setDoc(doc(await asUser(NOMSA), `${BUDGET}/weekly`), budget(100)));
  });
});
