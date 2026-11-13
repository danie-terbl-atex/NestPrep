import { deleteField, doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

/**
 * Recipes ADR-0003 §6: a catalogue recipe reaches the meal plan only as a
 * household meal at `meals/recipe-<recipeId>`, naming the recipe in an
 * immutable `recipeId` — set once at create, never added, changed or removed
 * — while its name and ingredients stay the family's to edit.
 */

const SAM = 'uid-sam';
const HOUSEHOLD = 'h1';
const SAM_MEMBER = 'm-sam';
const MEALS = `households/${HOUSEHOLD}/meals`;
const BOBOTIE = `${MEALS}/recipe-bobotie`;

const LINES = [
  { name: 'Beef mince', amount: 1, unit: 'kg' },
  { name: 'Eggs', amount: 2, unit: null },
];

const fromRecipe = {
  name: 'Bobotie',
  nameKey: 'bobotie',
  addedBy: SAM_MEMBER,
  createdAt: serverTimestamp(),
  ingredients: LINES,
  recipeId: 'bobotie',
};

async function givenTheParkers(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `households/${HOUSEHOLD}`), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin' },
    });
    await setDoc(doc(db, `households/${HOUSEHOLD}/members/${SAM_MEMBER}`), {
      displayName: 'Sam',
      color: 'violet',
      role: 'admin',
      claimedBy: SAM,
    });
    await setDoc(doc(db, `${MEALS}/spaghetti`), {
      name: 'Spaghetti',
      nameKey: 'spaghetti',
      addedBy: SAM_MEMBER,
      createdAt: new Date(),
    });
    await setDoc(doc(db, `${MEALS}/recipe-malva-pudding`), {
      name: 'Malva pudding',
      nameKey: 'malva pudding',
      addedBy: SAM_MEMBER,
      createdAt: new Date(),
      ingredients: [],
      recipeId: 'malva-pudding',
    });
  });
}

const OWN = 'own-0123456789abcdef0123';

const fromOwnRecipe = {
  name: 'Gran’s bobotie',
  nameKey: 'gran’s bobotie',
  addedBy: SAM_MEMBER,
  createdAt: serverTimestamp(),
  ingredients: LINES,
  householdRecipeId: OWN,
};

describe('meals/{mealId} made from a household’s own recipe (recipes ADR-0007 §6)', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  const ownMeal = `${MEALS}/recipe-${OWN}`;

  it('is created at recipe-<ownId>, naming it', async () => {
    await assertSucceeds(setDoc(doc(await asUser(SAM), ownMeal), fromOwnRecipe));
  });

  it('is refused under a stranger, anywhere else, or with a malformed id', async () => {
    await assertFails(setDoc(doc(await asUser('uid-stranger'), ownMeal), fromOwnRecipe));
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, `${MEALS}/bobotie`), fromOwnRecipe));
    for (const householdRecipeId of [
      'ai-0123456789abcdef0123',
      'own-0123',
      'own-0123456789ABCDEF0123',
      7,
    ]) {
      await assertFails(
        setDoc(doc(db, `${MEALS}/recipe-${String(householdRecipeId)}`), {
          ...fromOwnRecipe,
          householdRecipeId,
        }),
      );
    }
  });

  it('never carries both links', async () => {
    await assertFails(
      setDoc(doc(await asUser(SAM), ownMeal), { ...fromOwnRecipe, recipeId: 'bobotie' }),
    );
  });

  it('refuses an own recipe through `recipeId`, which a catalogue lookup would miss', async () => {
    await assertFails(setDoc(doc(await asUser(SAM), ownMeal), { ...fromRecipe, recipeId: OWN }));
  });

  it('never changes, gains or loses the link from a client', async () => {
    await givenData(async (db: Firestore) => {
      await setDoc(doc(db, ownMeal), { ...fromOwnRecipe, createdAt: new Date() });
    });
    const db = await asUser(SAM);
    await assertFails(
      updateDoc(doc(db, ownMeal), { householdRecipeId: 'own-ffffffffffffffffffff' }),
    );
    await assertFails(updateDoc(doc(db, ownMeal), { householdRecipeId: deleteField() }));
    await assertFails(updateDoc(doc(db, `${MEALS}/spaghetti`), { householdRecipeId: OWN }));
    await assertSucceeds(updateDoc(doc(db, ownMeal), { ingredients: LINES }));
  });
});

describe('meals/{mealId} made from a recipe', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('is created at recipe-<recipeId>, naming the recipe', async () => {
    await assertSucceeds(setDoc(doc(await asUser(SAM), BOBOTIE), fromRecipe));
  });

  it('is refused anywhere but recipe-<recipeId>', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, `${MEALS}/bobotie`), fromRecipe));
    await assertFails(setDoc(doc(db, `${MEALS}/recipe-sosaties`), fromRecipe));
  });

  it('is refused with an empty, over-long or non-string recipe id', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, `${MEALS}/recipe-`), { ...fromRecipe, recipeId: '' }));
    const long = 'x'.repeat(61);
    await assertFails(
      setDoc(doc(db, `${MEALS}/recipe-${long}`), { ...fromRecipe, recipeId: long }),
    );
    await assertFails(setDoc(doc(db, `${MEALS}/recipe-7`), { ...fromRecipe, recipeId: 7 }));
  });

  it('never changes, gains or loses its recipe id', async () => {
    const db = await asUser(SAM);
    const malva = `${MEALS}/recipe-malva-pudding`;
    await assertFails(updateDoc(doc(db, malva), { recipeId: 'melktert' }));
    await assertFails(updateDoc(doc(db, `${MEALS}/spaghetti`), { recipeId: 'spaghetti' }));
    await assertFails(updateDoc(doc(db, malva), { recipeId: deleteField() }));
  });

  it('keeps its name and ingredients the family’s to edit', async () => {
    const db = await asUser(SAM);
    const malva = `${MEALS}/recipe-malva-pudding`;
    await assertSucceeds(updateDoc(doc(db, malva), { ingredients: LINES }));
    await assertSucceeds(
      updateDoc(doc(db, malva), { name: 'Gran’s malva', nameKey: 'gran’s malva' }),
    );
  });
});
