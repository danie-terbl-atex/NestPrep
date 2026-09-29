import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { HOUSEHOLD, KID_DEVICE, PEOPLE } from './access_fixture';
import { CARER, CHILD, PATHS } from './nanny_fixture';
import { OTHER_CARER, givenAHubWithTwoCarers } from './nanny_v2_fixture';
import {
  asKid,
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
} from './rules_harness';

/**
 * Photo updates during a shift (nanny-hub ADR-0004): a carer sends the
 * parents a photo while the shift is open; it is born pending for
 * notifications to push; nobody changes one; the sender or family takes one
 * back.
 */

const OPEN_UPDATES = `${PATHS.openShift}/photoUpdates`;
const ENDED_UPDATES = `${PATHS.endedShift}/photoUpdates`;
const SENT = `${OPEN_UPDATES}/garden`;

function update(
  byMemberId: string,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    photoId: 'photo-garden-01',
    caption: 'Painting in the garden',
    childIds: [CHILD],
    byMemberId,
    createdAt: serverTimestamp(),
    delivery: { state: 'pending' },
    ...overrides,
  };
}

beforeEach(async () => {
  await clearData();
  await givenAHubWithTwoCarers();
  await givenData(async (db) => {
    await setDoc(doc(db, SENT), { ...update(CARER.member), createdAt: new Date() });
  });
});

describe('sending a photo update', () => {
  it('lets the carer send one, with or without a caption, while the shift is open', async () => {
    const db = await asUser(CARER.uid);
    await assertSucceeds(setDoc(doc(db, `${OPEN_UPDATES}/one`), update(CARER.member)));
    await assertSucceeds(
      setDoc(doc(db, `${OPEN_UPDATES}/two`), update(CARER.member, { caption: null, childIds: [] })),
    );
  });

  it('refuses a helper at view, and anybody the hub is closed to', async () => {
    for (const person of ['viewer', 'cleaner', 'kid'] as const) {
      const db = await asUser(PEOPLE[person].uid);
      await assertFails(setDoc(doc(db, `${OPEN_UPDATES}/x`), update(PEOPLE[person].member)));
    }
  });

  it('refuses one on a shift that has ended', async () => {
    const db = await asUser(CARER.uid);
    await assertFails(setDoc(doc(db, `${ENDED_UPDATES}/late`), update(CARER.member)));
  });

  it('refuses one with no photo, a long caption, delivery already decided, or more in it', async () => {
    const db = await asUser(CARER.uid);
    const path = doc(db, `${OPEN_UPDATES}/bad`);
    const by = CARER.member;
    await assertFails(setDoc(path, update(by, { photoId: null })));
    await assertFails(setDoc(path, update(by, { photoId: 'a/b' })));
    await assertFails(setDoc(path, update(by, { caption: 'x'.repeat(201) })));
    await assertFails(setDoc(path, update(by, { caption: '' })));
    await assertFails(setDoc(path, update(by, { delivery: { state: 'sent' } })));
    await assertFails(setDoc(path, update(by, { childIds: Array(11).fill(CHILD) })));
    await assertFails(setDoc(path, update(by, { location: 'garden' })));
    await assertFails(setDoc(path, update(OTHER_CARER.member)));
    await assertFails(setDoc(path, update(by, { createdAt: new Date() })));
  });

  it('never lets anybody change one — delivery is the Admin SDK’s', async () => {
    const carer = await asUser(CARER.uid);
    await assertFails(updateDoc(doc(carer, SENT), { caption: 'Changed' }));
    const admin = await asUser(PEOPLE.admin.uid);
    await assertFails(updateDoc(doc(admin, SENT), { delivery: { state: 'sent' } }));
  });
});

describe('taking one back', () => {
  it('refuses another carer', async () => {
    const db = await asUser(OTHER_CARER.uid);
    await assertFails(deleteDoc(doc(db, SENT)));
  });

  it('lets the sender take it back', async () => {
    const db = await asUser(CARER.uid);
    await assertSucceeds(deleteDoc(doc(db, SENT)));
  });

  it('lets family remove any', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    await assertSucceeds(deleteDoc(doc(db, SENT)));
  });
});

describe('the parents’ feed', () => {
  it('is read by family, the carer and a helper at view', async () => {
    for (const uid of [PEOPLE.admin.uid, PEOPLE.parent.uid, CARER.uid, PEOPLE.viewer.uid]) {
      const db = await asUser(uid);
      await assertSucceeds(getDocs(collection(db, OPEN_UPDATES)));
    }
  });

  it('is refused to the kid, the cleaner, the kid’s tablet, strangers and nobody', async () => {
    const tablet = await asKid(KID_DEVICE, { householdId: HOUSEHOLD, memberId: CHILD });
    for (const db of [
      await asUser(PEOPLE.kid.uid),
      await asUser(PEOPLE.cleaner.uid),
      tablet,
      await asUser('uid-stranger'),
      await asSignedOut(),
    ]) {
      await assertFails(getDoc(doc(db, SENT)));
    }
  });
});
