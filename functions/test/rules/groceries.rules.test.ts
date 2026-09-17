import {
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
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
const ITEMS = `households/${HOUSEHOLD}/groceryItems`;

async function givenTheParkers(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `households/${HOUSEHOLD}`), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [THANDI]: 'helper' },
    });
    await setDoc(doc(db, `households/${HOUSEHOLD}/members/${SAM_MEMBER}`), {
      displayName: 'Sam',
      color: 'violet',
      role: 'admin',
      claimedBy: SAM,
    });
    await setDoc(doc(db, `households/${HOUSEHOLD}/members/${THANDI_MEMBER}`), {
      displayName: 'Thandi',
      color: 'mint',
      role: 'helper',
      claimedBy: THANDI,
    });
    // Milk, added by Thandi, not yet bought.
    await setDoc(doc(db, `${ITEMS}/milk`), {
      name: 'Milk',
      quantity: '2 l',
      addedBy: THANDI_MEMBER,
      addedAt: new Date(),
      boughtAt: null,
      boughtBy: null,
    });
  });
}

const newItem = {
  name: 'Eggs',
  quantity: null,
  addedBy: THANDI_MEMBER,
  addedAt: serverTimestamp(),
  boughtAt: null,
  boughtBy: null,
};

describe('groceryItems/{itemId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('lets any member read the list', async () => {
    await assertSucceeds(getDoc(doc(await asUser(SAM), `${ITEMS}/milk`)));
    await assertSucceeds(getDoc(doc(await asUser(THANDI), `${ITEMS}/milk`)));
  });

  it('denies a stranger reading the list', async () => {
    await assertFails(getDoc(doc(await asUser(STRANGER), `${ITEMS}/milk`)));
  });

  it('lets a member add an item in their own name', async () => {
    const db = await asUser(THANDI);
    await assertSucceeds(setDoc(doc(db, `${ITEMS}/eggs`), newItem));
  });

  it('denies adding an item in somebody else"s name', async () => {
    const db = await asUser(THANDI);
    await assertFails(
      setDoc(doc(db, `${ITEMS}/eggs`), { ...newItem, addedBy: SAM_MEMBER }),
    );
  });

  it('denies adding an item already marked bought', async () => {
    const db = await asUser(THANDI);
    await assertFails(
      setDoc(doc(db, `${ITEMS}/eggs`), {
        ...newItem,
        boughtAt: serverTimestamp(),
        boughtBy: THANDI_MEMBER,
      }),
    );
  });

  it('denies an item that dates its own arrival, or has no name', async () => {
    const db = await asUser(THANDI);
    await assertFails(
      setDoc(doc(db, `${ITEMS}/eggs`), { ...newItem, addedAt: new Date('2000-01-01') }),
    );
    await assertFails(setDoc(doc(db, `${ITEMS}/eggs`), { ...newItem, name: '' }));
  });

  it('lets anybody in the household tick somebody else"s item', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(
      updateDoc(doc(db, `${ITEMS}/milk`), {
        boughtAt: serverTimestamp(),
        boughtBy: SAM_MEMBER,
      }),
    );
  });

  it('denies ticking in somebody else"s name', async () => {
    const db = await asUser(SAM);
    await assertFails(
      updateDoc(doc(db, `${ITEMS}/milk`), {
        boughtAt: serverTimestamp(),
        boughtBy: THANDI_MEMBER,
      }),
    );
  });

  it('denies a tick that dates itself', async () => {
    const db = await asUser(SAM);
    await assertFails(
      updateDoc(doc(db, `${ITEMS}/milk`), {
        boughtAt: new Date('2000-01-01'),
        boughtBy: SAM_MEMBER,
      }),
    );
  });

  it('lets anybody untick, which clears both fields together', async () => {
    await givenData(async (db) => {
      await updateDoc(doc(db, `${ITEMS}/milk`), {
        boughtAt: new Date(),
        boughtBy: SAM_MEMBER,
      });
    });
    const db = await asUser(THANDI);
    await assertSucceeds(
      updateDoc(doc(db, `${ITEMS}/milk`), { boughtAt: null, boughtBy: null }),
    );
  });

  it('denies unticking that leaves the buyer behind', async () => {
    await givenData(async (db) => {
      await updateDoc(doc(db, `${ITEMS}/milk`), {
        boughtAt: new Date(),
        boughtBy: SAM_MEMBER,
      });
    });
    const db = await asUser(THANDI);
    await assertFails(updateDoc(doc(db, `${ITEMS}/milk`), { boughtAt: null }));
  });

  it('lets the adder rename their own item', async () => {
    const db = await asUser(THANDI);
    await assertSucceeds(
      updateDoc(doc(db, `${ITEMS}/milk`), { name: 'Full cream milk', quantity: '2 l' }),
    );
  });

  it('lets an admin rename anybody"s item', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(
      updateDoc(doc(db, `${ITEMS}/milk`), { name: 'Milk (2%)', quantity: '2 l' }),
    );
  });

  it('denies a non-adder, non-admin renaming an item', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${ITEMS}/bread`), {
        name: 'Bread',
        quantity: null,
        addedBy: SAM_MEMBER,
        addedAt: new Date(),
        boughtAt: null,
        boughtBy: null,
      });
    });
    const db = await asUser(THANDI);
    await assertFails(updateDoc(doc(db, `${ITEMS}/bread`), { name: 'Cake' }));
  });

  it('denies rewriting who added an item or when', async () => {
    const db = await asUser(SAM);
    await assertFails(updateDoc(doc(db, `${ITEMS}/milk`), { addedBy: SAM_MEMBER }));
    await assertFails(updateDoc(doc(db, `${ITEMS}/milk`), { addedAt: new Date() }));
  });

  it('denies renaming and ticking in one write', async () => {
    const db = await asUser(SAM);
    await assertFails(
      updateDoc(doc(db, `${ITEMS}/milk`), {
        name: 'Cake',
        boughtAt: serverTimestamp(),
        boughtBy: SAM_MEMBER,
      }),
    );
  });

  it('lets the adder delete their own item, and an admin delete anybody"s', async () => {
    await assertSucceeds(deleteDoc(doc(await asUser(THANDI), `${ITEMS}/milk`)));
    await givenTheParkers();
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), `${ITEMS}/milk`)));
  });

  it('denies a non-adder, non-admin deleting an item', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${ITEMS}/bread`), {
        name: 'Bread',
        quantity: null,
        addedBy: SAM_MEMBER,
        addedAt: new Date(),
        boughtAt: null,
        boughtBy: null,
      });
    });
    await assertFails(deleteDoc(doc(await asUser(THANDI), `${ITEMS}/bread`)));
  });

  it('denies a stranger everything', async () => {
    const db = await asUser(STRANGER);
    await assertFails(setDoc(doc(db, `${ITEMS}/eggs`), newItem));
    await assertFails(updateDoc(doc(db, `${ITEMS}/milk`), { boughtAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(db, `${ITEMS}/milk`)));
  });
});
