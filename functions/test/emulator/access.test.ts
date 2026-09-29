import { FieldValue, type DocumentReference } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { ROLE_DEFAULTS, uniformGrant } from '../../src/household/access';
import {
  CallFailed,
  adminAuth,
  adminDb,
  callAs,
  clearFirestore,
  signUp,
  type TestUser,
} from './emulator_harness';

/**
 * The callables of household ADR-0003, end to end: a parent chooses what a
 * helper may do, and it lands on the profile, in the household's `access`
 * map every rule reads, and on the helper's token for Storage.
 */
interface Created {
  householdId: string;
  memberId: string;
}

const CLEANING_ONLY = { ...uniformGrant('none'), homeCare: 'own' };

async function createHousehold(user: TestUser): Promise<Created> {
  return callAs<Created>(user, 'createHousehold', {
    name: 'The Parkers',
    timeZone: 'Africa/Johannesburg',
    adminDisplayName: 'Sam',
    adminColor: 'violet',
  });
}

function household(householdId: string): DocumentReference {
  return adminDb().collection('households').doc(householdId);
}

async function addProfile(householdId: string, role: string, access?: unknown): Promise<string> {
  const ref = household(householdId).collection('members').doc();
  await ref.set({
    displayName: role,
    color: 'mint',
    role,
    claimedBy: null,
    createdAt: new Date(),
    ...(access === undefined ? {} : { access }),
  });
  return ref.id;
}

async function join(
  admin: TestUser,
  joiner: TestUser,
  householdId: string,
  memberId: string,
): Promise<void> {
  const invite = await callAs<{ code: string }>(admin, 'createInvite', { householdId, memberId });
  await callAs(joiner, 'redeemInvite', { code: invite.code });
}

async function expectRefusal(promise: Promise<unknown>, reason: string): Promise<void> {
  await expect(promise).rejects.toThrow(CallFailed);
  await promise.catch((error: unknown) => {
    expect(error instanceof CallFailed ? error.reason : undefined).toBe(reason);
  });
}

function field(snapshot: { get(path: string): unknown }, path: string): unknown {
  return snapshot.get(path);
}

describe('createHousehold opens the invite step', () => {
  beforeEach(clearFirestore);

  it('marks the new household as waiting on the invite step, and records its admin’s profile', async () => {
    const sam = await signUp();
    const { householdId, memberId } = await createHousehold(sam);
    const snapshot = await household(householdId).get();
    expect(snapshot.get('pendingSetupStep')).toBe('invitePeople');
    expect(field(snapshot, `profiles.${sam.uid}`)).toBe(memberId);
    expect(snapshot.get('access')).toBeUndefined();
  });
});

describe('redeemInvite records the grant', () => {
  beforeEach(clearFirestore);

  it('gives a helper whose profile holds a choice exactly that choice', async () => {
    const [sam, thandi] = [await signUp(), await signUp()];
    const { householdId } = await createHousehold(sam);
    const memberId = await addProfile(householdId, 'helper', CLEANING_ONLY);
    await join(sam, thandi, householdId, memberId);

    const snapshot = await household(householdId).get();
    expect(field(snapshot, `access.${thandi.uid}`)).toEqual(CLEANING_ONLY);
    expect(field(snapshot, `profiles.${thandi.uid}`)).toBe(memberId);
  });

  it("gives a kid with no stored choice the kid's defaults", async () => {
    const [sam, kid] = [await signUp(), await signUp()];
    const { householdId } = await createHousehold(sam);
    const memberId = await addProfile(householdId, 'kid');
    await join(sam, kid, householdId, memberId);

    const snapshot = await household(householdId).get();
    expect(field(snapshot, `members.${kid.uid}`)).toBe('kid');
    expect(field(snapshot, `access.${kid.uid}`)).toEqual(ROLE_DEFAULTS.kid);
  });

  it('gives a parent no grant at all — family needs none', async () => {
    const [sam, pat] = [await signUp(), await signUp()];
    const { householdId } = await createHousehold(sam);
    const memberId = await addProfile(householdId, 'parent', CLEANING_ONLY);
    await join(sam, pat, householdId, memberId);

    const snapshot = await household(householdId).get();
    expect(field(snapshot, `members.${pat.uid}`)).toBe('parent');
    expect(field(snapshot, `access.${pat.uid}`)).toBeUndefined();
  });
});

