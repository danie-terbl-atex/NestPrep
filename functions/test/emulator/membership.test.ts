import { beforeEach, describe, expect, it } from 'vitest';

import {
  CallFailed,
  adminDb,
  callAs,
  clearFirestore,
  signUp,
  type TestUser,
} from './emulator_harness';

interface CreatedHousehold {
  householdId: string;
  memberId: string;
}
interface CreatedInvite {
  code: string;
}

async function createHousehold(user: TestUser): Promise<CreatedHousehold> {
  return callAs<CreatedHousehold>(user, 'createHousehold', {
    name: 'The Parkers',
    timeZone: 'Africa/Johannesburg',
    adminDisplayName: 'Sam Parent',
    adminColor: 'violet',
  });
}

async function addMember(
  householdId: string,
  displayName: string,
  role = 'member',
): Promise<string> {
  const ref = adminDb().collection('households').doc(householdId).collection('members').doc();
  await ref.set({ displayName, color: 'mint', role, claimedBy: null, createdAt: new Date() });
  return ref.id;
}

/** The household's uid→role map, typed, so a test never reads through `any`. */
function membersOf(snapshot: { get(field: string): unknown }): Record<string, string> {
  return (snapshot.get('members') ?? {}) as Record<string, string>;
}

async function expectRefusal(promise: Promise<unknown>, reason: string): Promise<void> {
  await expect(promise).rejects.toThrow(CallFailed);
  await promise.catch((error: unknown) => {
    expect(error instanceof CallFailed ? error.reason : undefined).toBe(reason);
  });
}

/** Sam's household with Thandi's profile claimed by a second account. */
async function householdWithHelper(): Promise<{
  sam: TestUser;
  thandi: TestUser;
  householdId: string;
  helperMemberId: string;
}> {
  const sam = await signUp();
  const thandi = await signUp();
  const { householdId } = await createHousehold(sam);
  const helperMemberId = await addMember(householdId, 'Thandi', 'helper');
  const invite = await callAs<CreatedInvite>(sam, 'createInvite', {
    householdId,
    memberId: helperMemberId,
  });
  await callAs(thandi, 'redeemInvite', { code: invite.code });
  return { sam, thandi, householdId, helperMemberId };
}

describe('redeemInvite', () => {
  beforeEach(clearFirestore);

  it('claims the profile, joins the membership map and the account, and spends the code', async () => {
    const { thandi, householdId, helperMemberId } = await householdWithHelper();

    const member = await adminDb()
      .collection('households')
      .doc(householdId)
      .collection('members')
      .doc(helperMemberId)
      .get();
    expect(member.get('claimedBy')).toBe(thandi.uid);

    const household = await adminDb().collection('households').doc(householdId).get();
    expect(membersOf(household)[thandi.uid]).toBe('helper');

    const account = await adminDb().collection('users').doc(thandi.uid).get();
    expect(account.get('householdIds')).toEqual([householdId]);
    expect(account.get('activeHouseholdId')).toBe(householdId);
  });

  it('refuses the same code a second time', async () => {
    const sam = await signUp();
    const first = await signUp();
    const second = await signUp();
    const { householdId } = await createHousehold(sam);
    const memberId = await addMember(householdId, 'Kid');
    const invite = await callAs<CreatedInvite>(sam, 'createInvite', { householdId, memberId });

    await callAs(first, 'redeemInvite', { code: invite.code });
    await expectRefusal(callAs(second, 'redeemInvite', { code: invite.code }), 'inviteAlreadyUsed');
  });

  it('refuses a code that has expired', async () => {
    const sam = await signUp();
    const joiner = await signUp();
    const { householdId } = await createHousehold(sam);
    const memberId = await addMember(householdId, 'Kid');
    const invite = await callAs<CreatedInvite>(sam, 'createInvite', { householdId, memberId });

    await adminDb()
      .collection('invites')
      .doc(invite.code)
      .update({ expiresAt: new Date(Date.now() - 1000) });

    await expectRefusal(callAs(joiner, 'redeemInvite', { code: invite.code }), 'inviteExpired');
  });

  it('refuses a code nobody issued, without looking it up when it could never be ours', async () => {
    const joiner = await signUp();
    await expectRefusal(callAs(joiner, 'redeemInvite', { code: 'ABCD2345' }), 'inviteNotFound');
    // Contains characters the alphabet deliberately excludes (0, 1, I, O).
    await expectRefusal(callAs(joiner, 'redeemInvite', { code: 'O0IL1234' }), 'inviteNotFound');
  });

  it('accepts a code typed in lower case', async () => {
    const sam = await signUp();
    const joiner = await signUp();
    const { householdId } = await createHousehold(sam);
    const memberId = await addMember(householdId, 'Kid');
    const invite = await callAs<CreatedInvite>(sam, 'createInvite', { householdId, memberId });

    await callAs(joiner, 'redeemInvite', { code: invite.code.toLowerCase() });
    const household = await adminDb().collection('households').doc(householdId).get();
    // The profile was written as ADR-0001's `member`; it joins as what that
    // now means (household ADR-0003).
    expect(membersOf(household)[joiner.uid]).toBe('parent');
  });

  it('refuses an account that already holds a profile in that household', async () => {
    const { sam, thandi, householdId } = await householdWithHelper();
    const secondProfile = await addMember(householdId, 'Kid');
    const invite = await callAs<CreatedInvite>(sam, 'createInvite', {
      householdId,
      memberId: secondProfile,
    });
    await expectRefusal(
      callAs(thandi, 'redeemInvite', { code: invite.code }),
      'alreadyInHousehold',
    );
  });

  it('refuses a caller who is not signed in', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    const memberId = await addMember(householdId, 'Kid');
    const invite = await callAs<CreatedInvite>(sam, 'createInvite', { householdId, memberId });
    await expectRefusal(callAs(null, 'redeemInvite', { code: invite.code }), 'notSignedIn');
  });
});

