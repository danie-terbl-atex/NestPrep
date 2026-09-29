import { doc, setDoc } from 'firebase/firestore';

import { ROLE_DEFAULTS, uniformGrant, type Grant } from '../../src/household/access';
import { givenData, type Firestore } from './rules_harness';

/**
 * One household holding every role household ADR-0003 names, each with the
 * grant a real household would record, and one record of every kind the rules
 * guard — so a test can ask "may this role read that" for every pair.
 *
 * The grants are built from `ROLE_DEFAULTS` rather than typed out, so a
 * change to a default is a change to what these tests assert.
 */
export const HOUSEHOLD = 'h-access';
export const HOME = `households/${HOUSEHOLD}`;
export const DATE = '2026-09-29';

export const PEOPLE = {
  admin: { uid: 'uid-sam', member: 'm-sam', role: 'admin' },
  parent: { uid: 'uid-pat', member: 'm-pat', role: 'parent' },
  legacyMember: { uid: 'uid-lee', member: 'm-lee', role: 'member' },
  kid: { uid: 'uid-kid', member: 'm-kid', role: 'kid' },
  carer: { uid: 'uid-nomsa', member: 'm-nomsa', role: 'carer' },
  cleaner: { uid: 'uid-thandi', member: 'm-thandi', role: 'helper' },
  viewer: { uid: 'uid-vera', member: 'm-vera', role: 'helper' },
  legacyHelper: { uid: 'uid-old', member: 'm-old', role: 'helper' },
} as const;

export type Person = keyof typeof PEOPLE;

/**
 * A kid device bound to the kid's profile (accounts ADR-0004). It is not in the
 * uid→role map; it holds whatever grant that profile holds.
 */
export const KID_DEVICE = 'kid_the-kids-tablet';

/** Cleaning jobs and nothing else — the phase's own example. */
export const CLEANING_ONLY: Grant = { ...uniformGrant('none'), homeCare: 'own' };

/** Read everything, change nothing. */
export const LOOK_ONLY: Grant = uniformGrant('view');

/** Who holds which grant. The legacy helper holds none, on purpose. */
export const GRANTS: Partial<Record<Person, Grant>> = {
  kid: ROLE_DEFAULTS.kid,
  carer: ROLE_DEFAULTS.carer,
  cleaner: CLEANING_ONLY,
  viewer: LOOK_ONLY,
};

/** One of every record the rules guard, keyed by the area that guards it. */
export const RECORDS = {
  groceries: [`${HOME}/groceryItems/milk`],
  calendar: [`${HOME}/events/swim`, `${HOME}/eventExceptions/swim_${DATE}`],
  todos: [`${HOME}/tasks/bins`, `${HOME}/routines/sunday`, `${HOME}/taskCompletions/bins_${DATE}`],
  meals: [`${HOME}/meals/curry`, `${HOME}/mealPlans/2026-09-28`],
  documents: [`${HOME}/documentFolders/school`, `${HOME}/documents/passport`],
} as const;

export type GuardedArea = keyof typeof RECORDS;

export async function givenAHouseholdOfEveryRole(): Promise<void> {
  await givenData(async (db: Firestore) => {
    const members: Record<string, string> = {};
    const profiles: Record<string, string> = {};
    const access: Record<string, Grant> = {};
    for (const [key, person] of Object.entries(PEOPLE) as [Person, (typeof PEOPLE)[Person]][]) {
      members[person.uid] = person.role;
      // An account claimed before ADR-0003 has no profile entry and no grant.
      if (key === 'legacyHelper' || key === 'legacyMember') continue;
      profiles[person.uid] = person.member;
      const grant = GRANTS[key];
      if (grant !== undefined) access[person.uid] = grant;
    }
    await setDoc(doc(db, HOME), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members,
      profiles,
      access,
      kids: { [KID_DEVICE]: PEOPLE.kid.member },
      pendingSetupStep: 'invitePeople',
    });
    // The profile holds the parent's choice, as the Functions write it.
    for (const [key, person] of Object.entries(PEOPLE) as [Person, (typeof PEOPLE)[Person]][]) {
      const grant = GRANTS[key];
      await setDoc(doc(db, `${HOME}/members/${person.member}`), {
        displayName: person.member,
        color: 'violet',
        role: person.role,
        claimedBy: person.uid,
        ...(grant === undefined ? {} : { access: grant }),
      });
    }
    await setDoc(doc(db, `${HOME}/members/m-unclaimed`), {
      displayName: 'Gogo',
      color: 'mint',
      role: 'helper',
      claimedBy: null,
    });
    await seedRecords(db);
  });
}

