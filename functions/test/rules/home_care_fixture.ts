import { doc, setDoc } from 'firebase/firestore';

import { DATE, HOME, PEOPLE } from './access_fixture';
import { givenData, type Firestore } from './rules_harness';

/**
 * Home care's records on top of the household of every role
 * (`access_fixture.ts`): a room, a product, and three jobs — one for the
 * cleaner (who holds `homeCare: own`), one for the look-only helper, and one
 * for a profile nobody has claimed — each with the history event its
 * creation wrote (home-care ADR-0001).
 */
export const ROOM = `${HOME}/homeCareRooms/kitchen`;
export const PRODUCT = `${HOME}/homeCareProducts/jik`;

export const JOBS = {
  cleaners: `${HOME}/homeCareJobs/oven`,
  viewers: `${HOME}/homeCareJobs/windows`,
  nobodys: `${HOME}/homeCareJobs/garage`,
} as const;

export const STEPS = [
  { id: 's1', text: 'Open a window' },
  { id: 's2', text: 'Spray and leave for ten minutes' },
];

export function eventPath(job: string, revision: number): string {
  return `${job}/events/${String(revision)}`;
}

/** A job as `createJob` writes it, with anything overridden. */
export function jobData(
  helperId: string,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    title: 'Oven door',
    roomId: 'kitchen',
    helperId,
    dueDate: DATE,
    note: null,
    productIds: ['jik'],
    steps: STEPS,
    doneStepIds: [],
    beforePhoto: { photoId: 'before', width: 1600, height: 1200 },
    marks: [{ points: [0.1, 0.2, 0.3, 0.4] }],
    afterPhoto: null,
    status: 'assigned',
    reviewNote: null,
    revision: 0,
    createdBy: PEOPLE.admin.member,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

export async function givenHomeCareRecords(
  jobOverrides: Partial<Record<keyof typeof JOBS, Record<string, unknown>>> = {},
): Promise<void> {
  await givenData(async (db: Firestore) => {
    const at = new Date();
    await setDoc(doc(db, ROOM), {
      name: 'Kitchen',
      kind: 'kitchen',
      createdBy: PEOPLE.admin.member,
      createdAt: at,
    });
    await setDoc(doc(db, PRODUCT), {
      name: 'Jik',
      kind: 'bleach',
      whereKept: 'Under the sink',
      note: null,
      keepFromChildren: true,
      keepFromPets: true,
      createdBy: PEOPLE.admin.member,
      createdAt: at,
    });
    const helpers: Record<keyof typeof JOBS, string> = {
      cleaners: PEOPLE.cleaner.member,
      viewers: PEOPLE.viewer.member,
      nobodys: 'm-unclaimed',
    };
    for (const key of Object.keys(JOBS) as (keyof typeof JOBS)[]) {
      const data = jobData(helpers[key], jobOverrides[key]);
      await setDoc(doc(db, JOBS[key]), data);
      await setDoc(doc(db, eventPath(JOBS[key], 0)), {
        status: 'assigned',
        by: PEOPLE.admin.member,
        note: null,
        at,
      });
    }
  });
}
