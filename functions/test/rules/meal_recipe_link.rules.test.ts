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
