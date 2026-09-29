import { deleteDoc, doc, getDoc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
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

// Groceries ADR-0002: items the week's plans put on the list, and the
// household's keep-in-step switch and staples.

const SAM = 'uid-sam';
const THANDI = 'uid-thandi';
const VERA = 'uid-vera';
const STRANGER = 'uid-stranger';
const HOUSEHOLD = 'h1';
const SAM_MEMBER = 'm-sam';
const THANDI_MEMBER = 'm-thandi';
const VERA_MEMBER = 'm-vera';
const ITEMS = `households/${HOUSEHOLD}/groceryItems`;
const SETTINGS = `households/${HOUSEHOLD}/grocerySettings/plans`;
const WEEK = '2026-W40';
const PLANNED = `${ITEMS}/plan-${WEEK}-bread`;

async function givenTheParkers(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `households/${HOUSEHOLD}`), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [THANDI]: 'helper', [VERA]: 'helper' },
      profiles: { [VERA]: VERA_MEMBER },
      // Vera reads everything and changes nothing (household ADR-0003).
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
    // Bread, which Sam's list kept in step with the week's plans.
    await setDoc(doc(db, PLANNED), {
      ...planned(SAM_MEMBER),
      addedAt: new Date(),
    });
    // Milk, which Sam typed.
    await setDoc(doc(db, `${ITEMS}/milk`), {
      name: 'Milk',
      quantity: null,
      addedBy: SAM_MEMBER,
      addedAt: new Date(),
      boughtAt: null,
      boughtBy: null,
      sourceKey: null,
      sourceWeek: null,
      sourceNote: null,
    });
  });
}

function planned(addedBy: string): Record<string, unknown> {
  return {
    name: 'Bread',
    quantity: '2 loaves',
    addedBy,
    addedAt: serverTimestamp(),
    boughtAt: null,
    boughtBy: null,
    sourceKey: 'bread',
    sourceWeek: WEEK,
    sourceNote: 'For 5 lunches + Tuesday dinner',
  };
}

describe('groceryItems — what the week’s plans put on the list', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('lets an editor add a planned item in their own name', async () => {
    const db = await asUser(THANDI);
    await assertSucceeds(setDoc(doc(db, `${ITEMS}/plan-${WEEK}-eggs`), planned(THANDI_MEMBER)));
  });

  it('denies a planned item with half its source, a bad week, or a long note', async () => {
    const db = await asUser(THANDI);
    const at = doc(db, `${ITEMS}/plan-${WEEK}-eggs`);
    await assertFails(setDoc(at, { ...planned(THANDI_MEMBER), sourceWeek: null }));
    await assertFails(setDoc(at, { ...planned(THANDI_MEMBER), sourceWeek: '2026-40' }));
    await assertFails(setDoc(at, { ...planned(THANDI_MEMBER), sourceKey: 'Bread' }));
    await assertFails(setDoc(at, { ...planned(THANDI_MEMBER), sourceNote: 'x'.repeat(201) }));
    await assertFails(setDoc(at, { ...planned(THANDI_MEMBER), sourceKey: null, sourceWeek: WEEK }));
  });

  it('denies a planned item from somebody who may only read the list', async () => {
    const db = await asUser(VERA);
    await assertFails(setDoc(doc(db, `${ITEMS}/plan-${WEEK}-eggs`), planned(VERA_MEMBER)));
  });

  it('lets any editor bring an unbought planned item up to date', async () => {
    const db = await asUser(THANDI);
    await assertSucceeds(
      updateDoc(doc(db, PLANNED), { quantity: '3 loaves', sourceNote: 'For 6 lunches' }),
    );
  });

  it('denies a refresh that moves anything else, or touches a typed item', async () => {
    const db = await asUser(THANDI);
    await assertFails(
      updateDoc(doc(db, PLANNED), { quantity: '3 loaves', sourceWeek: '2026-W41' }),
    );
    // A typed item's text is its adder's; a refresh is not a way round that.
    await assertFails(
      updateDoc(doc(db, `${ITEMS}/milk`), { quantity: '2 l', sourceNote: 'For Tuesday' }),
    );
  });

  it('denies refreshing a planned item once somebody has bought it', async () => {
    await givenData(async (db: Firestore) => {
      await updateDoc(doc(db, PLANNED), { boughtAt: new Date(), boughtBy: SAM_MEMBER });
    });
    const db = await asUser(THANDI);
    await assertFails(updateDoc(doc(db, PLANNED), { quantity: '3 loaves', sourceNote: 'x' }));
    await assertFails(deleteDoc(doc(db, PLANNED)));
  });

  it('lets any editor adopt a planned item by editing it, clearing its source', async () => {
    const db = await asUser(THANDI);
    await assertSucceeds(
      updateDoc(doc(db, PLANNED), {
        name: 'Brown bread',
        quantity: '3 loaves',
        sourceKey: null,
        sourceWeek: null,
        sourceNote: null,
      }),
    );
  });

  it('denies an edit that keeps the source — an edit is always an adoption', async () => {
    const db = await asUser(THANDI);
    await assertFails(updateDoc(doc(db, PLANNED), { name: 'Brown bread', quantity: '3' }));
  });

  it('still keeps a typed item’s text to its adder or an admin', async () => {
    const edit = {
      name: 'Oat milk',
      quantity: null,
      sourceKey: null,
      sourceWeek: null,
      sourceNote: null,
    };
    await assertFails(updateDoc(doc(await asUser(THANDI), `${ITEMS}/milk`), edit));
    await assertSucceeds(updateDoc(doc(await asUser(SAM), `${ITEMS}/milk`), edit));
  });

  it('lets any editor take an unbought planned item off, never a typed one', async () => {
    const db = await asUser(THANDI);
    await assertSucceeds(deleteDoc(doc(db, PLANNED)));
    await assertFails(deleteDoc(doc(db, `${ITEMS}/milk`)));
  });

  it('denies a reader taking a planned item off', async () => {
    await assertFails(deleteDoc(doc(await asUser(VERA), PLANNED)));
  });
});

