import { doc, setDoc } from 'firebase/firestore';

import { ROLE_DEFAULTS, type Grant } from '../../src/household/access';
import { givenData, type Firestore } from './rules_harness';

/**
 * The Parkers, for the family-profiles rules suites (family-profiles
 * ADR-0001, ADR-0002): an admin, a parent, a helper a parent let see the
 * family's profiles but not their medicine, a carer on the carer defaults, a
 * cleaner who sees neither, and a kid profile nobody has claimed, with a
 * tablet signed in as it (accounts ADR-0004).
 */

export const SAM = 'uid-sam'; // admin, claimed m-sam
export const MIA = 'uid-mia'; // member (read as parent), claimed m-mia — a second adult who is not an admin
export const THANDI = 'uid-thandi'; // helper, claimed m-thandi: profiles at view, no medical
export const NOMSA = 'uid-nomsa'; // carer, claimed m-nomsa, on the carer defaults
export const CLEO = 'uid-cleo'; // helper, claimed m-cleo, cleaning only
export const KID_TABLET = 'kid_tablet'; // a kid device signed in as m-kid
export const STRANGER = 'uid-stranger';
export const OLIVIA = 'uid-olivia'; // admin of another household
export const HOUSEHOLD = 'h1';
export const OTHER_HOUSEHOLD = 'h2';
export const KID = 'm-kid'; // nobody has claimed it
export const THANDI_MEMBER = 'm-thandi';
export const PROFILES = `households/${HOUSEHOLD}/familyProfiles`;
export const HEALTH = `households/${HOUSEHOLD}/memberHealth`;
export const SCHOOLS = `households/${HOUSEHOLD}/schools`;
export const merge = { merge: true } as const;

export const NONE: Grant = {
  calendar: 'none',
  groceries: 'none',
  todos: 'none',
  meals: 'none',
  documents: 'none',
  lunch: 'none',
  familyProfiles: 'none',
  medical: 'none',
  homeCare: 'none',
  nannyHub: 'none',
};
/** A parent let this helper see the family's profiles, and not their medicine. */
export const PROFILES_ONLY: Grant = { ...NONE, familyProfiles: 'view' };
export const CLEANING_ONLY: Grant = { ...NONE, homeCare: 'own' };

export async function givenTheParkers(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `households/${HOUSEHOLD}`), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: {
        [SAM]: 'admin',
        [MIA]: 'member',
        [THANDI]: 'helper',
        [NOMSA]: 'carer',
        [CLEO]: 'helper',
      },
      profiles: { [THANDI]: THANDI_MEMBER, [NOMSA]: 'm-nomsa', [CLEO]: 'm-cleo' },
      access: { [THANDI]: PROFILES_ONLY, [NOMSA]: ROLE_DEFAULTS.carer, [CLEO]: CLEANING_ONLY },
      kids: { [KID_TABLET]: KID },
    });
    for (const [id, role, claimedBy, access] of [
      ['m-sam', 'admin', SAM, null],
      ['m-mia', 'member', MIA, null],
      [THANDI_MEMBER, 'helper', THANDI, PROFILES_ONLY],
      ['m-nomsa', 'carer', NOMSA, ROLE_DEFAULTS.carer],
      ['m-cleo', 'helper', CLEO, CLEANING_ONLY],
      [KID, 'kid', null, ROLE_DEFAULTS.kid],
    ] as const) {
      await setDoc(doc(db, `households/${HOUSEHOLD}/members/${id}`), {
        displayName: id,
        color: 'violet',
        role,
        claimedBy,
        ...(access === null ? {} : { access }),
      });
    }
    await setDoc(doc(db, `households/${OTHER_HOUSEHOLD}`), {
      name: 'The Others',
      timeZone: 'Africa/Johannesburg',
      members: { [OLIVIA]: 'admin' },
    });
    await setDoc(doc(db, `${SCHOOLS}/oakwood`), {
      name: 'Oakwood Primary',
      nutFree: true,
      createdAt: new Date(),
    });
  });
}

/** The kid, with a severe peanut allergy and a school, and one medicine. */
export async function givenTheKidsDetails(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `${PROFILES}/${KID}`), aFullProfile());
    await setDoc(doc(db, `${HEALTH}/${KID}`), {
      medications: { ritalin: { name: 'Inhaler', dose: 'Two puffs', times: [420], note: null } },
    });
  });
}

export function aFullProfile(): Record<string, unknown> {
  return {
    isChild: true,
    likes: ['Pasta', 'Apples'],
    dislikes: ['Mushrooms'],
    diet: ['nutFree', 'halal'],
    allergies: {
      peanut: { severity: 'severe', note: 'Adrenaline pen in her bag' },
      milk: { severity: 'mild', note: null },
    },
    otherAllergies: { k1: { name: 'Kiwi', severity: 'moderate', note: null } },
    schoolId: 'oakwood',
    grade: 'Grade 3',
    clothingSize: '7-8',
    shoeSize: 'UK 13',
  };
}