function task(title: string, assigneeIds: string[]): Record<string, unknown> {
  return {
    title,
    note: null,
    dueDate: DATE,
    recurrence: null,
    assigneeIds,
    createdBy: PEOPLE.admin.member,
    routineId: null,
    createdAt: new Date(),
  };
}

async function seedRecords(db: Firestore): Promise<void> {
  const by = PEOPLE.admin.member;
  const at = new Date();
  await setDoc(doc(db, RECORDS.groceries[0]), {
    name: 'Milk',
    quantity: null,
    addedBy: by,
    addedAt: at,
    boughtAt: null,
    boughtBy: null,
  });
  await setDoc(doc(db, RECORDS.calendar[0]), {
    title: 'Swimming',
    note: null,
    date: DATE,
    startMinute: 900,
    endMinute: 960,
    recurrence: null,
    memberIds: [],
    createdBy: by,
    createdAt: at,
  });
  await setDoc(doc(db, RECORDS.calendar[1]), {
    eventId: 'swim',
    occurrenceDate: DATE,
    skippedBy: by,
    skippedAt: at,
  });
  await setDoc(doc(db, RECORDS.todos[0]), task('Bins', []));
  await setDoc(doc(db, `${HOME}/tasks/homework`), task('Homework', [PEOPLE.kid.member]));
  await setDoc(doc(db, `${HOME}/tasks/ironing`), task('Ironing', [PEOPLE.carer.member]));
  await setDoc(doc(db, `${HOME}/tasks/tax`), task('Tax return', [PEOPLE.admin.member]));
  await setDoc(doc(db, RECORDS.todos[1]), {
    name: 'Sunday',
    firstDate: DATE,
    recurrence: null,
    defaultAssigneeIds: [],
    color: 'violet',
    createdBy: by,
    createdAt: at,
  });
  await setDoc(doc(db, RECORDS.todos[2]), {
    taskId: 'bins',
    occurrenceDate: DATE,
    completedBy: by,
    completedFor: by,
    completedAt: at,
  });
  await setDoc(doc(db, `${HOME}/taskCompletions/homework_2026-09-28`), {
    taskId: 'homework',
    occurrenceDate: '2026-09-28',
    completedBy: PEOPLE.kid.member,
    completedFor: PEOPLE.kid.member,
    completedAt: at,
  });
  await setDoc(doc(db, RECORDS.meals[0]), {
    name: 'Curry',
    nameKey: 'curry',
    addedBy: by,
    createdAt: at,
  });
  await setDoc(doc(db, RECORDS.meals[1]), { slots: {} });
  await setDoc(doc(db, RECORDS.documents[0]), { name: 'School', createdBy: by, createdAt: at });
  await setDoc(doc(db, RECORDS.documents[1]), {
    folderId: 'school',
    name: 'Passport',
    contentType: 'application/pdf',
    sizeBytes: 1024,
    uploadedBy: by,
    uploadedAt: at,
  });
}

/** Whether this person should be able to read this area, from the ADR alone. */
export function expectsToView(person: Person, area: GuardedArea): boolean {
  const role: string = PEOPLE[person].role;
  if (['admin', 'parent', 'member'].includes(role)) return true;
  const grant = GRANTS[person];
  if (grant === undefined) return role === 'helper';
  return grant[area] === 'view' || grant[area] === 'edit';
}

/**
 * Whether this person should be able to read this record. The area decides,
 * with one exception: `own` on to-dos also reads the routines, so a chore of
 * theirs follows its routine's schedule (accounts ADR-0004).
 */
export function expectsToRead(person: Person, area: GuardedArea, path: string): boolean {
  if (expectsToView(person, area)) return true;
  return path.includes('/routines/') && GRANTS[person]?.todos === 'own';
}
