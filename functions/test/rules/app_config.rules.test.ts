import { collection, doc, getDoc, getDocs, setDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { SAM, givenTheParkers } from './family_fixture';
import { kidsTablet } from './lunch_box_fixture';
import {
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
} from './rules_harness';

/**
 * The V2 switches (foundation ADR-0014): one document anybody may read —
 * a kid's tablet included, so its lunch picks can be switched off — and no
 * client may write. Any other id in the collection is closed.
 */

beforeEach(async () => {
  await clearData();
  await givenTheParkers();
  await givenData(async (db) => {
    await setDoc(doc(db, 'appConfig/flags'), { lunchKidPicks: true });
  });
});

describe('appConfig/{configId}', () => {
  it('the switches are read by anybody, signed in or not', async () => {
    for (const db of [await asUser(SAM), await kidsTablet(), await asSignedOut()]) {
      await assertSucceeds(getDoc(doc(db, 'appConfig/flags')));
    }
  });

  it('no client writes them, lists the collection or reads another id', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(sam, 'appConfig/flags'), { lunchKidPicks: false }));
    await assertFails(getDocs(collection(sam, 'appConfig')));
    await assertFails(getDoc(doc(sam, 'appConfig/secrets')));
  });
});
