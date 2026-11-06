import { doc, getDoc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
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
const THANDI_MEMBER = 'm-thandi';
const ITEMS = `households/${HOUSEHOLD}/groceryItems`;

function woolworthsPick(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    retailer: 'woolworths',
    productId: '20011697',
    articleCode: '20011697',
    unitOfMeasure: 'EA',
    name: 'Fresh Full Cream Milk 2 L',
    brand: null,
    priceCents: 4099,
    currency: 'ZAR',
    imageId: 'Fresh-Full-Cream-Milk-2-L-20011697.jpg?V=Q2xp&o=eyJidWNrZXQiOiJ3dyJ9&',
    pickedBy: THANDI_MEMBER,
    pickedAt: serverTimestamp(),
    ...overrides,
  };
}

async function givenTheParkers(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `households/${HOUSEHOLD}`), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [THANDI]: 'helper' },
    });
    await setDoc(doc(db, `households/${HOUSEHOLD}/members/${THANDI_MEMBER}`), {
      displayName: 'Thandi',
      color: 'mint',
      role: 'helper',
      claimedBy: THANDI,
    });
    await setDoc(doc(db, `${ITEMS}/milk`), {
      name: 'Milk',
      quantity: '2 L',
      addedBy: THANDI_MEMBER,
      addedAt: new Date(),
      boughtAt: null,
      boughtBy: null,
    });
  });
}

describe('groceryItems productMatch at Woolworths', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('lets a groceries editor pick a Woolworths product in their own name', async () => {
    const db = await asUser(THANDI);
    await assertSucceeds(updateDoc(doc(db, `${ITEMS}/milk`), { productMatch: woolworthsPick() }));
  });

  it('takes a weighed product and no picture', async () => {
    const db = await asUser(THANDI);
    await assertSucceeds(
      updateDoc(doc(db, `${ITEMS}/milk`), {
        productMatch: woolworthsPick({
          productId: '2000000123456',
          articleCode: '2000000123456',
          unitOfMeasure: 'KG',
          imageId: null,
        }),
      }),
    );
  });

  it.each([
    ['a SKU too short', { productId: '12345', articleCode: '12345' }],
    ['a SKU too long', { productId: '123456789012345', articleCode: '123456789012345' }],
    ['a SKU with letters', { productId: '2001169A', articleCode: '2001169A' }],
    ['an article code that is not the SKU', { articleCode: '20026875' }],
    ['a unit Woolworths does not sell by', { unitOfMeasure: 'PK1' }],
    ['an image path with a folder', { imageId: 'images/milk.jpg' }],
    ['an image name with a space', { imageId: 'Fresh Milk.jpg' }],
    ['an image name past 600 characters', { imageId: 'x'.repeat(601) }],
    ['a PnP code under the Woolworths name', { productId: '000000000000838685_EA' }],
    ['a Woolworths SKU under the Checkers name', { retailer: 'checkers' }],
    ['a price in rand', { priceCents: 40.99 }],
    ['another currency', { currency: 'USD' }],
  ])('denies a pick with %s', async (_, overrides) => {
    const db = await asUser(THANDI);
    await assertFails(
      updateDoc(doc(db, `${ITEMS}/milk`), { productMatch: woolworthsPick(overrides) }),
    );
  });

  it('denies a pick from somebody outside the household, or in somebody else’s name', async () => {
    await assertFails(
      updateDoc(doc(await asUser(STRANGER), `${ITEMS}/milk`), { productMatch: woolworthsPick() }),
    );
    await assertFails(
      updateDoc(doc(await asUser(THANDI), `${ITEMS}/milk`), {
        productMatch: woolworthsPick({ pickedBy: 'm-sam' }),
      }),
    );
  });

  it('allows adding an item already matched at Woolworths, and denies a match not well formed', async () => {
    const db = await asUser(THANDI);
    const item = {
      name: 'Bread',
      quantity: '1 loaf',
      addedBy: THANDI_MEMBER,
      addedAt: serverTimestamp(),
      boughtAt: null,
      boughtBy: null,
    };
    await assertSucceeds(
      setDoc(doc(db, `${ITEMS}/bread`), { ...item, productMatch: woolworthsPick() }),
    );
    for (const bad of [
      woolworthsPick({ pickedAt: new Date('2000-01-01') }),
      woolworthsPick({ productId: '838685', articleCode: '838686' }),
    ]) {
      await assertFails(setDoc(doc(db, `${ITEMS}/other`), { ...item, productMatch: bad }));
    }
  });
});

describe('woolworthsLinks/{uid}', () => {
  beforeEach(async () => {
    await clearData();
    await givenData(async (db: Firestore) => {
      await setDoc(doc(db, `woolworthsLinks/${SAM}`), { session: null });
    });
  });

  it('is written by the Functions alone, which the harness stands in for', async () => {
    await givenData(async (db: Firestore) => {
      await assertSucceeds(getDoc(doc(db, `woolworthsLinks/${SAM}`)));
    });
  });

  it('denies the member it belongs to reading or writing it', async () => {
    const db = await asUser(SAM);
    await assertFails(getDoc(doc(db, `woolworthsLinks/${SAM}`)));
    await assertFails(setDoc(doc(db, `woolworthsLinks/${SAM}`), { session: 'x' }));
    await assertFails(updateDoc(doc(db, `woolworthsLinks/${SAM}`), { session: 'x' }));
  });

  it('denies anybody else too', async () => {
    const db = await asUser(STRANGER);
    await assertFails(getDoc(doc(db, `woolworthsLinks/${SAM}`)));
    await assertFails(setDoc(doc(db, `woolworthsLinks/${STRANGER}`), { session: 'x' }));
  });
});
