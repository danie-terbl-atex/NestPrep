import { deleteField, doc, getDoc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
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
 * The Checkers build contract, as the rules hold it: a grocery item's
 * `productMatch` — set and cleared by a groceries editor, shape-checked,
 * carried untouched through every write the list already made — and the
 * member's own `checkersLinks/{uid}`, which no client reads or writes.
 */

const SAM = 'uid-sam';
const THANDI = 'uid-thandi';
const STRANGER = 'uid-stranger';
const HOUSEHOLD = 'h1';
const SAM_MEMBER = 'm-sam';
const THANDI_MEMBER = 'm-thandi';
const ITEMS = `households/${HOUSEHOLD}/groceryItems`;

function pick(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    retailer: 'checkers',
    productId: '5f0c1a2b3c4d5e6f7a8b9c0d',
    articleCode: '10136729EA',
    unitOfMeasure: 'EA',
    name: 'Clover Full Cream Milk 2L',
    brand: 'Clover',
    priceCents: 3599,
    currency: 'ZAR',
    imageId: '64f0a1b2c3d4e5f6a7b8c9d0',
    pickedBy: THANDI_MEMBER,
    pickedAt: serverTimestamp(),
    ...overrides,
  };
}

/** A stored pick, as the server wrote it earlier. */
const storedPick = { ...pick(), pickedAt: new Date('2026-09-30T08:00:00Z') };

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
    await setDoc(doc(db, `${ITEMS}/milk`), {
      name: 'Milk',
      quantity: '2 l',
      addedBy: THANDI_MEMBER,
      addedAt: new Date(),
      boughtAt: null,
      boughtBy: null,
    });
    // A planned item that already carries a pick.
    await setDoc(doc(db, `${ITEMS}/plan-eggs`), {
      name: 'Eggs',
      quantity: '×6',
      addedBy: SAM_MEMBER,
      addedAt: new Date(),
      boughtAt: null,
      boughtBy: null,
      sourceKey: 'eggs',
      sourceWeek: '2026-W40',
      sourceNote: 'For Monday breakfast',
      productMatch: storedPick,
    });
  });
}

describe('groceryItems productMatch', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('lets a groceries editor pick a product in their own name', async () => {
    const db = await asUser(THANDI);
    await assertSucceeds(updateDoc(doc(db, `${ITEMS}/milk`), { productMatch: pick() }));
  });

  it('lets anybody who edits the list pick for an item somebody else added', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(
      updateDoc(doc(db, `${ITEMS}/milk`), { productMatch: pick({ pickedBy: SAM_MEMBER }) }),
    );
  });

  it('accepts a pick with no brand and no image, and a unit other than EA', async () => {
    const db = await asUser(THANDI);
    await assertSucceeds(
      updateDoc(doc(db, `${ITEMS}/milk`), {
        productMatch: pick({ brand: null, imageId: null, unitOfMeasure: 'KG' }),
      }),
    );
  });

  it('lets a member clear a pick, by deleting it or nulling it', async () => {
    const db = await asUser(THANDI);
    await assertSucceeds(updateDoc(doc(db, `${ITEMS}/plan-eggs`), { productMatch: deleteField() }));
    await givenTheParkers();
    await assertSucceeds(updateDoc(doc(db, `${ITEMS}/plan-eggs`), { productMatch: null }));
  });

  it('denies a pick in somebody else"s name', async () => {
    const db = await asUser(THANDI);
    await assertFails(
      updateDoc(doc(db, `${ITEMS}/milk`), { productMatch: pick({ pickedBy: SAM_MEMBER }) }),
    );
  });

  it('denies a pick that dates itself', async () => {
    const db = await asUser(THANDI);
    await assertFails(
      updateDoc(doc(db, `${ITEMS}/milk`), {
        productMatch: pick({ pickedAt: new Date('2000-01-01') }),
      }),
    );
  });

  it.each([
    ['another retailer', { retailer: 'pnp' }],
    ['a product id that is not 24 hex', { productId: 'not-a-product' }],
    ['a price in rand rather than cents', { priceCents: 35.99 }],
    ['a negative price', { priceCents: -1 }],
    ['another currency', { currency: 'USD' }],
    ['an empty name', { name: '' }],
    ['a name longer than any product', { name: 'x'.repeat(201) }],
    ['a unit that is not a code', { unitOfMeasure: 'per kilogram' }],
    ['an article code with punctuation', { articleCode: '1013/6729' }],
  ])('denies a pick with %s', async (_, overrides) => {
    const db = await asUser(THANDI);
    await assertFails(updateDoc(doc(db, `${ITEMS}/milk`), { productMatch: pick(overrides) }));
  });

  it('denies a pick with a field the contract does not have, or one missing', async () => {
    const db = await asUser(THANDI);
    await assertFails(
      updateDoc(doc(db, `${ITEMS}/milk`), { productMatch: { ...pick(), cartLineId: 'x' } }),
    );
    const withoutBrand = pick();
    delete withoutBrand['brand'];
    await assertFails(updateDoc(doc(db, `${ITEMS}/milk`), { productMatch: withoutBrand }));
  });

  it('denies picking and ticking in one write', async () => {
    const db = await asUser(THANDI);
    await assertFails(
      updateDoc(doc(db, `${ITEMS}/milk`), {
        productMatch: pick(),
        boughtAt: serverTimestamp(),
        boughtBy: THANDI_MEMBER,
      }),
    );
  });

  it('denies a stranger picking', async () => {
    const db = await asUser(STRANGER);
    await assertFails(updateDoc(doc(db, `${ITEMS}/milk`), { productMatch: pick() }));
  });

  it('denies adding an item that arrives already picked, and allows one that says null', async () => {
    const db = await asUser(THANDI);
    const item = {
      name: 'Bread',
      quantity: null,
      addedBy: THANDI_MEMBER,
      addedAt: serverTimestamp(),
      boughtAt: null,
      boughtBy: null,
    };
    await assertFails(setDoc(doc(db, `${ITEMS}/bread`), { ...item, productMatch: pick() }));
    await assertSucceeds(setDoc(doc(db, `${ITEMS}/bread`), { ...item, productMatch: null }));
  });
});

