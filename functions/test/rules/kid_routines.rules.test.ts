import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  AVA,
  DATE,
  HOME,
  LEO,
  MIA,
  SAM,
  THANDI,
  avasTablet,
  bensTablet,
  miasTablet,
} from './kid_fixture';
import {
  AWARDS,
  KID_ROUTINES,
  TICKS,
  givenKidRoutines,
  kidRoutine,
  kidTick,
  step,
  tickId,
} from './kid_routines_fixture';
import { asUser, assertFails, assertSucceeds } from './rules_harness';

/**
 * Kid routines by the `todos` grant (kid-routines ADR-0001). Sam is family;
 * Thandi a helper holding `edit`, who writes routines but never their stars;
 * Mia's tablet holds `own`, Ava's `view` and Ben's nothing. A child ticks
 * only its own day of a routine that names it, and nobody writes an award.
 */

beforeEach(givenKidRoutines);

const fresh = `${HOME}/kidRoutines/new`;
const steps = (count: number): unknown[] =>
  Array.from({ length: count }, (_, index) => step(`s${String(index)}`));

describe('reading routines', () => {
  it('lets family, an `edit` helper and a `view` tablet read every routine', async () => {
    for (const db of [await asUser(SAM), await asUser(THANDI), await avasTablet()]) {
      await assertSucceeds(getDoc(doc(db, KID_ROUTINES.leos)));
      await assertSucceeds(getDocs(collection(db, `${HOME}/kidRoutines`)));
    }
  });

  it('lets an `own` tablet ask for exactly the routines naming its child', async () => {
    const mia = await miasTablet();
    await assertSucceeds(getDoc(doc(mia, KID_ROUTINES.mias)));
    await assertSucceeds(
      getDocs(
        query(collection(mia, `${HOME}/kidRoutines`), where('kidIds', 'array-contains', MIA)),
      ),
    );
  });

  it('denies it a routine that does not name it, and the whole list', async () => {
    const mia = await miasTablet();
    await assertFails(getDoc(doc(mia, KID_ROUTINES.leos)));
    await assertFails(getDocs(collection(mia, `${HOME}/kidRoutines`)));
    await assertFails(
      getDocs(
        query(collection(mia, `${HOME}/kidRoutines`), where('kidIds', 'array-contains', LEO)),
      ),
    );
  });

  it('denies a tablet with no grant, and a stranger', async () => {
    await assertFails(getDoc(doc(await bensTablet(), KID_ROUTINES.mias)));
    await assertFails(getDoc(doc(await asUser('uid-stranger'), KID_ROUTINES.mias)));
  });
});

