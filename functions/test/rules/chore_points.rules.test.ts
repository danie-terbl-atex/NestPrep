import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  BEN,
  DATE,
  HOME,
  LEO,
  MIA,
  SAM,
  THANDI,
  avasTablet,
  bensTablet,
  completion,
  miasTablet,
} from './kid_fixture';
import { STARS, givenStars, starredChore } from './chore_points_fixture';
import { asUser, assertFails, assertSucceeds, givenData } from './rules_harness';

/**
 * A child's stars (todos ADR-0003): only Functions write them, the `todos`
 * grant reads them, and only family puts stars on a chore or a reward on the
 * shelf. Every denied case here is a way a kid device — or a helper — could
 * otherwise mint stars.
 */

beforeEach(givenStars);

describe('stars on a chore', () => {
  it('a parent puts stars on a chore that names its child', async () => {
    const sam = await asUser(SAM);
    await assertSucceeds(setDoc(doc(sam, `${HOME}/tasks/new`), starredChore()));
  });

  it('a starred chore must name who earns it — "anyone" is refused', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(sam, `${HOME}/tasks/new`), starredChore({ assigneeIds: [] })));
    // An unstarred anyone-chore is still fine.
    await assertSucceeds(
      setDoc(
        doc(sam, `${HOME}/tasks/new`),
        starredChore({ assigneeIds: [], points: 0, needsApproval: false }),
      ),
    );
  });

  it('refuses stars that are not a whole number from 0 to 100', async () => {
    const sam = await asUser(SAM);
    for (const points of [101, -1, 2.5, '5']) {
      await assertFails(setDoc(doc(sam, `${HOME}/tasks/new`), starredChore({ points })));
    }
    await assertFails(
      setDoc(doc(sam, `${HOME}/tasks/new`), starredChore({ needsApproval: 'yes' })),
    );
  });

  it('a helper with `edit` makes chores but cannot give them stars', async () => {
    const thandi = await asUser(THANDI);
    const mine = { createdBy: 'm-thandi' };
    await assertFails(setDoc(doc(thandi, `${HOME}/tasks/new`), starredChore(mine)));
    await assertFails(
      setDoc(
        doc(thandi, `${HOME}/tasks/new`),
        starredChore({ ...mine, points: 0, needsApproval: true }),
      ),
    );
    await assertSucceeds(
      setDoc(
        doc(thandi, `${HOME}/tasks/new`),
        starredChore({ ...mine, points: 0, needsApproval: false }),
      ),
    );
  });

  it('a helper cannot add stars to her own chore, but may still retitle it', async () => {
    const thandi = await asUser(THANDI);
    await assertFails(updateDoc(doc(thandi, `${HOME}/tasks/thandi-chore`), { points: 10 }));
    await assertSucceeds(
      updateDoc(doc(thandi, `${HOME}/tasks/thandi-chore`), { title: 'Fold the washing' }),
    );
  });

  it('a parent changes what a chore is worth; not to more than 100', async () => {
    const sam = await asUser(SAM);
    await assertSucceeds(
      updateDoc(doc(sam, `${HOME}/tasks/starred`), { points: 20, needsApproval: false }),
    );
    await assertFails(updateDoc(doc(sam, `${HOME}/tasks/starred`), { points: 500 }));
    await assertFails(updateDoc(doc(sam, `${HOME}/tasks/starred`), { assigneeIds: [] }));
  });

  it('a kid device cannot write a chore, starred or not', async () => {
    const mia = await miasTablet();
    await assertFails(
      setDoc(doc(mia, `${HOME}/tasks/new`), starredChore({ createdBy: MIA, points: 100 })),
    );
    await assertFails(updateDoc(doc(mia, `${HOME}/tasks/starred`), { points: 100 }));
  });

  it('a completion carries no stars of its own — the trigger reads the chore', async () => {
    const mia = await miasTablet();
    await assertFails(
      setDoc(doc(mia, `${HOME}/taskCompletions/starred_${DATE}`), {
        ...completion('starred', MIA, MIA),
        points: 100,
      }),
    );
    await assertSucceeds(
      setDoc(doc(mia, `${HOME}/taskCompletions/starred_${DATE}`), completion('starred', MIA, MIA)),
    );
  });
});

