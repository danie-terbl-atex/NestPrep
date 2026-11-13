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
  type Query,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { CLEO, NOMSA, OLIVIA, SAM, STRANGER, THANDI } from './family_fixture';
import { givenTheLunchHousehold, kidsTablet } from './lunch_box_fixture';
import {
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

/**
 * A household's recipes. `ai` (recipes ADR-0002) is read one at a time by
 * whoever sees lunches; `own` (ADR-0007) is read and listed by whoever sees
 * meals. Only Functions write either, not even an admin.
 */
const RECIPES = 'households/h1/recipes';
const WRAP = `${RECIPES}/ai-0123456789abcdef0123`;
const BOBOTIE = `${RECIPES}/own-0123456789abcdef0123`;

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

const ownRecipe = {
  ...recipe,
  name: 'Bobotie',
  source: 'own',
  contexts: ['dinner'],
  placement: { dinner: 'main' },
};

const givenThandiHolds = (grant: Record<string, string>): Promise<void> =>
  givenData(async (db) => {
    await setDoc(doc(db, 'households/h1'), { access: { [THANDI]: grant } }, { merge: true });
  });

function ownRecipes(db: Firestore): Query {
  return query(collection(db, RECIPES), where('source', '==', 'own'), orderBy('name'), limit(300));
}

beforeEach(async () => {
  await clearData();
  await givenTheLunchHousehold();
  await givenData(async (db) => {
    await setDoc(doc(db, WRAP), { ...recipe, createdAt: new Date() });
    await setDoc(doc(db, BOBOTIE), { ...ownRecipe, createdAt: new Date() });
  });
});

describe('households/{h}/recipes/{recipeId} read by id', () => {
  it('family and a carer with lunch at view read one by id', async () => {
    await assertSucceeds(getDoc(doc(await asUser(SAM), WRAP)));
    await assertSucceeds(getDoc(doc(await asUser(NOMSA), WRAP)));
  });

  it('a cleaner without lunch, a stranger and another household read nothing', async () => {
    for (const db of [await asUser(CLEO), await asUser(STRANGER), await asUser(OLIVIA)]) {
      await assertFails(getDoc(doc(db, WRAP)));
      await assertFails(getDoc(doc(db, BOBOTIE)));
    }
  });

  it('meals at view reads an own recipe and never an AI one', async () => {
    await givenThandiHolds({ meals: 'view' });
    const thandi = await asUser(THANDI);
    await assertSucceeds(getDoc(doc(thandi, BOBOTIE)));
    await assertFails(getDoc(doc(thandi, WRAP)));
    const kid = await kidsTablet();
    await assertSucceeds(getDoc(doc(kid, BOBOTIE)));
    await assertFails(getDoc(doc(kid, WRAP)));
  });

  it('meals at view reads a missing recipe as gone rather than an error', async () => {
    await givenThandiHolds({ meals: 'view' });
    await assertSucceeds(getDoc(doc(await asUser(THANDI), `${RECIPES}/own-ffffffffffffffffffff`)));
    await assertFails(getDoc(doc(await asUser(CLEO), `${RECIPES}/own-ffffffffffffffffffff`)));
  });
});

describe('households/{h}/recipes listed', () => {
  it('family, a kid tablet and a helper with meals at view list own recipes', async () => {
    await givenThandiHolds({ meals: 'view' });
    for (const db of [await asUser(SAM), await kidsTablet(), await asUser(THANDI)]) {
      await assertSucceeds(getDocs(ownRecipes(db)));
    }
  });

  it('a helper with lunch at view and no meals lists nothing', async () => {
    await givenThandiHolds({ lunch: 'view' });
    await assertFails(getDocs(ownRecipes(await asUser(THANDI))));
  });

  it('a cleaner, a stranger and another household list nothing', async () => {
    for (const db of [await asUser(CLEO), await asUser(STRANGER), await asUser(OLIVIA)]) {
      await assertFails(getDocs(ownRecipes(db)));
    }
  });

  it('refuses a list without the source filter, or naming another source', async () => {
    const db = await asUser(SAM);
    await assertFails(getDocs(query(collection(db, RECIPES), limit(10))));
    await assertFails(
      getDocs(query(collection(db, RECIPES), where('source', '==', 'ai'), limit(10))),
    );
  });

  it('refuses a list over the limit, or with none', async () => {
    const db = await asUser(SAM);
    const own = where('source', '==', 'own');
    await assertFails(getDocs(query(collection(db, RECIPES), own, limit(301))));
    await assertFails(getDocs(query(collection(db, RECIPES), own)));
  });
});

describe('households/{h}/recipes written', () => {
  it('no client writes one, not even an admin: its codes are the Function’s', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, `${RECIPES}/ai-ffffffffffffffffffff`), recipe));
    await assertFails(setDoc(doc(db, `${RECIPES}/own-ffffffffffffffffffff`), ownRecipe));
    for (const path of [WRAP, BOBOTIE]) {
      await assertFails(updateDoc(doc(db, path), { allergens: [] }));
      await assertFails(deleteDoc(doc(db, path)));
    }
  });

  it('a kid tablet writes nothing', async () => {
    const db = await kidsTablet();
    await assertFails(setDoc(doc(db, `${RECIPES}/own-ffffffffffffffffffff`), ownRecipe));
    await assertFails(updateDoc(doc(db, BOBOTIE), { name: 'Mine' }));
  });
});
