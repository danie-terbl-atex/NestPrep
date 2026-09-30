/**
 * The live demo family in the real project (foundation ADR-0019): five
 * adults who sign in, three children who do not, two schools — a South African
 * household on Johannesburg time. Every id is fixed and starts with `demo-`
 * where it is a top-level id, so the seed is idempotent and the teardown can
 * refuse anything else. No real person's data: names, numbers and addresses
 * are invented.
 *
 * The addresses match `app/demo_logins.json` (gitignored), which also holds
 * the one password; nothing here is a secret (ENG-18).
 */
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { ROLE_DEFAULTS } = require('../../lib/household/access.js');

export const HOUSEHOLD_ID = 'demo-oak-street';

/**
 * The five accounts. `loginKey` names the address's define in
 * `demo_logins.json` (`NESTPREP_DEMO_EMAIL_<key>`), which the app reads.
 */
const PEOPLE = [
  {
    uid: 'demo-parent',
    loginKey: 'PARENT',
    email: 'parent@nestprep.test',
    displayName: 'Naledi Botha',
    memberId: 'naledi',
    role: 'admin',
    color: 'teal',
    // Her birthday is this Friday, so the week shows one.
    birthday: '1988-10-02',
    profile: { likes: ['flat whites', 'Sunday braais'], dislikes: ['olives'], shoeSize: 'UK 5' },
  },
  {
    uid: 'demo-partner',
    loginKey: 'PARTNER',
    email: 'partner@nestprep.test',
    displayName: 'Pieter Botha',
    memberId: 'pieter',
    role: 'parent',
    color: 'indigo',
    birthday: '1986-07-19',
    profile: { likes: ['rugby', 'biltong'], dislikes: ['mushrooms'], shoeSize: 'UK 10' },
  },
  {
    uid: 'demo-gran',
    loginKey: 'GRAN',
    email: 'gran@nestprep.test',
    displayName: 'Ouma Elsa',
    memberId: 'elsa',
    // Family: sees everything, does not manage people (household ADR-0003).
    role: 'parent',
    color: 'plum',
    birthday: '1957-12-24',
    profile: { likes: ['rooibos', 'baking rusks'], diet: ['glutenFree'] },
  },
  {
    uid: 'demo-helper',
    loginKey: 'HELPER',
    email: 'helper@nestprep.test',
    displayName: 'Thandi Mokoena',
    memberId: 'thandi',
    role: 'helper',
    color: 'amber',
    birthday: '1979-04-10',
    // The helper default, with lunches opened to `view` so she can pack them —
    // which needs the children's profiles (allergies, schools) to `view` too,
    // because the lunch board reads them — and the meal plan for cooking.
    access: { ...ROLE_DEFAULTS.helper, lunch: 'view', familyProfiles: 'view', meals: 'view' },
  },
  {
    uid: 'demo-nanny',
    loginKey: 'NANNY',
    email: 'nanny@nestprep.test',
    displayName: 'Lindiwe Nkosi',
    memberId: 'lindiwe',
    role: 'carer',
    color: 'mint',
    birthday: '1996-01-30',
    // The carer default: the nanny hub to edit, the children's profiles and
    // medicine to read, her own to-dos.
    access: { ...ROLE_DEFAULTS.carer },
  },
];

const SCHOOLS = [
  { id: 'oakwood-primary', name: 'Oakwood Primary', nutFree: true },
  { id: 'jacaranda-prep', name: 'Jacaranda Prep', nutFree: false },
];

const CHILDREN = [
  {
    memberId: 'lerato',
    displayName: 'Lerato',
    color: 'violet',
    birthday: '2017-05-12',
    profile: {
      allergies: { milk: { severity: 'mild', note: 'A little cheese is fine; no glass of milk.' } },
      schoolId: 'jacaranda-prep',
      grade: 'Grade 4',
      likes: ['chicken wraps', 'naartjies', 'netball', 'drawing'],
      dislikes: ['tomato', 'boiled eggs'],
      clothingSize: '9-10',
      shoeSize: 'UK 2',
    },
  },
  {
    memberId: 'sipho',
    displayName: 'Sipho',
    color: 'sky',
    // Six next Tuesday: the party is on the calendar.
    birthday: '2020-10-06',
    profile: {
      allergies: {
        peanut: { severity: 'severe', note: 'EpiPen in the red pouch of his school bag.' },
      },
      diet: ['nutFree'],
      schoolId: 'oakwood-primary',
      grade: 'Grade R',
      likes: ['pasta', 'grapes', 'soccer', 'dinosaurs'],
      dislikes: ['peas'],
      clothingSize: '5-6',
      shoeSize: 'UK 11',
    },
  },
  {
    memberId: 'zoe',
    displayName: 'Zoë',
    color: 'pink',
    birthday: '2024-03-03',
    profile: {
      likes: ['bananas', 'bath time', 'Bluey'],
      dislikes: ['car seats'],
      otherAllergies: { k1: { name: 'Kiwi', severity: 'mild', note: 'A rash round the mouth.' } },
      clothingSize: '2-3',
      shoeSize: 'UK 6',
    },
  },
];

/** What `seedDemoHousehold` takes. */
export const CLOUD_CAST = {
  householdId: HOUSEHOLD_ID,
  name: 'The Oak Street Nest',
  timeZone: 'Africa/Johannesburg',
  people: PEOPLE,
  children: CHILDREN,
  schools: SCHOOLS,
};

/** Member ids by who they are, so the content modules read like the family. */
export const WHO = {
  mom: 'naledi',
  dad: 'pieter',
  gran: 'elsa',
  helper: 'thandi',
  nanny: 'lindiwe',
  lerato: 'lerato',
  sipho: 'sipho',
  zoe: 'zoe',
};

/** A member's uid, for the few places that stamp one (Storage metadata). */
export function uidOf(memberId) {
  const person = PEOPLE.find((candidate) => candidate.memberId === memberId);
  if (person === undefined) throw new Error(`no account for ${memberId}`);
  return person.uid;
}