describe('the balance, the ledger and the claims', () => {
  it('a child reads their own, and not a sibling’s', async () => {
    const mia = await miasTablet();
    await assertSucceeds(getDoc(doc(mia, `${HOME}/pointBalances/${MIA}`)));
    await assertFails(getDoc(doc(mia, `${HOME}/pointBalances/${LEO}`)));
    await assertSucceeds(
      getDocs(
        query(
          collection(mia, STARS.claims),
          where('memberId', '==', MIA),
          where('occurrenceDate', '>=', '2026-09-22'),
        ),
      ),
    );
    await assertSucceeds(
      getDocs(
        query(
          collection(mia, STARS.entries),
          where('memberId', '==', MIA),
          orderBy('at', 'desc'),
          limit(20),
        ),
      ),
    );
    await assertFails(getDocs(collection(mia, STARS.claims)));
    await assertFails(getDocs(query(collection(mia, STARS.entries), where('memberId', '==', LEO))));
  });

  it('a balance nobody has yet is readable by its child — there is nothing to read', async () => {
    const mia = await miasTablet();
    await givenData(async (db) => {
      await deleteDoc(doc(db, `${HOME}/pointBalances/${MIA}`));
    });
    await assertSucceeds(getDoc(doc(mia, `${HOME}/pointBalances/${MIA}`)));
  });

  it('`view` on to-dos sees every child’s; no grant sees none', async () => {
    const ava = await avasTablet();
    await assertSucceeds(getDoc(doc(ava, `${HOME}/pointBalances/${LEO}`)));
    await assertSucceeds(getDocs(collection(ava, STARS.claims)));
    const ben = await bensTablet();
    await assertFails(getDoc(doc(ben, `${HOME}/pointBalances/${BEN}`)));
    await assertFails(getDocs(collection(ben, STARS.rewards)));
  });

  it('a parent sees everybody’s', async () => {
    const sam = await asUser(SAM);
    await assertSucceeds(getDocs(collection(sam, STARS.balances)));
    await assertSucceeds(
      getDocs(query(collection(sam, STARS.claims), where('status', '==', 'pending'))),
    );
  });

  it('a kid device cannot write its balance, a ledger line or a claim', async () => {
    const mia = await miasTablet();
    await assertFails(
      setDoc(doc(mia, `${HOME}/pointBalances/${MIA}`), { memberId: MIA, balance: 9999 }),
    );
    await assertFails(updateDoc(doc(mia, `${HOME}/pointBalances/${MIA}`), { balance: 9999 }));
    await assertFails(
      setDoc(doc(mia, `${HOME}/pointEntries/free`), {
        memberId: MIA,
        delta: 9999,
        kind: 'chore',
        sourceId: 'x',
        title: 'Free stars',
        at: serverTimestamp(),
      }),
    );
    await assertFails(deleteDoc(doc(mia, `${HOME}/pointEntries/chore_${MIA}`)));
  });

  it('a kid device cannot approve its own chore', async () => {
    const mia = await miasTablet();
    await assertFails(
      updateDoc(doc(mia, `${HOME}/pointClaims/claim_${MIA}`), { status: 'awarded' }),
    );
    await assertFails(
      setDoc(doc(mia, `${HOME}/pointClaims/new`), {
        memberId: MIA,
        taskId: 'dishes',
        occurrenceDate: DATE,
        title: 'Dishes',
        points: 50,
        status: 'awarded',
        round: 1,
      }),
    );
  });

  it('not even a parent writes stars by hand — only the Functions do', async () => {
    const sam = await asUser(SAM);
    await assertFails(updateDoc(doc(sam, `${HOME}/pointBalances/${MIA}`), { balance: 100 }));
    await assertFails(
      updateDoc(doc(sam, `${HOME}/pointClaims/claim_${MIA}`), { status: 'awarded' }),
    );
    await assertFails(deleteDoc(doc(sam, `${HOME}/pointEntries/chore_${MIA}`)));
  });
});
