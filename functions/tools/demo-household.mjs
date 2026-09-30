/**
 * The demo household the emulator seed builds (foundation ADR-0018): one
 * family, the same ids on every run, written in the shapes the callables
 * write — so the seeded sign-in lands in the same household on every device,
 * after every restart of the app or the suite.
 *
 * Every write is a merge onto fixed ids and `createdAt` is set only on a
 * document that does not exist yet, so running it again over imported data
 * restores the seeded parts and leaves what somebody added by hand.
 *
 * Nothing here is invented shape: grants, claims, the entitlement and the
 * flag list come from the Functions' own code in `lib/` (`ENG-01`), so run
 * `npm run build` first — the emulator runs `lib/` too.
 */
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';

const require = createRequire(import.meta.url);
const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const { effectiveGrant, ROLE_DEFAULTS } = require('../lib/household/access.js');
const { writeAccountClaims } = require('../lib/household/access_claim.js');
const { FREE } = require('../lib/subscriptions/entitlement.js');
const { entitlementFields } = require('../lib/subscriptions/subscription_documents.js');
const { FEATURE_FLAGS } = require('../lib/shared/feature_flags.js');

export const HOUSEHOLD_ID = 'demo-household';
const HOUSEHOLD_NAME = 'The Oak Street Nest';
const TIME_ZONE = 'Africa/Johannesburg';

/** The three seeded people: fixed uids, and the profile each one claims. */
export const PEOPLE = [
  {
    uid: 'seed-parent',
    email: 'parent@nestprep.test',
    displayName: 'Sam Parent',
    memberId: 'sam',
    role: 'admin',
    color: 'teal',
  },
  {
    uid: 'seed-partner',
    email: 'partner@nestprep.test',
    displayName: 'Alex Parent',
    memberId: 'alex',
    role: 'parent',
    color: 'coral',
  },
  {
    uid: 'seed-helper',
    email: 'helper@nestprep.test',
    displayName: 'Thandi Helper',
    memberId: 'thandi',
    role: 'helper',
    color: 'amber',
    // A helper's default grant (household ADR-0003), with the lunches opened
    // up to `view` so the person packing them can see what goes in.
    access: { ...ROLE_DEFAULTS.helper, lunch: 'view' },
  },
];

/** Two children with no sign-in of their own: one allergy, one nut-free school. */
const SCHOOLS = [
  { id: 'greenside-primary', name: 'Greenside Primary', nutFree: true },
  { id: 'parkview-junior', name: 'Parkview Junior', nutFree: false },
];

const CHILDREN = [
  {
    memberId: 'mia',
    displayName: 'Mia',
    color: 'violet',
    birthday: '2018-03-14',
    profile: {
      isChild: true,
      allergies: { peanut: { severity: 'severe', note: 'EpiPen in the school bag' } },
      schoolId: 'parkview-junior',
      grade: 'Grade 2',
      likes: ['cheese sandwiches', 'apples'],
      dislikes: ['tomato'],
    },
  },
  {
    memberId: 'leo',
    displayName: 'Leo',
    color: 'sky',
    birthday: '2020-11-02',
    profile: {
      isChild: true,
      schoolId: 'greenside-primary',
      grade: 'Grade R',
      diet: ['nutFree'],
      likes: ['pasta', 'grapes'],
    },
  },
];

/** The legal versions this build ships, read from the one source (accounts ADR-0005). */
function legalVersion(document) {
  const text = readFileSync(
    resolve(import.meta.dirname, `../../app/assets/legal/${document}.md`),
    'utf8',
  );
  const match = /^version:\s*(\d+)\s*$/m.exec(text);
  if (match === null) throw new Error(`no version in ${document}.md`);
  return Number(match[1]);
}

/** A merge that stamps `createdAt` only the first time the document exists. */
async function upsert(ref, data) {
  const snapshot = await ref.get();
  const fields = snapshot.exists ? data : { ...data, createdAt: FieldValue.serverTimestamp() };
  await ref.set(fields, { merge: true });
}