describe('setMemberAccess', () => {
  beforeEach(clearFirestore);

  async function helperJoined(): Promise<{ sam: TestUser; thandi: TestUser } & Created> {
    const [sam, thandi] = [await signUp(), await signUp()];
    const { householdId } = await createHousehold(sam);
    const memberId = await addProfile(householdId, 'helper', ROLE_DEFAULTS.helper);
    await join(sam, thandi, householdId, memberId);
    return { sam, thandi, householdId, memberId };
  }

  it('writes the choice to the profile and the household together', async () => {
    const { sam, thandi, householdId, memberId } = await helperJoined();
    await callAs(sam, 'setMemberAccess', { householdId, memberId, access: CLEANING_ONLY });

    const profile = await household(householdId).collection('members').doc(memberId).get();
    expect(profile.get('access')).toEqual(CLEANING_ONLY);
    const snapshot = await household(householdId).get();
    expect(field(snapshot, `access.${thandi.uid}`)).toEqual(CLEANING_ONLY);
  });

  it("brings the helper's token up to date, so Storage agrees at the next refresh", async () => {
    const { sam, thandi, householdId, memberId } = await helperJoined();
    const documentsToo = { ...CLEANING_ONLY, documents: 'view' };
    const result = await callAs<{ tokenUpdated: boolean }>(sam, 'setMemberAccess', {
      householdId,
      memberId,
      access: documentsToo,
    });
    expect(result.tokenUpdated).toBe(true);

    const claims = (await adminAuth().getUser(thandi.uid)).customClaims ?? {};
    expect(claims['households']).toEqual({ [householdId]: 'helper' });
    expect(claims['access']).toEqual({ [householdId]: { documents: 'view', homeCare: 'own' } });
  });

  it('changes an unclaimed profile too, touching no map', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    const memberId = await addProfile(householdId, 'carer');
    await callAs(sam, 'setMemberAccess', { householdId, memberId, access: CLEANING_ONLY });

    const profile = await household(householdId).collection('members').doc(memberId).get();
    expect(profile.get('access')).toEqual(CLEANING_ONLY);
    expect((await household(householdId).get()).get('access')).toBeUndefined();
  });

  it('refuses anybody who is not an admin, the helper included', async () => {
    const { thandi, householdId, memberId } = await helperJoined();
    await expectRefusal(
      callAs(thandi, 'setMemberAccess', { householdId, memberId, access: uniformGrant('edit') }),
      'notAnAdmin',
    );
  });

  it('refuses a grant on family, who already see everything', async () => {
    const sam = await signUp();
    const { householdId, memberId } = await createHousehold(sam);
    await expectRefusal(
      callAs(sam, 'setMemberAccess', { householdId, memberId, access: CLEANING_ONLY }),
      'familyHasFullAccess',
    );
  });

  it('refuses a profile that is not there', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    await expectRefusal(
      callAs(sam, 'setMemberAccess', { householdId, memberId: 'm-gone', access: CLEANING_ONLY }),
      'memberNotFound',
    );
  });

  it('refuses a level an area does not take', async () => {
    const { sam, householdId, memberId } = await helperJoined();
    await expectRefusal(
      callAs(sam, 'setMemberAccess', {
        householdId,
        memberId,
        access: { ...CLEANING_ONLY, calendar: 'own' },
      }),
      'badRequest',
    );
  });
});

