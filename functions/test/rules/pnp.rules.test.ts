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

/**
 * Add to Pick n Pay as the rules hold it: a grocery item's `productMatch` may
 * be at Pick n Pay in PnP's own shape (groceries ADR-0007), and the member's
 * own `pnpLinks/{uid}`, which no client reads or writes (add-to-pnp ADR-0003).
 */
const SAM = 'uid-sam';
const THANDI = 'uid-thandi';
const STRANGER = 'uid-stranger';
const HOUSEHOLD = 'h1';
const THANDI_MEMBER = 'm-thandi';
const ITEMS = `households/${HOUSEHOLD}/groceryItems`;

function pnpPick(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    retailer: 'pickNPay',
    productId: '000000000000838685_EA',
    articleCode: '000000000000838685',
    unitOfMeasure: 'EA',
    name: 'Simba Potato Chips Mrs Balls Chutney 120g',
    brand: null,
    priceCents: 2199,
    currency: 'ZAR',
    imageId:
      'sys-master/images/haf/hf1/11268779245598/silo-product-image-v2-22Sep2023-180615-6001056414524-Straight_on-175412-359_300Wx300H',
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
    await setDoc(doc(db, `${ITEMS}/chips`), {
      name: 'Chips',
      quantity: '2 packs',
      addedBy: THANDI_MEMBER,
      addedAt: new Date(),
      boughtAt: null,
      boughtBy: null,
    });
  });
}

describe('groceryItems productMatch at Pick n Pay', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('lets a groceries editor pick a PnP product in their own name', async () => {
    const db = await asUser(THANDI);
    await assertSucceeds(updateDoc(doc(db, `${ITEMS}/chips`), { productMatch: pnpPick() }));
  });

  it('takes a weighed or case code, and no picture', async () => {
    const db = await asUser(THANDI);
    await assertSucceeds(
      updateDoc(doc(db, `${ITEMS}/chips`), {
        productMatch: pnpPick({
          productId: '000000000000123456_KGM',
          unitOfMeasure: 'KGM',
          imageId: null,
        }),
      }),
    );
  });

  it.each([
    ['a Checkers id under the PnP name', { productId: '5f0c1a2b3c4d5e6f7a8b9c0d' }],
    ['a PnP code under the Checkers name', { retailer: 'checkers' }],
    ['a code without its unit', { productId: '000000000000838685' }],
    ['an article code with letters', { articleCode: '838685EA' }],
    ['an image path longer than any PnP path', { imageId: 'x'.repeat(301) }],
    ['a shop NestPrep does not know', { retailer: 'woolworths' }],
    ['a price in rand', { priceCents: 21.99 }],
  ])('denies a pick with %s', async (_, overrides) => {
    const db = await asUser(THANDI);
    await assertFails(updateDoc(doc(db, `${ITEMS}/chips`), { productMatch: pnpPick(overrides) }));
  });

  it('denies a pick from somebody outside the household', async () => {
    const db = await asUser(STRANGER);
    await assertFails(updateDoc(doc(db, `${ITEMS}/chips`), { productMatch: pnpPick() }));
  });

  it('allows adding an item already matched at Pick n Pay, and denies a match not the adder’s or not well formed', async () => {
    const db = await asUser(THANDI);
    const item = {
      name: 'Biltong',
      quantity: '2 packs',
      addedBy: THANDI_MEMBER,
      addedAt: serverTimestamp(),
      boughtAt: null,
      boughtBy: null,
    };
    await assertSucceeds(setDoc(doc(db, `${ITEMS}/biltong`), { ...item, productMatch: pnpPick() }));
    for (const bad of [
      pnpPick({ pickedBy: 'm-sam' }),
      pnpPick({ pickedAt: new Date('2000-01-01') }),
      pnpPick({ productId: '838685' }),
      pnpPick({ retailer: 'woolworths' }),
    ]) {
      await assertFails(setDoc(doc(db, `${ITEMS}/other`), { ...item, productMatch: bad }));
    }
  });
});

describe('pnpLinks/{uid}', () => {
  beforeEach(async () => {
    await clearData();
    await givenData(async (db: Firestore) => {
      await setDoc(doc(db, `pnpLinks/${SAM}`), { pending: null, session: null });
    });
  });

  it('is written by the Functions alone, which the harness stands in for', async () => {
    await givenData(async (db: Firestore) => {
      await assertSucceeds(getDoc(doc(db, `pnpLinks/${SAM}`)));
    });
  });

  it('denies the member it belongs to reading or writing it', async () => {
    const db = await asUser(SAM);
    await assertFails(getDoc(doc(db, `pnpLinks/${SAM}`)));
    await assertFails(setDoc(doc(db, `pnpLinks/${SAM}`), { session: 'x' }));
    await assertFails(updateDoc(doc(db, `pnpLinks/${SAM}`), { session: 'x' }));
  });

  it('denies anybody else too', async () => {
    const db = await asUser(STRANGER);
    await assertFails(getDoc(doc(db, `pnpLinks/${SAM}`)));
    await assertFails(setDoc(doc(db, `pnpLinks/${STRANGER}`), { session: 'x' }));
  });
});
