import { Timestamp, doc, serverTimestamp, setDoc } from 'firebase/firestore';

import { HOME, PEOPLE, givenAHouseholdOfEveryRole } from './access_fixture';
import { givenData, type Firestore } from './rules_harness';

/**
 * The nanny hub's records (nanny-hub ADR-0003), seeded into the household of
 * every role so each test can ask what the carer, the cleaner, the look-only
 * helper, the kid, the kid's tablet and family may do with each.
 *
 * In that household the carer holds the carer defaults (`nannyHub: edit`),
 * the "viewer" helper holds `view` everywhere, and the cleaner and the kid
 * hold `none` for the hub.
 */
export const CHILD = PEOPLE.kid.member;
export const CARER = PEOPLE.carer;

export const PATHS = {
  card: `${HOME}/nannyChildCards/${CHILD}`,
  contact: `${HOME}/nannyContacts/gogo`,
  sheet: `${HOME}/nannyHome/sheet`,
  spot: `${HOME}/nannyGuide/nappies`,
  rule: `${HOME}/nannyRules/screens`,
  checklist: `${HOME}/nannyChecklists/bedtime`,
  openShift: `${HOME}/nannyShifts/tonight`,
  endedShift: `${HOME}/nannyShifts/last-week`,
  entry: `${HOME}/nannyShifts/tonight/entries/tea`,
  endedEntry: `${HOME}/nannyShifts/last-week/entries/bath`,
  summary: `${HOME}/nannyShiftSummaries/last-week`,
} as const;

/** A card as the app writes its first section. */
export function card(updatedBy: string): Record<string, unknown> {
  return {
    routines: [{ label: 'Bath', minuteOfDay: 1080, note: null }],
    comfortItems: ['Blue bunny'],
    settling: 'Two songs and the night light.',
    updatedBy,
    updatedAt: serverTimestamp(),
  };
}

export function contact(
  createdBy: string,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    name: 'Dr Naidoo',
    kind: 'doctor',
    phone: '+27 11 555 0101',
    note: null,
    createdBy,
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

export function shift(startedBy: string, carerMemberId = startedBy): Record<string, unknown> {
  return {
    carerMemberId,
    startedBy,
    startedAt: serverTimestamp(),
    endedAt: null,
    endedBy: null,
    status: 'open',
    ticks: {},
  };
}

export function entry(
  byMemberId: string,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    kind: 'meal',
    note: 'Ate all the pasta',
    mood: null,
    childIds: [CHILD],
    photoId: null,
    at: Timestamp.now(),
    byMemberId,
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

export async function givenAHubOfEveryRole(): Promise<void> {
  await givenAHouseholdOfEveryRole();
  await givenData(async (db: Firestore) => {
    const by = PEOPLE.admin.member;
    const at = new Date();
    await setDoc(doc(db, PATHS.card), { ...card(by), updatedAt: at });
    await setDoc(doc(db, PATHS.contact), { ...contact(by), createdAt: at });
    await setDoc(doc(db, PATHS.sheet), {
      address: '12 Acacia Lane',
      medicalAidScheme: 'Discovery',
      medicalAidPlan: null,
      medicalAidNumber: '123456',
      updatedBy: by,
      updatedAt: at,
    });
    await setDoc(doc(db, PATHS.spot), {
      title: 'Nappies',
      note: 'Top shelf',
      photoId: null,
      createdBy: by,
      createdAt: at,
    });
    await setDoc(doc(db, PATHS.rule), { text: 'No screens after 6', createdBy: by, createdAt: at });
    await setDoc(doc(db, PATHS.checklist), {
      items: [{ id: 'teeth', text: 'Brush teeth' }],
      updatedBy: by,
      updatedAt: at,
    });
    await setDoc(doc(db, PATHS.openShift), { ...shift(CARER.member), startedAt: at });
    await setDoc(doc(db, PATHS.endedShift), {
      ...shift(CARER.member),
      startedAt: at,
      endedAt: at,
      endedBy: CARER.member,
      status: 'ended',
    });
    await setDoc(doc(db, PATHS.entry), { ...entry(CARER.member), createdAt: at });
    await setDoc(doc(db, PATHS.endedEntry), { ...entry(CARER.member), createdAt: at });
    await setDoc(doc(db, PATHS.summary), {
      carerMemberId: CARER.member,
      entryCount: 1,
      delivery: { state: 'pending' },
    });
  });
}