describe('setMemberRole resets the grant to the new role', () => {
  beforeEach(clearFirestore);

  it('a helper made a carer gets the carer defaults, on the profile and in the map', async () => {
    const [sam, nomsa] = [await signUp(), await signUp()];
    const { householdId } = await createHousehold(sam);
    const memberId = await addProfile(householdId, 'helper', CLEANING_ONLY);
    await join(sam, nomsa, householdId, memberId);
    await callAs(sam, 'setMemberRole', { householdId, memberId, role: 'carer' });

    const snapshot = await household(householdId).get();
    expect(field(snapshot, `members.${nomsa.uid}`)).toBe('carer');
    expect(field(snapshot, `access.${nomsa.uid}`)).toEqual(ROLE_DEFAULTS.carer);
  });

  it('a helper made a parent loses the grant, because family has none', async () => {
    const [sam, pat] = [await signUp(), await signUp()];
    const { householdId } = await createHousehold(sam);
    const memberId = await addProfile(householdId, 'helper', CLEANING_ONLY);
    await join(sam, pat, householdId, memberId);
    await callAs(sam, 'setMemberRole', { householdId, memberId, role: 'parent' });

    const snapshot = await household(householdId).get();
    expect(field(snapshot, `access.${pat.uid}`)).toBeUndefined();
    const profile = await household(householdId).collection('members').doc(memberId).get();
    expect(profile.get('access')).toBeNull();
  });

  it('writes `member` from an old app as parent', async () => {
    const [sam, lee] = [await signUp(), await signUp()];
    const { householdId } = await createHousehold(sam);
    const memberId = await addProfile(householdId, 'kid');
    await join(sam, lee, householdId, memberId);
    await callAs(sam, 'setMemberRole', { householdId, memberId, role: 'member' });

    const snapshot = await household(householdId).get();
    expect(field(snapshot, `members.${lee.uid}`)).toBe('parent');
  });
});

describe('leaving takes the grant with it', () => {
  beforeEach(clearFirestore);

  it('clears the access and profile entries a departed helper left', async () => {
    const [sam, thandi] = [await signUp(), await signUp()];
    const { householdId } = await createHousehold(sam);
    const memberId = await addProfile(householdId, 'helper', CLEANING_ONLY);
    await join(sam, thandi, householdId, memberId);
    await callAs(thandi, 'leaveHousehold', { householdId });

    const snapshot = await household(householdId).get();
    expect(field(snapshot, `access.${thandi.uid}`)).toBeUndefined();
    expect(field(snapshot, `profiles.${thandi.uid}`)).toBeUndefined();
  });
});

describe('syncDocumentAccess carries the grant to Storage', () => {
  beforeEach(clearFirestore);

  it('writes the access claim for a helper, and none for the admin', async () => {
    const [sam, thandi] = [await signUp(), await signUp()];
    const { householdId } = await createHousehold(sam);
    const memberId = await addProfile(householdId, 'helper', {
      ...CLEANING_ONLY,
      documents: 'edit',
    });
    await join(sam, thandi, householdId, memberId);

    await callAs(thandi, 'syncDocumentAccess', {});
    await callAs(sam, 'syncDocumentAccess', {});

    const helperClaims = (await adminAuth().getUser(thandi.uid)).customClaims ?? {};
    expect(helperClaims['access']).toEqual({
      [householdId]: { documents: 'edit', homeCare: 'own' },
    });
    const adminClaims = (await adminAuth().getUser(sam.uid)).customClaims ?? {};
    expect(adminClaims['access']).toEqual({});
  });

  it('gives a helper claimed before ADR-0003, with no grant, what every helper had', async () => {
    const [sam, old] = [await signUp(), await signUp()];
    const { householdId } = await createHousehold(sam);
    const memberId = await addProfile(householdId, 'helper');
    await join(sam, old, householdId, memberId);
    // What an account claimed before the ADR looks like: in the map, no grant.
    await household(householdId).update({ [`access.${old.uid}`]: FieldValue.delete() });

    await callAs(old, 'syncDocumentAccess', {});
    const claims = (await adminAuth().getUser(old.uid)).customClaims ?? {};
    expect(claims['access']).toEqual({
      [householdId]: {
        documents: 'edit',
        homeCare: 'edit',
        nannyHub: 'edit',
        familyProfiles: 'edit',
        medical: 'edit',
      },
    });
  });
});
