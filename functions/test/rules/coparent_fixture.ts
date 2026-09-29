import { doc, setDoc } from 'firebase/firestore';

import { ALTERNATING, DADS_HOME, MUMS_HOME } from '../coparent_fixtures';
import { DATE, HOME, HOUSEHOLD, givenAHouseholdOfEveryRole } from './access_fixture';
import { givenData, type Firestore } from './rules_harness';

/**
 * Two homes and the link between them (household ADR-0004): Mum's home is the
 * access fixture's household, with every role and grant; Dad's home is a
 * second household with its own admin and its own records. Each holds its own
 * mirror of the link, as the co-parenting Functions write it.
 */
export const LINK = 'link-sam';

export const DADS = {
  household: 'h-dad',
  home: 'households/h-dad',
  admin: { uid: 'uid-dad', member: 'm-dad' },
  parent: { uid: 'uid-step', member: 'm-step' },
  child: 'm-sam-dad',
} as const;

export const MUM_CHILD = 'm-kid';

/** The mirror paths, under each home. */
export function mirrorPaths(home: string): {
  link: string;
  handover: string;
  request: string;
} {
  return {
    link: `${home}/coParentLinks/${LINK}`,
    handover: `${home}/coParentLinks/${LINK}/handovers/${DATE}`,
    request: `${home}/coParentLinks/${LINK}/requests/swap-1`,
  };
}

/** Records only Dad's home keeps — what Mum's home must never read. */
export const DADS_OWN_RECORDS = [
  `${DADS.home}/events/football`,
  `${DADS.home}/groceryItems/bread`,
  `${DADS.home}/tasks/dishes`,
  `${DADS.home}/members/${DADS.admin.member}`,
  `${DADS.home}/familyProfiles/${DADS.child}`,
  `${DADS.home}/documents/lease`,
] as const;

function mirror(ownSide: 'a' | 'b', childMemberId: string): Record<string, unknown> {
  return {
    status: 'active',
    ownSide,
    childMemberId,
    childName: 'Sam',
    homes: { a: MUMS_HOME, b: DADS_HOME },
    schedule: ALTERNATING,
    overrides: {},
    awaitingSide: null,
    endedBySide: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };
}

const HANDOVER = {
  date: DATE,
  items: [{ text: 'School bag', packed: true }],
  medicine: 'Half a Panado at 7',
  homework: null,
  clothes: null,
  note: null,
  updatedBySide: 'a',
  updatedAt: new Date(),
};

const REQUEST = {
  kind: 'swap',
  from: '2026-10-02',
  to: '2026-10-04',
  toSide: 'a',
  note: null,
  proposedBySide: 'b',
  status: 'pending',
  createdAt: new Date(),
  answeredAt: null,
  answeredBySide: null,
  answerNote: null,
};

export async function givenTwoLinkedHomes(): Promise<void> {
  await givenAHouseholdOfEveryRole();
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, DADS.home), {
      name: 'Dad and Lindi',
      timeZone: 'Africa/Johannesburg',
      members: { [DADS.admin.uid]: 'admin', [DADS.parent.uid]: 'parent' },
      profiles: { [DADS.admin.uid]: DADS.admin.member, [DADS.parent.uid]: DADS.parent.member },
      access: {},
    });
    for (const [path, data] of [
      [`${DADS.home}/members/${DADS.admin.member}`, { displayName: 'Dad', role: 'admin' }],
      [`${DADS.home}/events/football`, { title: 'Football', date: DATE }],
      [`${DADS.home}/groceryItems/bread`, { name: 'Bread' }],
      [`${DADS.home}/tasks/dishes`, { title: 'Dishes', assigneeIds: [] }],
      [`${DADS.home}/familyProfiles/${DADS.child}`, { allergies: [] }],
      [`${DADS.home}/documents/lease`, { name: 'Lease' }],
    ] as const) {
      await setDoc(doc(db, path), data);
    }
    const mum = mirrorPaths(HOME);
    const dad = mirrorPaths(DADS.home);
    await setDoc(doc(db, mum.link), mirror('a', MUM_CHILD));
    await setDoc(doc(db, dad.link), mirror('b', DADS.child));
    for (const paths of [mum, dad]) {
      await setDoc(doc(db, paths.handover), HANDOVER);
      await setDoc(doc(db, paths.request), REQUEST);
    }
    await setDoc(doc(db, `coParentLinks/${LINK}`), {
      householdIds: { a: HOUSEHOLD, b: DADS.household },
      childMemberIds: { a: MUM_CHILD, b: DADS.child },
      status: 'active',
    });
    await setDoc(doc(db, 'coParentInvites/ABCD2345'), {
      householdId: HOUSEHOLD,
      childMemberId: MUM_CHILD,
      redeemedBy: null,
    });
    await setDoc(doc(db, 'appConfig/flags'), { coParenting: true });
  });
}

export const A_MIRROR = mirror('a', MUM_CHILD);
export { HANDOVER, REQUEST };
