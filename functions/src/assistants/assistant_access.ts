import type { Firestore } from 'firebase-admin/firestore';

import { isFamilyRole, type Level } from '../household/access';
import { HOUSEHOLDS, MEMBERS, type HouseholdDocument } from '../household/documents';
import { levelNow } from '../household/shift_window';
import { APP_CONFIG, readFlag } from '../shared/feature_flags';
import { SCOPE_NEEDS, type AssistantScope } from './assistant_scopes';
import { AssistantRefusal, type AssistantPrincipal } from './principal';

/** `appConfig/assistants.enabled: false` stops every assistant call at once. */
export const ASSISTANTS_CONFIG_DOCUMENT = 'assistants';

/** `households/{h}/assistantSettings/current.allowed: false` is a household's own off switch. */
export const ASSISTANT_SETTINGS = 'assistantSettings';
export const CURRENT_SETTINGS = 'current';

/** The member an allowed call acts as, and the household it read to decide. */
export interface AssistantMember {
  readonly memberId: string;
  readonly role: string;
  readonly household: HouseholdDocument;
}

const LEVEL_RANK: Record<Level, number> = { none: 0, own: 1, view: 2, edit: 3 };

/**
 * The one check every assistant tool makes before it reads or writes
 * (assistants ADR-0003). The Admin SDK skips Security Rules, so this is where
 * the rules' answer is given again, live, on every call: the scope the member
 * granted, both off switches, membership, a family role (v1), the household's
 * own switch, the area level the rules' `levelIn` would give right now
 * (shift-aware), and the profile the member claimed, which every write is
 * stamped with.
 */
export async function requireAccess(
  store: Firestore,
  principal: AssistantPrincipal,
  scope: AssistantScope,
  now: Date,
): Promise<AssistantMember> {
  if (!principal.scopes.includes(scope)) {
    throw new AssistantRefusal(
      'insufficientScope',
      'scopeNotGranted',
      `This connection was not given ${scope}.`,
      scope,
    );
  }
  await requireSwitchedOn(store);

  const householdRef = store.collection(HOUSEHOLDS).doc(principal.householdId);
  const [householdSnapshot, settingsSnapshot] = await Promise.all([
    householdRef.get(),
    householdRef.collection(ASSISTANT_SETTINGS).doc(CURRENT_SETTINGS).get(),
  ]);
  const household = householdSnapshot.data() as HouseholdDocument | undefined;
  if (household === undefined) {
    throw new AssistantRefusal(
      'forbidden',
      'householdNotFound',
      'That household no longer exists.',
    );
  }
  const role = household.members[principal.uid];
  if (role === undefined) {
    throw new AssistantRefusal('forbidden', 'notAMember', 'You are no longer in this household.');
  }
  if (!isFamilyRole(role)) {
    throw new AssistantRefusal(
      'forbidden',
      'familyOnly',
      'Only admins and parents can use an assistant with NestPrep for now.',
    );
  }
  if (settingsSnapshot.get('allowed') === false) {
    throw new AssistantRefusal(
      'forbidden',
      'householdSwitchedOff',
      'This household has switched assistants off in NestPrep.',
    );
  }

  const need = SCOPE_NEEDS[scope];
  if (need.area !== null) {
    const level = await levelNow(store, {
      householdId: principal.householdId,
      householdData: household,
      uid: principal.uid,
      role,
      storedGrant: household.access?.[principal.uid],
      area: need.area,
      now,
    });
    if (LEVEL_RANK[level] < LEVEL_RANK[need.level]) {
      throw new AssistantRefusal(
        'forbidden',
        'noAccess',
        'You do not have access to that in NestPrep.',
      );
    }
  }

  const memberId = await claimedMemberId(store, principal.householdId, household, principal.uid);
  if (memberId === null) {
    throw new AssistantRefusal(
      'forbidden',
      'noProfile',
      'Claim your profile in the NestPrep app first.',
    );
  }
  return { memberId, role, household };
}

/** Throws `switchedOff` unless the `assistants` flag is on and the kill switch is not thrown. */
export async function requireSwitchedOn(store: Firestore): Promise<void> {
  const [flagOn, config] = await Promise.all([
    readFlag(store, 'assistants'),
    store.collection(APP_CONFIG).doc(ASSISTANTS_CONFIG_DOCUMENT).get(),
  ]);
  if (!flagOn || config.get('enabled') === false) {
    throw new AssistantRefusal(
      'switchedOff',
      'switchedOff',
      'NestPrep assistants are switched off.',
    );
  }
}

/**
 * The profile this uid claimed, by the test the rules' `hasClaimed` applies to
 * a write's author — `claimedBy` is the uid — so the app can later edit what an
 * assistant wrote. The household's `profiles` map is tried first; an account
 * claimed before the map existed is found by the query.
 */
async function claimedMemberId(
  store: Firestore,
  householdId: string,
  household: HouseholdDocument,
  uid: string,
): Promise<string | null> {
  const members = store.collection(HOUSEHOLDS).doc(householdId).collection(MEMBERS);
  const mapped = household.profiles?.[uid];
  if (mapped !== undefined) {
    const profile = await members.doc(mapped).get();
    if (profile.get('claimedBy') === uid) return mapped;
  }
  const claimed = await members.where('claimedBy', '==', uid).limit(1).get();
  return claimed.docs[0]?.id ?? null;
}
