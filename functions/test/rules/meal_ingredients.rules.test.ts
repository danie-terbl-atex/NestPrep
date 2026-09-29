import { doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { uniformGrant } from '../../src/household/access';
import {
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

// Meal-planning ADR-0002: a meal carries its ingredients, and anybody who
// edits meals keeps them — while renaming stays the adder's or an admin's.

const SAM = 'uid-sam';
const THANDI = 'uid-thandi';
const VERA = 'uid-vera';
const HOUSEHOLD = 'h1';
const SAM_MEMBER = 'm-sam';
const THANDI_MEMBER = 'm-thandi';
const VERA_MEMBER = 'm-vera';
const SPAGHETTI = `households/${HOUSEHOLD}/meals/spaghetti`;

const LINES = [
  { name: 'Mince', amount: 500, unit: 'g' },
  { name: 'Onions', amount: 2, unit: null },
  { name: 'Salt', amount: null, unit: null },
];

async function givenTheParkers(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `households/${HOUSEHOLD}`), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [THANDI]: 'helper', [VERA]: 'helper' },
      profiles: { [VERA]: VERA_MEMBER },
      access: { [VERA]: uniformGrant('view') },
    });
    for (const [id, name, role, claimedBy] of [
      [SAM_MEMBER, 'Sam', 'admin', SAM],
      [THANDI_MEMBER, 'Thandi', 'helper', THANDI],
      [VERA_MEMBER, 'Vera', 'helper', VERA],
    ] as const) {
      await setDoc(doc(db, `households/${HOUSEHOLD}/members/${id}`), {
        displayName: name,
        color: 'violet',
        role,
        claimedBy,
      });
    }
    // Sam's meal; Thandi did not add it.
    await setDoc(doc(db, SPAGHETTI), {
      name: 'Spaghetti',
      nameKey: 'spaghetti',
      addedBy: SAM_MEMBER,
      createdAt: new Date(),
    });
  });
}

describe('meals/{mealId} — what goes in it', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('lets a meal be created with its ingredients', async () => {
    await assertSucceeds(
      setDoc(doc(await asUser(THANDI), `households/${HOUSEHOLD}/meals/lasagne`), {
        name: 'Lasagne',
        nameKey: 'lasagne',
        addedBy: THANDI_MEMBER,
        createdAt: serverTimestamp(),
        ingredients: LINES,
      }),
    );
  });

  it('lets any meals editor, not only the adder, keep a meal’s ingredients', async () => {
    await assertSucceeds(updateDoc(doc(await asUser(THANDI), SPAGHETTI), { ingredients: LINES }));
  });

  it('denies a reader of the meals changing what goes in one', async () => {
    await assertFails(updateDoc(doc(await asUser(VERA), SPAGHETTI), { ingredients: LINES }));
  });

  it('denies an ingredients write that renames too — renaming stays the adder’s', async () => {
    await assertFails(
      updateDoc(doc(await asUser(THANDI), SPAGHETTI), {
        ingredients: LINES,
        name: 'Spag bol',
        nameKey: 'spag bol',
      }),
    );
  });

  it('denies more than forty lines, or ingredients that are not a list', async () => {
    const tooMany = Array.from({ length: 41 }, (_, i) => ({ name: `Thing ${String(i)}` }));
    const db = await asUser(THANDI);
    await assertFails(updateDoc(doc(db, SPAGHETTI), { ingredients: tooMany }));
    await assertFails(updateDoc(doc(db, SPAGHETTI), { ingredients: 'mince, onions' }));
  });
});
