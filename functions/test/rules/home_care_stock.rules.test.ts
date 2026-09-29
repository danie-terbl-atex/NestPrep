import { doc, serverTimestamp, updateDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { KID_DEVICE, PEOPLE, givenAHouseholdOfEveryRole, type Person } from './access_fixture';
import { PRODUCT, givenHomeCareRecords } from './home_care_fixture';
import {
  asKid,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  type Firestore,
} from './rules_harness';

/**
 * A product's stock level (home-care ADR-0005): anybody who sees home care
 * marks it, in their own name at the server's time, and changes nothing
 * else of the product.
 */

const as = (person: Person): Promise<Firestore> => asUser(PEOPLE[person].uid);

function mark(level: string, by: string): Record<string, unknown> {
  return { stock: level, stockChangedBy: by, stockChangedAt: serverTimestamp() };
}

beforeEach(async () => {
  await clearData();
  await givenAHouseholdOfEveryRole();
  await givenHomeCareRecords();
});

describe('marking a product’s stock', () => {
  it('lets every level of home care mark it, each in their own name', async () => {
    for (const person of ['admin', 'cleaner', 'viewer', 'legacyHelper'] as Person[]) {
      const db = await as(person);
      await assertSucceeds(updateDoc(doc(db, PRODUCT), mark('low', PEOPLE[person].member)));
      await assertSucceeds(updateDoc(doc(db, PRODUCT), mark('full', PEOPLE[person].member)));
    }
  });

  it('refuses a level that is not one of the four', async () => {
    const db = await as('cleaner');
    await assertFails(updateDoc(doc(db, PRODUCT), mark('nearly', PEOPLE.cleaner.member)));
  });

  it('refuses a mark in somebody else’s name, or at the client’s time', async () => {
    const db = await as('cleaner');
    await assertFails(updateDoc(doc(db, PRODUCT), mark('low', PEOPLE.admin.member)));
    await assertFails(
      updateDoc(doc(db, PRODUCT), {
        stock: 'low',
        stockChangedBy: PEOPLE.cleaner.member,
        stockChangedAt: new Date(0),
      }),
    );
  });

  it('refuses a helper changing anything else while she marks it', async () => {
    const db = await as('cleaner');
    await assertFails(
      updateDoc(doc(db, PRODUCT), { ...mark('low', PEOPLE.cleaner.member), name: 'Mine' }),
    );
    await assertFails(updateDoc(doc(db, PRODUCT), { kind: 'allPurpose' }));
  });

  it('denies the carer, the kid and the tablet', async () => {
    await assertFails(updateDoc(doc(await as('carer'), PRODUCT), mark('low', 'm-nomsa')));
    await assertFails(updateDoc(doc(await as('kid'), PRODUCT), mark('low', 'm-kid')));
    const tablet = await asKid(KID_DEVICE, {
      householdId: 'h-access',
      memberId: PEOPLE.kid.member,
    });
    await assertFails(updateDoc(doc(tablet, PRODUCT), mark('low', PEOPLE.kid.member)));
  });
});
