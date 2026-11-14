import { doc, serverTimestamp, setDoc } from 'firebase/firestore';

import { everyDay } from '../recurrence_shape';
import { AVA, DATE, HOME, LEO, MIA, givenAKidsHousehold } from './kid_fixture';
import { clearData, givenData, type Firestore } from './rules_harness';

/**
 * Kid routines on top of the kid household (kid-routines ADR-0001): a morning
 * for Mia and Ava that Sam made, a bedtime for Leo, one Thandi made worth
 * nothing — with a tick and an award for Mia's and for Leo's day.
 */
export const KID_ROUTINES = {
  mias: `${HOME}/kidRoutines/morning`,
  leos: `${HOME}/kidRoutines/bedtime`,
  thandis: `${HOME}/kidRoutines/after-school`,
} as const;

export const TICKS = `${HOME}/kidRoutineTicks`;
export const AWARDS = `${HOME}/kidRoutineAwards`;

export function step(id: string): Record<string, unknown> {
  return {
    id,
    title: 'Brush your teeth',
    picture: 'toothbrush',
    parts: [{ id: `${id}-p1`, text: 'Top and bottom', weekdays: [] }],
  };
}

/** A routine as the app writes one, with anything overridden. */
export function kidRoutine(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    name: 'Morning',
    slot: 'morning',
    kidIds: [MIA, AVA],
    firstDate: DATE,
    recurrence: everyDay(),
    finishBy: 450,
    points: 3,
    steps: [step('s1'), step('s2')],
    createdBy: 'm-sam',
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

export function tickId(routineId: string, kidId: string, date = DATE): string {
  return `${routineId}_${kidId}_${date}`;
}

/** A child's day as the app writes one — the server's time, unless overridden. */
export function kidTick(
  routineId: string,
  kidId: string,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    routineId,
    kidId,
    occurrenceDate: DATE,
    doneStepIds: ['s1'],
    updatedBy: kidId,
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

export async function givenKidRoutines(): Promise<void> {
  await clearData();
  await givenAKidsHousehold();
  await givenData(async (db: Firestore) => {
    const at = { createdAt: new Date() };
    await setDoc(doc(db, KID_ROUTINES.mias), kidRoutine(at));
    await setDoc(
      doc(db, KID_ROUTINES.leos),
      kidRoutine({ ...at, name: 'Bedtime', slot: 'bedtime', kidIds: [LEO], finishBy: null }),
    );
    await setDoc(
      doc(db, KID_ROUTINES.thandis),
      kidRoutine({
        ...at,
        name: 'After school',
        slot: 'afternoon',
        points: 0,
        createdBy: 'm-thandi',
      }),
    );
    for (const [routineId, kidId] of [
      ['morning', MIA],
      ['bedtime', LEO],
    ] as const) {
      await setDoc(
        doc(db, `${TICKS}/${tickId(routineId, kidId)}`),
        kidTick(routineId, kidId, { updatedAt: new Date() }),
      );
      await setDoc(doc(db, `${AWARDS}/${tickId(routineId, kidId)}`), {
        memberId: kidId,
        routineId,
        occurrenceDate: DATE,
        title: 'Morning',
        points: 3,
        status: 'awarded',
        round: 1,
        awardedAt: new Date(),
        settledAt: null,
      });
    }
  });
}
