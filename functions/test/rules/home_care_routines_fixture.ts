import { doc, serverTimestamp, setDoc } from 'firebase/firestore';

import { DATE, HOME, PEOPLE } from './access_fixture';
import { weeklyOn } from '../recurrence_shape';
import { givenData, type Firestore } from './rules_harness';

/**
 * Room routines on top of the household of every role (home-care ADR-0004):
 * one for the cleaner (`homeCare: own`), one for the look-only helper, and
 * one for a profile nobody has claimed — with a tick for the cleaner's and
 * the unclaimed one's day.
 */
export const ROUTINES = {
  cleaners: `${HOME}/homeCareRoutines/kitchen-daily`,
  viewers: `${HOME}/homeCareRoutines/windows-weekly`,
  nobodys: `${HOME}/homeCareRoutines/garage-sweep`,
} as const;

const ITEMS = [
  { id: 'i1', text: 'Wipe the counters' },
  { id: 'i2', text: 'Sweep the floor' },
  { id: 'i3', text: 'Empty the bin' },
];

export function tickPath(routineId: string, date = DATE): string {
  return `${HOME}/homeCareRoutineTicks/${routineId}_${date}`;
}

/** A routine as the app writes one, with anything overridden. */
export function routineData(
  helperId: string,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    name: 'Kitchen, every weekday',
    roomId: 'kitchen',
    cadence: 'daily',
    items: ITEMS,
    helperId,
    firstDate: DATE,
    recurrence: weeklyOn([1, 2, 3, 4, 5]),
    createdBy: PEOPLE.admin.member,
    createdAt: new Date(),
    ...overrides,
  };
}

/** A day's tick as the app writes one — the server's time, unless overridden. */
export function tickData(
  routineId: string,
  helperId: string,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    routineId,
    occurrenceDate: DATE,
    helperId,
    doneItemIds: ['i1'],
    updatedBy: helperId,
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

export async function givenRoutines(): Promise<void> {
  await givenData(async (db: Firestore) => {
    const helpers: Record<keyof typeof ROUTINES, string> = {
      cleaners: PEOPLE.cleaner.member,
      viewers: PEOPLE.viewer.member,
      nobodys: 'm-unclaimed',
    };
    for (const key of Object.keys(ROUTINES) as (keyof typeof ROUTINES)[]) {
      await setDoc(doc(db, ROUTINES[key]), routineData(helpers[key]));
    }
    for (const [routineId, helperId] of [
      ['kitchen-daily', PEOPLE.cleaner.member],
      ['garage-sweep', 'm-unclaimed'],
    ] as const) {
      await setDoc(
        doc(db, tickPath(routineId)),
        tickData(routineId, helperId, { updatedBy: PEOPLE.admin.member, updatedAt: new Date() }),
      );
    }
  });
}