describe('leaveHousehold', () => {
  beforeEach(clearFirestore);

  it('refuses the last admin, and lets them go once somebody else is one', async () => {
    const { sam, thandi, householdId, helperMemberId } = await householdWithHelper();

    await expectRefusal(callAs(sam, 'leaveHousehold', { householdId }), 'lastAdmin');

    await callAs(sam, 'setMemberRole', { householdId, memberId: helperMemberId, role: 'admin' });
    await callAs(sam, 'leaveHousehold', { householdId });

    const household = await adminDb().collection('households').doc(householdId).get();
    expect(household.get('members')).toEqual({ [thandi.uid]: 'admin' });

    const account = await adminDb().collection('users').doc(sam.uid).get();
    expect(account.get('householdIds')).toEqual([]);
    expect(account.get('activeHouseholdId')).toBeNull();
  });

  it('unclaims the profile but leaves it standing, so its items still say who they were for', async () => {
    const { thandi, householdId, helperMemberId } = await householdWithHelper();
    await callAs(thandi, 'leaveHousehold', { householdId });

    const member = await adminDb()
      .collection('households')
      .doc(householdId)
      .collection('members')
      .doc(helperMemberId)
      .get();
    expect(member.exists).toBe(true);
    expect(member.get('claimedBy')).toBeNull();
    expect(member.get('displayName')).toBe('Thandi');
  });

  it('refuses somebody who was never in the household', async () => {
    const sam = await signUp();
    const stranger = await signUp();
    const { householdId } = await createHousehold(sam);
    await expectRefusal(callAs(stranger, 'leaveHousehold', { householdId }), 'notAMember');
  });
});

describe('removeMember', () => {
  beforeEach(clearFirestore);

  it('detaches the account and deletes the profile', async () => {
    const { sam, thandi, householdId, helperMemberId } = await householdWithHelper();
    await callAs(sam, 'removeMember', { householdId, memberId: helperMemberId });

    const member = await adminDb()
      .collection('households')
      .doc(householdId)
      .collection('members')
      .doc(helperMemberId)
      .get();
    expect(member.exists).toBe(false);

    const household = await adminDb().collection('households').doc(householdId).get();
    expect(household.get('members')).toEqual({ [sam.uid]: 'admin' });

    const account = await adminDb().collection('users').doc(thandi.uid).get();
    expect(account.get('householdIds')).toEqual([]);
  });

  it('deletes what the household knew about them — profile and medication (family-profiles ADR-0001)', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    const kidId = await addMember(householdId, 'Kid');
    const siblingId = await addMember(householdId, 'Sibling');
    const household = adminDb().collection('households').doc(householdId);
    for (const id of [kidId, siblingId]) {
      await household
        .collection('familyProfiles')
        .doc(id)
        .set({ allergies: { peanut: { severity: 'severe', note: null } } });
      await household
        .collection('memberHealth')
        .doc(id)
        .set({ medications: { a: { name: 'Inhaler', dose: null, times: [], note: null } } });
    }

    await callAs(sam, 'removeMember', { householdId, memberId: kidId });

    expect((await household.collection('familyProfiles').doc(kidId).get()).exists).toBe(false);
    expect((await household.collection('memberHealth').doc(kidId).get()).exists).toBe(false);
    // Only theirs: a sibling's allergies are not collateral.
    expect((await household.collection('familyProfiles').doc(siblingId).get()).exists).toBe(true);
    expect((await household.collection('memberHealth').doc(siblingId).get()).exists).toBe(true);
  });

  it('removes a member who never had a profile, as before', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    const kidId = await addMember(householdId, 'Kid');
    await callAs(sam, 'removeMember', { householdId, memberId: kidId });
    const member = await adminDb()
      .collection('households')
      .doc(householdId)
      .collection('members')
      .doc(kidId)
      .get();
    expect(member.exists).toBe(false);
  });

  it('refuses an admin removing themselves — that is leaving', async () => {
    const sam = await signUp();
    const { householdId, memberId } = await createHousehold(sam);
    await expectRefusal(callAs(sam, 'removeMember', { householdId, memberId }), 'cannotRemoveSelf');
  });

  it('refuses a non-admin', async () => {
    const { thandi, householdId } = await householdWithHelper();
    const kidId = await addMember(householdId, 'Kid');
    await expectRefusal(
      callAs(thandi, 'removeMember', { householdId, memberId: kidId }),
      'notAnAdmin',
    );
  });
});

