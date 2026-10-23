import {
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
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
  givenLunchPremium,
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
    await assertFails(
      setDoc(doc(db, `${ITEMS}/pb`), { ...newItem, createdAt: new Date(Date.now() - 60_000) }),
    );
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

  // Recipes ADR-0001: a recipe reaches a household only as a library item,
  // `recipe-<id>`, that names it — once, for good.
  const fromRecipe = {
    ...newItem,
    name: 'Banana oat bites',
    nameKey: 'banana oat bites',
    slot: 'treat',
    allergens: [],
    recipeId: 'banana-oat-bites',
  };

  it('family adds an item made from a recipe, naming the recipe', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, `${ITEMS}/recipe-banana-oat-bites`), fromRecipe));
    for (const recipeId of ['', 42, 'x'.repeat(61), null]) {
      await assertFails(setDoc(doc(db, `${ITEMS}/bad`), { ...fromRecipe, recipeId }));
    }
  });

  it('never adds, changes or drops the recipe an item was made from', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${ITEMS}/recipe-banana-oat-bites`), {
        ...fromRecipe,
        createdAt: new Date(),
      });
    });
    const db = await asUser(SAM);
    const item = doc(db, `${ITEMS}/recipe-banana-oat-bites`);
    await assertSucceeds(updateDoc(item, { name: 'Oat bites', nameKey: 'oat bites' }));
    await assertFails(updateDoc(item, { recipeId: 'apple-crumble-muffins' }));
    await assertFails(updateDoc(item, { recipeId: deleteField() }));
    await assertFails(updateDoc(doc(db, `${ITEMS}/apple`), { recipeId: 'banana-oat-bites' }));
  });

  // Recipes ADR-0002: a dish *Plan my week* drafted links to the household's
  // own recipe, carries at least its allergen codes, and never moves.
  const RECIPES = 'households/h1/recipes';
  const fromHouseholdRecipe = {
    ...newItem,
    name: 'Mexican wholewheat wrap',
    nameKey: 'mexican wholewheat wrap',
    allergens: ['milk', 'wheat'],
    householdRecipeId: 'ai-0123456789abcdef0123',
  };

  async function givenTheWrapRecipe(): Promise<void> {
    await givenData(async (db) => {
      await setDoc(doc(db, `${RECIPES}/ai-0123456789abcdef0123`), {
        name: 'Mexican wholewheat wrap',
        source: 'ai',
        allergens: ['milk', 'wheat'],
        addedBy: 'm-sam',
        createdAt: new Date(),
      });
    });
  }

  it('family adds a dish linked to its household recipe, carrying the recipe’s codes', async () => {
    await givenTheWrapRecipe();
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, `${ITEMS}/wrap`), fromHouseholdRecipe));
    await assertSucceeds(
      setDoc(doc(db, `${ITEMS}/wrap-plus`), {
        ...fromHouseholdRecipe,
        allergens: ['milk', 'wheat', 'soy'],
      }),
    );
  });

  it('refuses a dish that carries fewer codes than its recipe', async () => {
    await givenTheWrapRecipe();
    const db = await asUser(SAM);
    await assertFails(
      setDoc(doc(db, `${ITEMS}/wrap`), { ...fromHouseholdRecipe, allergens: ['wheat'] }),
    );
    await assertFails(setDoc(doc(db, `${ITEMS}/wrap`), { ...fromHouseholdRecipe, allergens: [] }));
  });

  it('refuses a link to a recipe the household does not have, or to both kinds at once', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, `${ITEMS}/wrap`), fromHouseholdRecipe));
    await givenTheWrapRecipe();
    await assertFails(
      setDoc(doc(db, `${ITEMS}/wrap`), { ...fromHouseholdRecipe, recipeId: 'chicken-mayo-wrap' }),
    );
    for (const householdRecipeId of ['', 42, 'x'.repeat(61), null]) {
      await assertFails(setDoc(doc(db, `${ITEMS}/bad`), { ...newItem, householdRecipeId }));
    }
  });

  it('never changes or drops the link, nor takes the recipe’s codes off the dish', async () => {
    await givenTheWrapRecipe();
    await givenData(async (db) => {
      await setDoc(doc(db, `${ITEMS}/wrap`), { ...fromHouseholdRecipe, createdAt: new Date() });
    });
    const db = await asUser(SAM);
    const item = doc(db, `${ITEMS}/wrap`);
    await assertSucceeds(updateDoc(item, { name: 'Taco wrap', nameKey: 'taco wrap' }));
    await assertSucceeds(updateDoc(item, { allergens: ['milk', 'wheat', 'egg'] }));
    await assertFails(updateDoc(item, { allergens: ['wheat'] }));
    await assertFails(updateDoc(item, { householdRecipeId: 'ai-ffffffffffffffffffff' }));
    await assertFails(updateDoc(item, { householdRecipeId: deleteField() }));
    await assertFails(
      updateDoc(doc(db, `${ITEMS}/apple`), { householdRecipeId: 'ai-0123456789abcdef0123' }),
    );
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
  // The prep list is premium (lunch-box ADR-0009); the free side of it is in
  // `lunch_premium.rules.test.ts`.
  beforeEach(() => givenLunchPremium());

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
