import {
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import {
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  rulesEnvironment,
  type Firestore,
} from './rules_harness';

/**
 * The beta numbers' four collections (product-analytics ADR-0001).
 *
 * The ledgers say which members of which household opened the app in which
 * week, so nobody reads them — not a stranger, and not the household itself:
 * the numbers are about the product, never a view of one family. Only the
 * weekly totals, which are counts with no identifier in them, can be read, and
 * only by an account holding the reader claim. Nothing is written by a client,
 * ever: a number a client can write is a number anybody can move (`BE-20`).
 */

const SAM = 'uid-sam';
const DANIEL = 'uid-daniel';
const HOUSEHOLD = 'h1';
const WEEK = '2026-W40';

const LEDGERS = {
  analyticsHouseholdWeeks: `analyticsHouseholdWeeks/${WEEK}_${HOUSEHOLD}`,
  analyticsHouseholds: `analyticsHouseholds/${HOUSEHOLD}`,
  analyticsConversions: 'analyticsConversions/c1',
} as const;
const TOTALS = `analyticsWeeks/${WEEK}`;

async function asReader(uid = DANIEL): Promise<Firestore> {
  const context = (await rulesEnvironment()).authenticatedContext(uid, { analyticsReader: true });
  return context.firestore() as unknown as Firestore;
}

async function asClaimed(claim: unknown): Promise<Firestore> {
  const context = (await rulesEnvironment()).authenticatedContext(DANIEL, {
    analyticsReader: claim,
  });
  return context.firestore() as unknown as Firestore;
}

async function givenTheNumbers(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `households/${HOUSEHOLD}`), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin' },
    });
    await setDoc(doc(db, LEDGERS.analyticsHouseholdWeeks), {
      householdId: HOUSEHOLD,
      week: WEEK,
      activeMemberIds: ['m-sam'],
    });
    await setDoc(doc(db, LEDGERS.analyticsHouseholds), {
      householdId: HOUSEHOLD,
      cohortWeek: WEEK,
      createdAt: new Date(),
      firstAdultInviteAt: null,
    });
    await setDoc(doc(db, LEDGERS.analyticsConversions), {
      householdId: HOUSEHOLD,
      week: WEEK,
      trigger: 'direct',
    });
    await setDoc(doc(db, TOTALS), { week: WEEK, weekStart: '2026-09-28', activeFamilies: 1 });
  });
}

describe('the weekly totals', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheNumbers();
  });

  it('can be read by an account holding the reader claim', async () => {
    const reader = await asReader();
    await assertSucceeds(getDoc(doc(reader, TOTALS)));
    await assertSucceeds(getDocs(collection(reader, 'analyticsWeeks')));
  });

  it('can be listed newest first, the way the Beta numbers screen asks', async () => {
    // The exact query `FirestoreBetaNumbersRepository` runs. Ordering by the
    // document id instead is refused — Firestore will not scan ids descending —
    // and only a real query against the emulator shows that.
    const reader = await asReader();
    const newestFirst = await assertSucceeds(
      getDocs(query(collection(reader, 'analyticsWeeks'), orderBy('week', 'desc'), limit(13))),
    );
    expect(newestFirst.docs.map((week) => week.id)).toEqual([WEEK]);
  });

  it('cannot be read by a household admin without the claim', async () => {
    await assertFails(getDoc(doc(await asUser(SAM), TOTALS)));
  });

  it('cannot be read with the claim set to anything but true', async () => {
    await assertFails(getDoc(doc(await asClaimed('true'), TOTALS)));
    await assertFails(getDoc(doc(await asClaimed(false), TOTALS)));
  });

  it('cannot be read signed out', async () => {
    await assertFails(getDoc(doc(await asSignedOut(), TOTALS)));
  });

  it('cannot be written, even by a reader', async () => {
    const reader = await asReader();
    await assertFails(setDoc(doc(reader, TOTALS), { week: WEEK, activeFamilies: 50 }));
    await assertFails(updateDoc(doc(reader, TOTALS), { activeFamilies: 50 }));
    await assertFails(setDoc(doc(reader, 'analyticsWeeks/2026-W41'), { week: '2026-W41' }));
  });
});

describe('the per-household ledgers', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheNumbers();
  });

  for (const [name, path] of Object.entries(LEDGERS)) {
    it(`${name} cannot be read by the reader, who sees counts and never households`, async () => {
      await assertFails(getDoc(doc(await asReader(), path)));
      await assertFails(getDocs(collection(await asReader(), name)));
    });

    it(`${name} cannot be read by the household the entry is about`, async () => {
      await assertFails(getDoc(doc(await asUser(SAM), path)));
    });

    it(`${name} cannot be written by anybody, so a member cannot make themselves active`, async () => {
      await assertFails(setDoc(doc(await asUser(SAM), path), { householdId: HOUSEHOLD }));
      await assertFails(setDoc(doc(await asReader(), path), { householdId: HOUSEHOLD }));
      await assertFails(setDoc(doc(await asSignedOut(), path), { householdId: HOUSEHOLD }));
    });
  }

  it('a member cannot add themselves to a week that has no entry yet', async () => {
    await assertFails(
      setDoc(doc(await asUser(SAM), `analyticsHouseholdWeeks/2026-W41_${HOUSEHOLD}`), {
        householdId: HOUSEHOLD,
        week: '2026-W41',
        activeMemberIds: ['m-sam', 'm-invented'],
      }),
    );
  });

  it('while the household itself is still readable to its member, so the denial is the rule', async () => {
    // Without this, every denial above could be the fixture being wrong.
    await assertSucceeds(getDoc(doc(await asUser(SAM), `households/${HOUSEHOLD}`)));
  });
});