describe('writing routines', () => {
  it('lets family add, change — stars too — and remove a routine', async () => {
    const sam = await asUser(SAM);
    await assertSucceeds(setDoc(doc(sam, fresh), kidRoutine()));
    await assertSucceeds(
      updateDoc(doc(sam, fresh), { name: 'Up and out', points: 20, finishBy: null, kidIds: [LEO] }),
    );
    await assertSucceeds(deleteDoc(doc(sam, fresh)));
  });

  it('lets an `edit` helper add one worth nothing, and refuses her one with stars', async () => {
    const thandi = await asUser(THANDI);
    const mine = { createdBy: 'm-thandi' };
    await assertFails(setDoc(doc(thandi, fresh), kidRoutine(mine)));
    await assertSucceeds(setDoc(doc(thandi, fresh), kidRoutine({ ...mine, points: 0 })));
  });

  it('lets her change and remove a routine, but never what it is worth', async () => {
    const thandi = await asUser(THANDI);
    await assertFails(updateDoc(doc(thandi, KID_ROUTINES.thandis), { points: 5 }));
    await assertFails(updateDoc(doc(thandi, KID_ROUTINES.mias), { points: 0 }));
    await assertSucceeds(updateDoc(doc(thandi, KID_ROUTINES.mias), { name: 'Rise and shine' }));
    await assertSucceeds(deleteDoc(doc(thandi, KID_ROUTINES.thandis)));
  });

  it('denies `view`, `own` and no grant every write', async () => {
    for (const [db, by] of [
      [await avasTablet(), AVA],
      [await miasTablet(), MIA],
      [await bensTablet(), 'm-ben'],
    ] as const) {
      await assertFails(setDoc(doc(db, fresh), kidRoutine({ createdBy: by, points: 0 })));
      await assertFails(updateDoc(doc(db, KID_ROUTINES.mias), { name: 'Mine now' }));
      await assertFails(deleteDoc(doc(db, KID_ROUTINES.mias)));
    }
  });

  it('refuses a routine the shape does not allow', async () => {
    const sam = await asUser(SAM);
    for (const bad of [
      { slot: 'midnight' },
      { name: '' },
      { name: 'x'.repeat(41) },
      { kidIds: [] },
      { kidIds: Array.from({ length: 13 }, (_, index) => `m-${String(index)}`) },
      { steps: [] },
      { steps: steps(13) },
      { steps: 'brush' },
      { points: 21 },
      { points: -1 },
      { points: 2.5 },
      { finishBy: 1440 },
      { finishBy: -1 },
      { finishBy: '07:30' },
      { firstDate: '29/09/2026' },
      { recurrence: 'daily' },
      { colour: 'red' },
      { createdBy: 'm-thandi' },
      { createdAt: new Date(0) },
    ]) {
      await assertFails(setDoc(doc(sam, fresh), kidRoutine(bad)));
    }
    await assertSucceeds(
      setDoc(doc(sam, fresh), kidRoutine({ steps: steps(12), finishBy: 1439, points: 20 })),
    );
  });

  it('refuses one written without its stars or its finish time', async () => {
    const sam = await asUser(SAM);
    for (const missing of ['points', 'finishBy']) {
      const routine = Object.fromEntries(
        Object.entries(kidRoutine()).filter(([key]) => key !== missing),
      );
      await assertFails(setDoc(doc(sam, fresh), routine));
    }
  });

  it('holds a change to the same shape, and never rewrites who made it', async () => {
    const sam = await asUser(SAM);
    await assertFails(updateDoc(doc(sam, KID_ROUTINES.mias), { points: 21 }));
    await assertFails(updateDoc(doc(sam, KID_ROUTINES.mias), { steps: [] }));
    await assertFails(updateDoc(doc(sam, KID_ROUTINES.mias), { finishBy: '07:30' }));
    await assertFails(updateDoc(doc(sam, KID_ROUTINES.mias), { createdBy: 'm-thandi' }));
    await assertFails(updateDoc(doc(sam, KID_ROUTINES.mias), { colour: 'red' }));
  });
});

