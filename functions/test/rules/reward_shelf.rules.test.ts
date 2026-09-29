import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { AVA, HOME, LEO, MIA, SAM, THANDI, avasTablet, miasTablet } from './kid_fixture';
import { STARS, givenStars, request, reward } from './chore_points_fixture';
import { asUser, assertFails, assertSucceeds } from './rules_harness';

/**
 * The reward shelf and asking for a treat (todos ADR-0003): family writes the
 * shelf; a child asks for themselves with four fields and nothing more; the
 * status, the cost and a refusal are the trigger's alone.
 */

beforeEach(givenStars);

describe('the reward shelf', () => {
  it('every child with to-dos sees it; a stranger does not', async () => {
    await assertSucceeds(getDocs(collection(await miasTablet(), STARS.rewards)));
    await assertFails(getDocs(collection(await asUser('uid-stranger'), STARS.rewards)));
  });

  it('a parent adds, changes and removes a reward', async () => {
    const sam = await asUser(SAM);
    await assertSucceeds(setDoc(doc(sam, `${HOME}/rewards/movie`), reward()));
    await assertSucceeds(updateDoc(doc(sam, `${HOME}/rewards/ice-cream`), { cost: 15 }));
    await assertSucceeds(deleteDoc(doc(sam, `${HOME}/rewards/ice-cream`)));
  });

  it('refuses a reward that is free, too dear, unnamed or carries more', async () => {
    const sam = await asUser(SAM);
    for (const bad of [
      reward({ cost: 0 }),
      reward({ cost: 10001 }),
      reward({ cost: 2.5 }),
      reward({ title: '' }),
      reward({ title: 'x'.repeat(61) }),
      reward({ forMemberIds: [MIA] }),
    ]) {
      await assertFails(setDoc(doc(sam, `${HOME}/rewards/bad`), bad));
    }
  });

  it('a helper or a kid cannot write the shelf', async () => {
    const thandi = await asUser(THANDI);
    await assertFails(
      setDoc(doc(thandi, `${HOME}/rewards/movie`), reward({ createdBy: 'm-thandi' })),
    );
    await assertFails(deleteDoc(doc(thandi, `${HOME}/rewards/ice-cream`)));
    const mia = await miasTablet();
    await assertFails(setDoc(doc(mia, `${HOME}/rewards/movie`), reward({ createdBy: MIA })));
    await assertFails(updateDoc(doc(mia, `${HOME}/rewards/ice-cream`), { cost: 1 }));
  });
});

describe('asking for a reward', () => {
  it('a child asks for one for themselves', async () => {
    const mia = await miasTablet();
    await assertSucceeds(setDoc(doc(mia, `${HOME}/rewardRequests/new`), request()));
  });

  it('a child cannot ask for a sibling, or in a sibling’s name', async () => {
    const mia = await miasTablet();
    await assertFails(setDoc(doc(mia, `${HOME}/rewardRequests/new`), request({ memberId: LEO })));
    await assertFails(
      setDoc(doc(mia, `${HOME}/rewardRequests/new`), request({ requestedBy: LEO })),
    );
  });

  it('a child cannot write the status, the cost or a refusal', async () => {
    const mia = await miasTablet();
    for (const extra of [{ status: 'fulfilled' }, { cost: 0 }, { refusal: null }]) {
      await assertFails(setDoc(doc(mia, `${HOME}/rewardRequests/new`), request(extra)));
    }
    await assertFails(
      updateDoc(doc(mia, `${HOME}/rewardRequests/req_${MIA}`), { status: 'fulfilled' }),
    );
    await assertFails(deleteDoc(doc(mia, `${HOME}/rewardRequests/req_${MIA}`)));
  });

  it('refuses a reward that is not on the shelf', async () => {
    const mia = await miasTablet();
    await assertFails(
      setDoc(doc(mia, `${HOME}/rewardRequests/new`), request({ rewardId: 'a-pony' })),
    );
  });

  it('`view` only looks: it cannot ask', async () => {
    const ava = await avasTablet();
    await assertFails(
      setDoc(doc(ava, `${HOME}/rewardRequests/new`), request({ memberId: AVA, requestedBy: AVA })),
    );
  });

  it('a parent asks on a child’s behalf; a helper cannot', async () => {
    const sam = await asUser(SAM);
    await assertSucceeds(
      setDoc(doc(sam, `${HOME}/rewardRequests/new`), request({ requestedBy: 'm-sam' })),
    );
    const thandi = await asUser(THANDI);
    await assertFails(
      setDoc(doc(thandi, `${HOME}/rewardRequests/other`), request({ requestedBy: 'm-thandi' })),
    );
  });

  it('a child reads their own requests, newest first, and not a sibling’s', async () => {
    const mia = await miasTablet();
    await assertSucceeds(
      getDocs(
        query(
          collection(mia, STARS.requests),
          where('memberId', '==', MIA),
          orderBy('requestedAt', 'desc'),
          limit(10),
        ),
      ),
    );
    await assertFails(getDoc(doc(mia, `${HOME}/rewardRequests/req_${LEO}`)));
  });

  it('a parent reads what is waiting', async () => {
    const sam = await asUser(SAM);
    await assertSucceeds(
      getDocs(query(collection(sam, STARS.requests), where('status', '==', 'waiting'))),
    );
  });
});
