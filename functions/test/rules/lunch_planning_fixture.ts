import { Timestamp, doc, setDoc } from 'firebase/firestore';

import { HOUSEHOLD } from './family_fixture';
import { ITEMS } from './lunch_box_fixture';
import { givenData, type Firestore } from './rules_harness';

/**
 * Lunch-box's V2 tools (lunch-box ADR-0006 to ADR-0008) on top of the lunch
 * fixture: the collections, a small library for the pantry and prices to
 * point at, and the household's premium.
 */

export const PANTRY = `households/${HOUSEHOLD}/lunchPantry`;
export const PACKED = `households/${HOUSEHOLD}/lunchPacked`;
export const PRICES = `households/${HOUSEHOLD}/lunchPrices`;
export const BUDGET = `households/${HOUSEHOLD}/lunchBudget`;
export const CHOICES = `households/${HOUSEHOLD}/lunchChoices`;
export const GROCERIES = `households/${HOUSEHOLD}/groceryItems`;
export const ENTITLEMENT = `households/${HOUSEHOLD}/entitlement/current`;
export const TUESDAY = '2026-09-29';

/** The library items the pantry and prices name. */
export async function givenTheLibrary(): Promise<void> {
  await givenData(async (db: Firestore) => {
    for (const [id, name, slot, allergens] of [
      ['apple', 'Apple', 'fruit', []],
      ['wrap', 'Chicken wrap', 'main', ['wheat']],
      ['pb', 'Peanut butter sandwich', 'main', ['peanut', 'wheat']],
    ] as const) {
      await setDoc(doc(db, `${ITEMS}/${id}`), {
        name,
        nameKey: name.toLowerCase(),
        slot,
        allergens: [...allergens],
        addedBy: 'm-sam',
        createdAt: new Date(),
      });
    }
  });
}

/** Premium for the household until a day from now, as a Function writes it. */
export async function givenPremium(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, ENTITLEMENT), {
      premiumUntil: Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000),
    });
  });
}

/** Premium that ran out an hour ago. */
export async function givenLapsedPremium(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, ENTITLEMENT), {
      premiumUntil: Timestamp.fromMillis(Date.now() - 60 * 60 * 1000),
    });
  });
}
