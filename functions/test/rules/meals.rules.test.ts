import { deleteDoc, doc, getDoc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

const SAM = 'uid-sam';
const THANDI = 'uid-thandi';
const STRANGER = 'uid-stranger';
const HOUSEHOLD = 'h1';
const SAM_MEMBER = 'm-sam';
const THANDI_MEMBER = 'm-thandi';
const MEALS = `households/${HOUSEHOLD}/meals`;
const PLANS = `households/${HOUSEHOLD}/mealPlans`;
const MONDAY = '2026-09-14';

async function givenTheParkers(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `households/${HOUSEHOLD}`), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [THANDI]: 'helper' },
    });
    for (const [id, name, role, claimedBy] of [
      [SAM_MEMBER, 'Sam', 'admin', SAM],
      [THANDI_MEMBER, 'Thandi', 'helper', THANDI],
    ] as const) {
      await setDoc(doc(db, `households/${HOUSEHOLD}/members/${id}`), {
        displayName: name,
        color: 'violet',
        role,
        claimedBy,
      });
    }
    await setDoc(doc(db, `${MEALS}/spaghetti`), {
      name: 'Spaghetti',
      nameKey: 'spaghetti',
      addedBy: THANDI_MEMBER,
      createdAt: new Date(),
    });
  });
}

const newMeal = {
  name: 'Lasagne',
  nameKey: 'lasagne',
  addedBy: THANDI_MEMBER,
  createdAt: serverTimestamp(),
};

describe('meals/{mealId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('lets any member read the library, and denies a stranger', async () => {
    await assertSucceeds(getDoc(doc(await asUser(SAM), `${MEALS}/spaghetti`)));
    await assertFails(getDoc(doc(await asUser(STRANGER), `${MEALS}/spaghetti`)));
  });

  it('lets a member add a meal in their own name', async () => {
    await assertSucceeds(setDoc(doc(await asUser(THANDI), `${MEALS}/lasagne`), newMeal));
  });

  it('denies adding a meal in somebody else"s name', async () => {
    await assertFails(
      setDoc(doc(await asUser(THANDI), `${MEALS}/lasagne`), {
        ...newMeal,
        addedBy: SAM_MEMBER,
      }),
    );
  });

  it('denies a meal with no name, or a key that is not normalised', async () => {
    const db = await asUser(THANDI);
    await assertFails(setDoc(doc(db, `${MEALS}/a`), { ...newMeal, name: '' }));
    await assertFails(setDoc(doc(db, `${MEALS}/b`), { ...newMeal, nameKey: '' }));
    await assertFails(setDoc(doc(db, `${MEALS}/c`), { ...newMeal, nameKey: 'Lasagne' }));
  });

  it('denies a meal that dates its own arrival', async () => {
    await assertFails(
      setDoc(doc(await asUser(THANDI), `${MEALS}/lasagne`), {
        ...newMeal,
        createdAt: new Date('2000-01-01'),
      }),
    );
  });

  it('lets the adder rename their meal, and an admin rename anybody"s', async () => {
    await assertSucceeds(
      updateDoc(doc(await asUser(THANDI), `${MEALS}/spaghetti`), {
        name: 'Spaghetti bolognese',
        nameKey: 'spaghetti bolognese',
      }),
    );
    await assertSucceeds(
      updateDoc(doc(await asUser(SAM), `${MEALS}/spaghetti`), {
        name: 'Spaghetti',
        nameKey: 'spaghetti',
      }),
    );
  });

  it('denies a non-adder, non-admin renaming a meal', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${MEALS}/sams-pie`), {
        name: 'Pie',
        nameKey: 'pie',
        addedBy: SAM_MEMBER,
        createdAt: new Date(),
      });
    });
    await assertFails(
      updateDoc(doc(await asUser(THANDI), `${MEALS}/sams-pie`), {
        name: 'Not pie',
        nameKey: 'not pie',
      }),
    );
  });

  it('denies rewriting who added a meal', async () => {
    await assertFails(
      updateDoc(doc(await asUser(SAM), `${MEALS}/spaghetti`), {
        addedBy: SAM_MEMBER,
      }),
    );
  });

  it('lets the adder or an admin delete, and denies anybody else', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${MEALS}/sams-pie`), {
        name: 'Pie',
        nameKey: 'pie',
        addedBy: SAM_MEMBER,
        createdAt: new Date(),
      });
    });
    await assertFails(deleteDoc(doc(await asUser(THANDI), `${MEALS}/sams-pie`)));
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), `${MEALS}/sams-pie`)));
    await assertSucceeds(deleteDoc(doc(await asUser(THANDI), `${MEALS}/spaghetti`)));
  });
});

describe('mealPlans/{weekStart}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('lets any member fill a slot — the plan has no owner', async () => {
    await assertSucceeds(
      setDoc(doc(await asUser(THANDI), `${PLANS}/${MONDAY}`), {
        slots: { '2_dinner': 'spaghetti' },
      }),
    );
    await assertSucceeds(
      updateDoc(doc(await asUser(SAM), `${PLANS}/${MONDAY}`), {
        'slots.4_dinner': 'spaghetti',
      }),
    );
  });

  it('lets any member clear a slot', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${PLANS}/${MONDAY}`), {
        slots: { '2_dinner': 'spaghetti' },
      });
    });
    await assertSucceeds(
      updateDoc(doc(await asUser(THANDI), `${PLANS}/${MONDAY}`), {
        'slots.2_dinner': '',
      }),
    );
  });

  it('denies a week with more slots than a week has', async () => {
    const tooMany: Record<string, string> = {};
    for (let index = 0; index < 22; index += 1) {
      tooMany[`slot-${index.toString()}`] = 'spaghetti';
    }
    await assertFails(setDoc(doc(await asUser(THANDI), `${PLANS}/${MONDAY}`), { slots: tooMany }));
  });

  it('denies a field the plan does not have', async () => {
    await assertFails(
      setDoc(doc(await asUser(THANDI), `${PLANS}/${MONDAY}`), {
        slots: {},
        owner: THANDI_MEMBER,
      }),
    );
  });

  it('denies a non-admin deleting a whole week', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${PLANS}/${MONDAY}`), { slots: {} });
    });
    await assertFails(deleteDoc(doc(await asUser(THANDI), `${PLANS}/${MONDAY}`)));
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), `${PLANS}/${MONDAY}`)));
  });

  it('denies a stranger everything', async () => {
    const db = await asUser(STRANGER);
    await assertFails(getDoc(doc(db, `${PLANS}/${MONDAY}`)));
    await assertFails(setDoc(doc(db, `${PLANS}/${MONDAY}`), { slots: {} }));
  });
});
