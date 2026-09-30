import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import {
  CallFailed,
  adminDb,
  callAs,
  clearFirestore,
  closeAdmin,
  signUp,
  signUpUnverified,
  type TestUser,
} from './emulator_harness';

interface CreatedHousehold {
  householdId: string;
  memberId: string;
}
interface CreatedInvite {
  code: string;
  expiresAt: string;
}

async function createHousehold(user: TestUser, name = 'The Parkers'): Promise<CreatedHousehold> {
  return callAs<CreatedHousehold>(user, 'createHousehold', {
    name,
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

function reasonOf(error: unknown): string | undefined {
  return error instanceof CallFailed ? error.reason : undefined;
}

async function expectRefusal(promise: Promise<unknown>, reason: string): Promise<void> {
  await expect(promise).rejects.toThrow(CallFailed);
  await promise.catch((error: unknown) => {
    expect(reasonOf(error)).toBe(reason);
  });
}

describe('createHousehold', () => {
  beforeEach(clearFirestore);
  afterAll(closeAdmin);

  it('creates a household whose creator is already an admin and already claimed', async () => {
    const sam = await signUp();
    const { householdId, memberId } = await createHousehold(sam);

    const household = await adminDb().collection('households').doc(householdId).get();
    expect(household.get('name')).toBe('The Parkers');
    expect(household.get('timeZone')).toBe('Africa/Johannesburg');
    expect(household.get('members')).toEqual({ [sam.uid]: 'admin' });

    const member = await adminDb()
      .collection('households')
      .doc(householdId)
      .collection('members')
      .doc(memberId)
      .get();
    expect(member.get('role')).toBe('admin');
    expect(member.get('claimedBy')).toBe(sam.uid);

    const account = await adminDb().collection('users').doc(sam.uid).get();
    expect(account.get('householdIds')).toEqual([householdId]);
    expect(account.get('activeHouseholdId')).toBe(householdId);
  });

  it('refuses a caller who is not signed in', async () => {
    await expectRefusal(
      callAs(null, 'createHousehold', {
        name: 'The Parkers',
        timeZone: 'Africa/Johannesburg',
        adminDisplayName: 'Sam',
        adminColor: 'violet',
      }),
      'notSignedIn',
    );
  });

  it('refuses a body it cannot parse', async () => {
    const sam = await signUp();
    await expectRefusal(callAs(sam, 'createHousehold', { name: '' }), 'badRequest');
    await expectRefusal(
      callAs(sam, 'createHousehold', {
        name: 'The Parkers',
        timeZone: 'not a zone!',
        adminDisplayName: 'Sam',
        adminColor: 'violet',
      }),
      'badRequest',
    );
  });

  it('lets one account belong to two households', async () => {
    const sam = await signUp();
    const first = await createHousehold(sam, 'The Parkers');
    const second = await createHousehold(sam, 'The Cottage');
    const account = await adminDb().collection('users').doc(sam.uid).get();
    expect(account.get('householdIds')).toEqual([first.householdId, second.householdId]);
    expect(account.get('activeHouseholdId')).toBe(second.householdId);
  });
});

describe('createInvite', () => {
  beforeEach(clearFirestore);

  it('issues a single-use code with a seven-day expiry for an unclaimed profile', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    const memberId = await addMember(householdId, 'Thandi', 'helper');

    const invite = await callAs<CreatedInvite>(sam, 'createInvite', { householdId, memberId });
    expect(invite.code).toMatch(/^[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{8}$/);

    const days = (new Date(invite.expiresAt).getTime() - Date.now()) / 86_400_000;
    expect(days).toBeGreaterThan(6.9);
    expect(days).toBeLessThan(7.1);

    const stored = await adminDb().collection('invites').doc(invite.code).get();
    expect(stored.get('householdId')).toBe(householdId);
    expect(stored.get('redeemedBy')).toBeNull();
  });

  it('refuses a member of the household who is not an admin', async () => {
    const sam = await signUp();
    const helper = await signUp();
    const { householdId } = await createHousehold(sam);
    const helperMemberId = await addMember(householdId, 'Thandi', 'helper');
    const invite = await callAs<CreatedInvite>(sam, 'createInvite', {
      householdId,
      memberId: helperMemberId,
    });
    await callAs(helper, 'redeemInvite', { code: invite.code });

    const kidId = await addMember(householdId, 'Kid');
    await expectRefusal(
      callAs(helper, 'createInvite', { householdId, memberId: kidId }),
      'notAnAdmin',
    );
  });

  it('refuses a stranger to the household', async () => {
    const sam = await signUp();
    const stranger = await signUp();
    const { householdId } = await createHousehold(sam);
    const memberId = await addMember(householdId, 'Kid');
    await expectRefusal(callAs(stranger, 'createInvite', { householdId, memberId }), 'notAnAdmin');
  });

  it('refuses a profile somebody has already claimed', async () => {
    const sam = await signUp();
    const { householdId, memberId } = await createHousehold(sam);
    await expectRefusal(
      callAs(sam, 'createInvite', { householdId, memberId }),
      'memberAlreadyClaimed',
    );
  });

  it('refuses a profile that is not there', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    await expectRefusal(
      callAs(sam, 'createInvite', { householdId, memberId: 'nobody' }),
      'memberNotFound',
    );
  });
});

/**
 * No gate between an account and its first household (accounts ADR-0007,
 * which lifted ADR-0002's verified-address rule): an address nobody has
 * confirmed yet creates and joins like any other.
 */
describe('an address nobody has confirmed', () => {
  it('can create a household', async () => {
    await expect(createHousehold(await signUpUnverified())).resolves.toBeDefined();
  });
});
