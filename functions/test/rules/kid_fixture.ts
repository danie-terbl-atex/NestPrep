import { doc, serverTimestamp, setDoc } from 'firebase/firestore';

import { asKid, givenData, type Firestore } from './rules_harness';

/**
 * One household with kid devices, for the two kid-device rules suites
 * (accounts ADR-0003, ADR-0004): Mia holds the kid defaults, Ava a grant a
 * parent changed, Ben no grant at all, and Old a profile that is not a kid.
 */
export const SAM = 'uid-sam';
export const THANDI = 'uid-thandi';
export const KID = 'kid_mia-tablet';
export const REVOKED_KID = 'kid_lost-phone';
export const HOME = 'households/h-kids';
export const MIA = 'm-mia';
export const LEO = 'm-leo';
export const DATE = '2026-09-29';
export const AVA = 'm-ava';
export const BEN = 'm-ben';
export const OLD = 'm-old';
export const miasTablet = (): Promise<Firestore> =>
  asKid(KID, { householdId: 'h-kids', memberId: MIA });
export const avasTablet = (): Promise<Firestore> =>
  asKid('kid_ava-tablet', { householdId: 'h-kids', memberId: AVA });
export const bensTablet = (): Promise<Firestore> =>
  asKid('kid_ben-tablet', { householdId: 'h-kids', memberId: BEN });
export const oldTablet = (): Promise<Firestore> =>
  asKid('kid_old-tablet', { householdId: 'h-kids', memberId: OLD });

/** Household ADR-0003's defaults for a kid. */
export const KID_DEFAULTS = {
  calendar: 'view',
  groceries: 'view',
  todos: 'own',
  meals: 'view',
  documents: 'none',
  lunch: 'own',
  familyProfiles: 'own',
  medical: 'none',
  homeCare: 'none',
  nannyHub: 'none',
};

export function task(
  title: string,
  assigneeIds: string[],
  routineId: string | null = null,
): object {
  return {
    title,
    note: null,
    dueDate: DATE,
    recurrence: null,
    assigneeIds,
    createdBy: 'm-sam',
    routineId,
    createdAt: new Date(),
  };
}

export function completion(taskId: string, by: string, forMember: string): object {
  return {
    taskId,
    occurrenceDate: DATE,
    completedBy: by,
    completedFor: forMember,
    completedAt: serverTimestamp(),
  };
}

export async function givenAKidsHousehold(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, HOME), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [THANDI]: 'helper' },
      kids: {
        [KID]: MIA,
        'kid_ava-tablet': AVA,
        'kid_ben-tablet': BEN,
        'kid_old-tablet': OLD,
      },
    });
    for (const [id, name, role, claimedBy, access] of [
      ['m-sam', 'Sam', 'admin', SAM, null],
      ['m-thandi', 'Thandi', 'helper', THANDI, null],
      [MIA, 'Mia', 'kid', null, KID_DEFAULTS],
      [LEO, 'Leo', 'kid', null, KID_DEFAULTS],
      [
        AVA,
        'Ava',
        'kid',
        null,
        { ...KID_DEFAULTS, todos: 'view', groceries: 'edit', meals: 'none' },
      ],
      [BEN, 'Ben', 'kid', null, null],
      // A profile that is no longer a kid: its grant stays on the document,
      // and its devices hold none of it (accounts ADR-0004).
      [OLD, 'Old', 'member', null, KID_DEFAULTS],
    ] as const) {
      await setDoc(doc(db, `${HOME}/members/${id}`), {
        displayName: name,
        color: 'violet',
        role,
        claimedBy,
        ...(access === null ? {} : { access }),
      });
    }
    await setDoc(doc(db, `${HOME}/tasks/dishes`), task('Dishes', [MIA]));
    await setDoc(doc(db, `${HOME}/tasks/feed-cat`), task('Feed the cat', [MIA], 'r-morning'));
    await setDoc(doc(db, `${HOME}/tasks/homework-leo`), task('Homework', [LEO]));
    await setDoc(doc(db, `${HOME}/tasks/bins`), task('Bins', []));
    await setDoc(doc(db, `${HOME}/tasks/ava-reading`), task('Reading', [AVA]));
    await setDoc(doc(db, `${HOME}/tasks/ben-bed`), task('Make the bed', [BEN]));
    await setDoc(doc(db, `${HOME}/tasks/old-lawn`), task('Lawn', [OLD]));
    await setDoc(doc(db, `${HOME}/routines/r-morning`), {
      name: 'Morning',
      firstDate: DATE,
      recurrence: null,
      defaultAssigneeIds: [MIA],
      color: 'mint',
      createdBy: 'm-sam',
      createdAt: new Date(),
    });
    await setDoc(doc(db, `${HOME}/taskCompletions/homework-leo_${DATE}`), {
      ...completion('homework-leo', LEO, LEO),
      completedAt: new Date(),
    });
    await setDoc(doc(db, `${HOME}/taskCompletions/feed-cat_${DATE}`), {
      ...completion('feed-cat', MIA, MIA),
      completedAt: new Date(),
    });
    await setDoc(doc(db, `${HOME}/meals/pasta`), {
      name: 'Pasta',
      nameKey: 'pasta',
      addedBy: 'm-sam',
      createdAt: new Date(),
    });
    await setDoc(doc(db, `${HOME}/mealPlans/2026-09-28`), { slots: { '2_lunch': 'pasta' } });
    await setDoc(doc(db, `${HOME}/groceryItems/milk`), { name: 'Milk' });
    await setDoc(doc(db, `${HOME}/events/dentist`), { title: 'Dentist' });
    await setDoc(doc(db, `${HOME}/documentFolders/school`), { name: 'School' });
    await setDoc(doc(db, `${HOME}/documents/passport`), { name: 'Passport' });
    await setDoc(doc(db, `${HOME}/memberLocations/m-sam`), { accuracyMetres: 5 });
    await setDoc(doc(db, `${HOME}/kidDevices/${KID}`), {
      memberId: MIA,
      label: 'Tablet',
      pairedBy: SAM,
      pairedAt: new Date(),
    });
    await setDoc(doc(db, 'kidPairings/ABC234'), { householdId: 'h-kids', memberId: LEO });
    await setDoc(doc(db, 'invites/ABCD2345'), { householdId: 'h-kids', memberId: LEO });
  });
}