describe('the list"s own writes on an item that carries a pick', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('still lets the plans refresh a planned item, and the pick stays', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(
      updateDoc(doc(db, `${ITEMS}/plan-eggs`), { quantity: '×12', sourceNote: 'For the week' }),
    );
  });

  it('still lets anybody tick and untick it', async () => {
    const db = await asUser(THANDI);
    await assertSucceeds(
      updateDoc(doc(db, `${ITEMS}/plan-eggs`), {
        boughtAt: serverTimestamp(),
        boughtBy: THANDI_MEMBER,
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db, `${ITEMS}/plan-eggs`), { boughtAt: null, boughtBy: null }),
    );
  });

  it('lets a rename clear the pick, and lets an older app rename without touching it', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(
      updateDoc(doc(db, `${ITEMS}/plan-eggs`), {
        name: 'Free-range eggs',
        quantity: '×6',
        sourceKey: null,
        sourceWeek: null,
        sourceNote: null,
        productMatch: deleteField(),
      }),
    );
    await givenTheParkers();
    await assertSucceeds(
      updateDoc(doc(db, `${ITEMS}/plan-eggs`), {
        name: 'Brown eggs',
        quantity: '×6',
        sourceKey: null,
        sourceWeek: null,
        sourceNote: null,
      }),
    );
  });

  it('denies a rename that swaps the pick for another', async () => {
    const db = await asUser(SAM);
    await assertFails(
      updateDoc(doc(db, `${ITEMS}/plan-eggs`), {
        name: 'Brown eggs',
        sourceKey: null,
        sourceWeek: null,
        sourceNote: null,
        productMatch: pick({ pickedBy: SAM_MEMBER, productId: 'aaaaaaaaaaaaaaaaaaaaaaaa' }),
      }),
    );
  });

  it('denies a plan refresh that drops the pick', async () => {
    const db = await asUser(SAM);
    await assertFails(
      updateDoc(doc(db, `${ITEMS}/plan-eggs`), {
        quantity: '×12',
        sourceNote: 'For the week',
        productMatch: deleteField(),
      }),
    );
  });
});

describe('checkersLinks/{uid}', () => {
  beforeEach(async () => {
    await clearData();
    await givenData(async (db: Firestore) => {
      await setDoc(doc(db, `checkersLinks/${SAM}`), { mobileMasked: '+27 ** *** 4567' });
    });
  });

  it('is written by the Functions alone, which the harness stands in for', async () => {
    await givenData(async (db: Firestore) => {
      await assertSucceeds(getDoc(doc(db, `checkersLinks/${SAM}`)));
    });
  });

  it('denies the member it belongs to reading or writing it', async () => {
    const db = await asUser(SAM);
    await assertFails(getDoc(doc(db, `checkersLinks/${SAM}`)));
    await assertFails(setDoc(doc(db, `checkersLinks/${SAM}`), { mobileMasked: 'x' }));
    await assertFails(updateDoc(doc(db, `checkersLinks/${SAM}`), { mobileMasked: 'x' }));
  });

  it('denies anybody else too', async () => {
    const db = await asUser(STRANGER);
    await assertFails(getDoc(doc(db, `checkersLinks/${SAM}`)));
    await assertFails(setDoc(doc(db, `checkersLinks/${STRANGER}`), { mobileMasked: 'x' }));
  });
});