describe('setMemberRole', () => {
  beforeEach(clearFirestore);

  it('moves the role on the profile and in the membership map together', async () => {
    const { sam, thandi, householdId, helperMemberId } = await householdWithHelper();
    await callAs(sam, 'setMemberRole', { householdId, memberId: helperMemberId, role: 'admin' });

    const member = await adminDb()
      .collection('households')
      .doc(householdId)
      .collection('members')
      .doc(helperMemberId)
      .get();
    expect(member.get('role')).toBe('admin');

    const household = await adminDb().collection('households').doc(householdId).get();
    expect(membersOf(household)[thandi.uid]).toBe('admin');
  });

  it('changes an unclaimed profile without touching the map', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    const kidId = await addMember(householdId, 'Kid');
    await callAs(sam, 'setMemberRole', { householdId, memberId: kidId, role: 'helper' });

    const household = await adminDb().collection('households').doc(householdId).get();
    expect(household.get('members')).toEqual({ [sam.uid]: 'admin' });
  });

  it('refuses demoting the only admin', async () => {
    const sam = await signUp();
    const { householdId, memberId } = await createHousehold(sam);
    await expectRefusal(
      callAs(sam, 'setMemberRole', { householdId, memberId, role: 'member' }),
      'lastAdmin',
    );
  });

  it('refuses a role that is not one of the five', async () => {
    const sam = await signUp();
    const { householdId, memberId } = await createHousehold(sam);
    await expectRefusal(
      callAs(sam, 'setMemberRole', { householdId, memberId, role: 'owner' }),
      'badRequest',
    );
  });
});

describe('previewInvite', () => {
  beforeEach(clearFirestore);

  async function anInvite(): Promise<{ sam: TestUser; householdId: string; code: string }> {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    const memberId = await addMember(householdId, 'Thandi', 'helper');
    const { code } = await callAs<CreatedInvite>(sam, 'createInvite', { householdId, memberId });
    return { sam, householdId, code };
  }

  it('names the household, the profile, its role and who sent it, and spends nothing', async () => {
    const { householdId, code } = await anInvite();
    const joiner = await signUp();

    const preview = await callAs<Record<string, unknown>>(joiner, 'previewInvite', {
      code: code.toLowerCase(),
    });

    expect(preview).toEqual({
      householdName: 'The Parkers',
      memberName: 'Thandi',
      role: 'helper',
      invitedBy: 'Sam Parent',
      expiresAt: expect.any(String) as unknown,
    });
    const invite = await adminDb().collection('invites').doc(code).get();
    expect(invite.get('redeemedBy')).toBeNull();
    const household = await adminDb().collection('households').doc(householdId).get();
    expect(membersOf(household)[joiner.uid]).toBeUndefined();
  });

  it('reads a legacy member profile as a parent', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    const memberId = await addMember(householdId, 'Alex');
    const { code } = await callAs<CreatedInvite>(sam, 'createInvite', { householdId, memberId });

    const preview = await callAs<{ role: string }>(await signUp(), 'previewInvite', { code });
    expect(preview.role).toBe('parent');
  });

  it('refuses what redeeming would refuse', async () => {
    const { sam, code } = await anInvite();
    const joiner = await signUp();

    await expectRefusal(callAs(sam, 'previewInvite', { code }), 'alreadyInHousehold');
    await expectRefusal(callAs(joiner, 'previewInvite', { code: 'ABCD2345' }), 'inviteNotFound');
    await expectRefusal(callAs(joiner, 'previewInvite', { code: 'O0IL1234' }), 'inviteNotFound');

    await adminDb()
      .collection('invites')
      .doc(code)
      .update({ expiresAt: new Date(Date.now() - 1000) });
    await expectRefusal(callAs(joiner, 'previewInvite', { code }), 'inviteExpired');
  });

  it('refuses a code somebody has already used', async () => {
    const { code } = await anInvite();
    await callAs(await signUp(), 'redeemInvite', { code });

    await expectRefusal(callAs(await signUp(), 'previewInvite', { code }), 'inviteAlreadyUsed');
  });
});
