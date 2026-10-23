import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  limit,
  query,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { CLEO, NOMSA, OLIVIA, SAM, STRANGER } from './family_fixture';
import { givenTheLunchHousehold, kidsTablet } from './lunch_box_fixture';
import { asUser, assertFails, assertSucceeds, clearData, givenData } from './rules_harness';

/**
 * A household's own recipes (recipes ADR-0002): the dishes it used from
 * *Plan my week*. Read one at a time by whoever sees lunches; written only by
 * the `saveLunchRecipes` Function, so no client — not even an admin — creates,
 * changes, deletes or lists one.
 */
const RECIPES = 'households/h1/recipes';
const WRAP = `${RECIPES}/ai-0123456789abcdef0123`;

const recipe = {
  name: 'Mexican wholewheat wrap',
  summary: 'A soft wrap with chicken, corn and cheese.',
  source: 'ai',
  contexts: ['lunchBox'],
  placement: { lunchBox: 'main' },
  allergens: ['milk', 'wheat'],
  dietTags: [],
  ingredients: [{ name: 'Wholewheat tortillas', quantity: 1, unit: null, note: null }],
  steps: ['Fill and roll.'],
  servings: 1,
  prepMinutes: 10,
  prepAhead: false,
  prepNote: null,
  addedBy: 'm-sam',
};

beforeEach(async () => {
  await clearData();
  await givenTheLunchHousehold();
  await givenData(async (db) => {
    await setDoc(doc(db, WRAP), { ...recipe, createdAt: new Date() });
  });
});

describe('households/{h}/recipes/{recipeId}', () => {
  it('family and a carer with lunch at view read one by id', async () => {
    await assertSucceeds(getDoc(doc(await asUser(SAM), WRAP)));
    await assertSucceeds(getDoc(doc(await asUser(NOMSA), WRAP)));
  });

  it('a cleaner without lunch, a kid tablet, a stranger and another household read nothing', async () => {
    for (const db of [
      await asUser(CLEO),
      await kidsTablet(),
      await asUser(STRANGER),
      await asUser(OLIVIA),
    ]) {
      await assertFails(getDoc(doc(db, WRAP)));
    }
  });

  it('nobody lists them — the app reads the one an item names', async () => {
    await assertFails(getDocs(query(collection(await asUser(SAM), RECIPES), limit(10))));
  });

  it('no client writes one, not even an admin: its codes are the Function’s', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, `${RECIPES}/ai-ffffffffffffffffffff`), recipe));
    await assertFails(updateDoc(doc(db, WRAP), { allergens: [] }));
    await assertFails(deleteDoc(doc(db, WRAP)));
  });
});