describe('ticking a day', () => {
  const path = (routineId: string, kidId: string): string =>
    `${HOME}/kidRoutineTicks/${tickId(routineId, kidId)}`;

  it('lets a child tick and untick its own day', async () => {
    const mia = await miasTablet();
    const mine = doc(mia, path('morning', MIA));
    await assertSucceeds(setDoc(mine, kidTick('morning', MIA, { doneStepIds: ['s1', 's2'] })));
    await assertSucceeds(setDoc(mine, kidTick('morning', MIA, { doneStepIds: [] })));
  });

  it('lets a `view` tablet tick its own day too, and only its own', async () => {
    const ava = await avasTablet();
    await assertSucceeds(setDoc(doc(ava, path('morning', AVA)), kidTick('morning', AVA)));
    await assertFails(
      setDoc(doc(ava, path('morning', MIA)), kidTick('morning', MIA, { updatedBy: AVA })),
    );
  });

  it('denies a child another child’s day, in its own name or theirs', async () => {
    const mia = await miasTablet();
    await assertFails(
      setDoc(doc(mia, path('morning', AVA)), kidTick('morning', AVA, { updatedBy: MIA })),
    );
    await assertFails(setDoc(doc(mia, path('morning', AVA)), kidTick('morning', AVA)));
    await assertFails(
      setDoc(doc(mia, path('bedtime', LEO)), kidTick('bedtime', LEO, { updatedBy: MIA })),
    );
  });

  it('refuses a child the routine does not name', async () => {
    await assertFails(
      setDoc(doc(await miasTablet(), path('bedtime', MIA)), kidTick('bedtime', MIA)),
    );
    await assertFails(
      setDoc(
        doc(await asUser(SAM), path('bedtime', MIA)),
        kidTick('bedtime', MIA, { updatedBy: 'm-sam' }),
      ),
    );
  });

  it('refuses a tick whose id is not its routine, its child and its day', async () => {
    const mia = await miasTablet();
    for (const id of [`morning_${MIA}_2026-01-01`, `morning_${DATE}`, `bedtime_${MIA}_${DATE}`]) {
      await assertFails(setDoc(doc(mia, `${TICKS}/${id}`), kidTick('morning', MIA)));
    }
    await assertFails(
      setDoc(
        doc(mia, `${TICKS}/morning_${MIA}_tomorrow`),
        kidTick('morning', MIA, { occurrenceDate: 'tomorrow' }),
      ),
    );
  });

  it('refuses more steps done than the routine has, or a list that is not one', async () => {
    const mia = await miasTablet();
    const mine = doc(mia, path('morning', MIA));
    await assertFails(setDoc(mine, kidTick('morning', MIA, { doneStepIds: ['s1', 's2', 's3'] })));
    await assertFails(setDoc(mine, kidTick('morning', MIA, { doneStepIds: 's1' })));
  });

  it('refuses a client’s clock, an extra key and a routine that does not exist', async () => {
    const mia = await miasTablet();
    const mine = doc(mia, path('morning', MIA));
    await assertFails(setDoc(mine, kidTick('morning', MIA, { updatedAt: new Date(0) })));
    await assertFails(setDoc(mine, kidTick('morning', MIA, { points: 20 })));
    await assertFails(setDoc(doc(mia, path('gone', MIA)), kidTick('gone', MIA)));
  });

  it('lets family tick for any child the routine names, in their own name', async () => {
    const sam = await asUser(SAM);
    for (const [routineId, kidId] of [
      ['morning', AVA],
      ['bedtime', LEO],
    ] as const) {
      await assertSucceeds(
        setDoc(doc(sam, path(routineId, kidId)), kidTick(routineId, kidId, { updatedBy: 'm-sam' })),
      );
    }
    await assertFails(setDoc(doc(sam, path('morning', MIA)), kidTick('morning', MIA)));
  });

  it('denies a helper who is not family, and a tablet with no grant', async () => {
    await assertFails(
      setDoc(
        doc(await asUser(THANDI), path('morning', MIA)),
        kidTick('morning', MIA, { updatedBy: 'm-thandi' }),
      ),
    );
    await assertFails(
      setDoc(doc(await bensTablet(), path('morning', MIA)), kidTick('morning', MIA)),
    );
  });

  it('a child reads its own ticks, and not a sibling’s', async () => {
    const mia = await miasTablet();
    await assertSucceeds(getDoc(doc(mia, path('morning', MIA))));
    await assertSucceeds(
      getDocs(
        query(
          collection(mia, TICKS),
          where('kidId', '==', MIA),
          where('occurrenceDate', '>=', DATE),
        ),
      ),
    );
    await assertFails(getDoc(doc(mia, path('bedtime', LEO))));
    await assertFails(getDocs(collection(mia, TICKS)));
    await assertSucceeds(getDocs(collection(await avasTablet(), TICKS)));
    await assertFails(getDoc(doc(await bensTablet(), path('morning', MIA))));
  });

  it('lets only family remove a tick', async () => {
    await assertFails(deleteDoc(doc(await miasTablet(), path('morning', MIA))));
    await assertFails(deleteDoc(doc(await asUser(THANDI), path('morning', MIA))));
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), path('morning', MIA))));
  });
});

describe('the stars a finished routine gave', () => {
  const awardOf = (routineId: string, kidId: string): string =>
    `${HOME}/kidRoutineAwards/${tickId(routineId, kidId)}`;
  const award = (kidId: string): Record<string, unknown> => ({
    memberId: kidId,
    routineId: 'morning',
    occurrenceDate: DATE,
    title: 'Morning',
    points: 20,
    status: 'awarded',
    round: 1,
    awardedAt: serverTimestamp(),
    settledAt: null,
  });

  it('a child reads its own award, and not a sibling’s', async () => {
    const mia = await miasTablet();
    await assertSucceeds(getDoc(doc(mia, awardOf('morning', MIA))));
    await assertSucceeds(getDocs(query(collection(mia, AWARDS), where('memberId', '==', MIA))));
    await assertFails(getDoc(doc(mia, awardOf('bedtime', LEO))));
    await assertFails(getDocs(collection(mia, AWARDS)));
  });

  it('`view` and family read everybody’s; no grant reads none', async () => {
    await assertSucceeds(getDocs(collection(await avasTablet(), AWARDS)));
    await assertSucceeds(getDocs(collection(await asUser(SAM), AWARDS)));
    await assertFails(getDoc(doc(await bensTablet(), awardOf('morning', MIA))));
  });

  it('nobody writes one — not the child, not a helper, not a parent', async () => {
    for (const db of [await miasTablet(), await asUser(THANDI), await asUser(SAM)]) {
      await assertFails(setDoc(doc(db, awardOf('morning', AVA)), award(AVA)));
      await assertFails(updateDoc(doc(db, awardOf('morning', MIA)), { status: 'withdrawn' }));
      await assertFails(deleteDoc(doc(db, awardOf('morning', MIA))));
    }
  });
});