export async function seedDemoHousehold(store) {
  const household = store.collection('households').doc(HOUSEHOLD_ID);
  const privacyVersion = legalVersion('privacy-policy');
  const termsVersion = legalVersion('terms-of-service');
  const admin = PEOPLE[0];

  // The household: its uid→role map, the profile each uid claimed, and the
  // grant of everybody who is not family — what `createHousehold` and
  // `redeemInvite` (through `recordClaim`) write between them.
  const members = {};
  const profiles = {};
  const access = {};
  for (const person of PEOPLE) {
    members[person.uid] = person.role;
    profiles[person.uid] = person.memberId;
    const grant = effectiveGrant(person.role, person.access ?? null);
    if (grant !== null) access[person.uid] = grant;
  }
  await upsert(household, {
    name: HOUSEHOLD_NAME,
    timeZone: TIME_ZONE,
    members,
    profiles,
    access,
    createdBy: admin.uid,
    // Set up already: no invite step waiting on the admin.
    pendingSetupStep: null,
  });

  for (const person of PEOPLE) {
    await upsert(household.collection('members').doc(person.memberId), {
      displayName: person.displayName,
      color: person.color,
      role: person.role,
      claimedBy: person.uid,
      ...(person.access === undefined ? {} : { access: person.access }),
    });
  }

  for (const school of SCHOOLS) {
    await upsert(household.collection('schools').doc(school.id), {
      name: school.name,
      nutFree: school.nutFree,
    });
  }

  // Children: an unclaimed `kid` profile with a parent's consent on it
  // (accounts ADR-0005), and `isChild` on the family profile — which is what
  // `setChildProfile` writes, beside the free child it keeps.
  for (const child of CHILDREN) {
    const member = household.collection('members').doc(child.memberId);
    const existing = await member.get();
    await upsert(member, {
      displayName: child.displayName,
      color: child.color,
      role: 'kid',
      claimedBy: null,
      birthday: child.birthday,
      ...(existing.get('guardianConsent') == null
        ? {
            guardianConsent: {
              byMemberId: admin.memberId,
              version: privacyVersion,
              at: FieldValue.serverTimestamp(),
            },
          }
        : {}),
    });
    await household
      .collection('familyProfiles')
      .doc(child.memberId)
      .set(child.profile, { merge: true });
  }
  await household
    .collection('entitlement')
    .doc('freeChild')
    .set({ memberId: CHILDREN[0].memberId });

  // Premium until 2099, as months given rather than a store purchase, so
  // every premium feature can be tried and nothing reads as a subscription
  // somebody would have to manage.
  const until = new Date('2099-12-31T00:00:00Z');
  await household
    .collection('entitlement')
    .doc('current')
    .set(
      entitlementFields(
        { ...FREE, isTest: true },
        {
          premiumUntil: until,
          storeUntil: null,
          referralUntil: until,
          referralDaysWaiting: 0,
          referralFrom: new Date(),
        },
      ),
    );

  // Every V2 switch on, which is also the emulator's default when the
  // document is absent — written so a release build against the suite agrees.
  await store
    .collection('appConfig')
    .doc('flags')
    .set(Object.fromEntries(FEATURE_FLAGS.map((flag) => [flag, true])), { merge: true });

  // Each account: the household in its list and active, and the documents
  // this build ships already agreed to, so a seeded sign-in lands in the week.
  for (const person of PEOPLE) {
    await upsert(store.collection('users').doc(person.uid), {
      displayName: person.displayName,
      photoUrl: null,
      householdIds: FieldValue.arrayUnion(HOUSEHOLD_ID),
      activeHouseholdId: HOUSEHOLD_ID,
      legalConsent: { termsVersion, privacyVersion, acceptedAt: Timestamp.now() },
    });
  }

  // The token claims Storage rules read, from what was just written — the
  // same projection `syncDocumentAccess` makes (documents ADR-0001).
  for (const person of PEOPLE) await writeAccountClaims(store, person.uid);

  return `${HOUSEHOLD_NAME} (${HOUSEHOLD_ID}): ${String(PEOPLE.length)} adults, ${String(CHILDREN.length)} children, premium, every flag on`;
}