describe('grocerySettings/plans — keep in step, and staples', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  const settings = (by: string): Record<string, unknown> => ({
    keepInStep: true,
    staples: ['salt'],
    updatedBy: by,
    updatedAt: serverTimestamp(),
  });

  it('lets an editor turn keeping in step on, signed in their own name', async () => {
    await assertSucceeds(setDoc(doc(await asUser(THANDI), SETTINGS), settings(THANDI_MEMBER)));
  });

  it('lets every member of the list read it, and nobody outside', async () => {
    await assertSucceeds(getDoc(doc(await asUser(VERA), SETTINGS)));
    await assertFails(getDoc(doc(await asUser(STRANGER), SETTINGS)));
  });

  it('denies a reader, a borrowed name, and a device clock', async () => {
    await assertFails(setDoc(doc(await asUser(VERA), SETTINGS), settings(VERA_MEMBER)));
    await assertFails(setDoc(doc(await asUser(THANDI), SETTINGS), settings(SAM_MEMBER)));
    await assertFails(
      setDoc(doc(await asUser(THANDI), SETTINGS), {
        ...settings(THANDI_MEMBER),
        updatedAt: new Date('2000-01-01'),
      }),
    );
  });

  it('denies any other document, any other field, or too many staples', async () => {
    const db = await asUser(THANDI);
    await assertFails(
      setDoc(doc(db, `households/${HOUSEHOLD}/grocerySettings/other`), settings(THANDI_MEMBER)),
    );
    await assertFails(setDoc(doc(db, SETTINGS), { ...settings(THANDI_MEMBER), shop: 'Spar' }));
    await assertFails(setDoc(doc(db, SETTINGS), { ...settings(THANDI_MEMBER), keepInStep: 'yes' }));
    await assertFails(
      setDoc(doc(db, SETTINGS), {
        ...settings(THANDI_MEMBER),
        staples: Array.from({ length: 201 }, (_, i) => `item ${String(i)}`),
      }),
    );
  });

  it('is never deleted', async () => {
    await givenData(async (db: Firestore) => {
      await setDoc(doc(db, SETTINGS), {
        keepInStep: true,
        staples: [],
        updatedBy: SAM_MEMBER,
        updatedAt: new Date(),
      });
    });
    await assertFails(deleteDoc(doc(await asUser(SAM), SETTINGS)));
  });
});
