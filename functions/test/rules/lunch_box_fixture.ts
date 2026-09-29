import { Timestamp, doc, setDoc } from 'firebase/firestore';

import { KID, PROFILES, THANDI, givenTheKidsDetails, givenTheParkers } from './family_fixture';
import { asKid, givenData, type Firestore } from './rules_harness';

/**
 * The Parkers for the lunch-box rules suite (lunch-box ADR-0001): the family
 * fixture — Sam an admin, Mia a second parent, Nomsa a carer on the carer
 * defaults (`lunch` view), Cleo a cleaner with no lunch, a kid tablet signed
 * in as `m-kid` on the kid defaults (`lunch` own) — plus the children lunches
 * are planned for:
 *
 * - `m-kid`: severe peanut allergy, mild milk allergy, a nut-free diet and a
 *   nut-free school (the family fixture's full profile);
 * - `m-zola`: a child with no rules at all;
 * - `m-school`: a child whose only nut rule is their school's;
 * - `m-diet`: a child whose only nut rule is the family's diet.
 *
 * `m-sam` has a profile that is not a child's.
 */

export const ZOLA = 'm-zola';
export const SCHOOL_ONLY = 'm-school';
export const DIET_ONLY = 'm-diet';
export const WEEK = '2026-W40';
export const MONDAY = '2026-09-28';
export const ITEMS = 'households/h1/lunchItems';
export const PLANS = 'households/h1/lunchPlans';
export const FAVOURITES = 'households/h1/lunchFavourites';
export const PREP = 'households/h1/lunchPrep';

export const kidsTablet = (): Promise<Firestore> =>
  asKid('kid_tablet', { householdId: 'h1', memberId: KID });

export const pick = (itemId: string, name: string, allergens: string[] = []): object => ({
  itemId,
  name,
  allergens,
});

export const WRAP = pick('wrap', 'Chicken wrap', ['wheat']);
export const PEANUT_BUTTER = pick('pb', 'Peanut butter sandwich', ['peanut', 'wheat']);
export const TRAIL_MIX = pick('trail', 'Trail mix', ['treeNut']);
export const YOGHURT = pick('yoghurt', 'Yoghurt', ['milk']);
export const APPLE = pick('apple', 'Apple');

/** The three fields that make a plan the plan it says it is. */
export function planOf(childId: string, slots: object = {}): object {
  return { childId, week: WEEK, weekStart: MONDAY, slots };
}

export const planPath = (childId: string): string => `${PLANS}/${childId}_${WEEK}`;

export async function givenTheLunchHousehold(): Promise<void> {
  await givenTheParkers();
  await givenTheKidsDetails();
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `${PROFILES}/${ZOLA}`), { isChild: true });
    await setDoc(doc(db, `${PROFILES}/${SCHOOL_ONLY}`), { isChild: true, schoolId: 'oakwood' });
    await setDoc(doc(db, `${PROFILES}/${DIET_ONLY}`), { isChild: true, diet: ['nutFree'] });
    await setDoc(doc(db, `${PROFILES}/m-sam`), { isChild: false });
  });
}

/** Thandi, a helper, given `lunch` at [level] by a parent. */
export async function givenThandiHasLunch(level: 'view' | 'edit'): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(
      doc(db, 'households/h1'),
      { access: { [THANDI]: { familyProfiles: 'view', lunch: level } } },
      { merge: true },
    );
  });
}

const DAY = 24 * 60 * 60 * 1000;

/**
 * Premium for the Parkers, a month ahead — or lapsed a day ago — written the
 * way only the subscriptions Functions write it (lunch-box ADR-0009).
 */
export async function givenLunchPremium(state: 'active' | 'lapsed' = 'active'): Promise<void> {
  const until = state === 'active' ? Date.now() + 30 * DAY : Date.now() - DAY;
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, 'households/h1/entitlement/current'), {
      premiumUntil: Timestamp.fromMillis(until),
    });
  });
}

/** The child the free tier plans for, as `setChildProfile` records it. */
export async function givenTheFreeChild(memberId: string): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, 'households/h1/entitlement/freeChild'), { memberId });
  });
}
