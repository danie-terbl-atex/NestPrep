import { Timestamp, type DocumentReference } from 'firebase-admin/firestore';
import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import {
  CallFailed,
  adminAuth,
  adminDb,
  callAs,
  claimsOf,
  clearFirestore,
  closeAdmin,
  signInWithCustomToken,
  signUp,
  type TestUser,
} from './emulator_harness';

/**
 * Kid sign-in end to end (accounts ADR-0003): a parent makes a code, a signed-out
 * device trades it for a custom token, signs in with it against the Auth
 * emulator, and is then that kid profile — and nothing a household callable
 * will serve. Every refusal is checked by its reason, over HTTP (`BE-14`).
 */

interface Created {
  householdId: string;
  memberId: string;
}
interface Pairing {
  code: string;
  expiresAt: string;
}

const household = (id: string): DocumentReference => adminDb().collection('households').doc(id);

async function createHousehold(parent: TestUser): Promise<Created> {
  return callAs<Created>(parent, 'createHousehold', {
    name: 'The Parkers',
    timeZone: 'Africa/Johannesburg',
    adminDisplayName: 'Sam',
    adminColor: 'violet',
  });
}

async function addProfile(
  householdId: string,
  displayName: string,
  role = 'kid',
  claimedBy: string | null = null,
): Promise<string> {
  const ref = household(householdId).collection('members').doc();
  await ref.set({ displayName, color: 'mint', role, claimedBy, createdAt: new Date() });
  return ref.id;
}

async function expectRefusal(promise: Promise<unknown>, reason: string): Promise<void> {
  const error: unknown = await promise.then(
    () => null,
    (caught: unknown) => caught,
  );
  expect(error).toBeInstanceOf(CallFailed);
  expect((error as CallFailed).reason).toBe(reason);
}

/** A parent, their household, and one kid profile nobody has claimed. */
async function aFamily(): Promise<{ sam: TestUser; householdId: string; mia: string }> {
  const sam = await signUp();
  const { householdId } = await createHousehold(sam);
  const mia = await addProfile(householdId, 'Mia');
  return { sam, householdId, mia };
}

async function pairingFor(
  sam: TestUser,
  householdId: string,
  memberId: string,
  label = '',
): Promise<Pairing> {
  return callAs<Pairing>(sam, 'createKidPairing', { householdId, memberId, label });
}

/** The whole kid side: redeem the code and sign in with what comes back. */
async function pairDevice(code: string): Promise<TestUser> {
  const { token } = await callAs<{ token: string }>(null, 'redeemKidPairing', { code });
  return signInWithCustomToken(token);
}

beforeEach(clearFirestore);
afterAll(closeAdmin);

describe('createKidPairing', () => {
  it('gives an admin a six-character code that lives ten minutes', async () => {
    const { sam, householdId, mia } = await aFamily();
    const before = Date.now();
    const pairing = await pairingFor(sam, householdId, mia, ' Tablet ');
    const after = Date.now();

    expect(pairing.code).toMatch(/^[2-9A-HJKMNP-Z]{6}$/);
    // The Function stamps "now + ten minutes" somewhere inside the call, so the
    // expiry sits between ten minutes after it was asked for and ten minutes
    // after it answered — however long a loaded machine took over the call.
    // The same clock on both sides; the second of slack is ISO rounding.
    const tenMinutes = 10 * 60 * 1000;
    const expiresAt = Date.parse(pairing.expiresAt);
    expect(expiresAt).toBeGreaterThanOrEqual(before + tenMinutes - 1000);
    expect(expiresAt).toBeLessThanOrEqual(after + tenMinutes + 1000);

    const stored = await adminDb().collection('kidPairings').doc(pairing.code).get();
    expect(stored.get('memberId')).toBe(mia);
    expect(stored.get('label')).toBe('Tablet');
    expect(stored.get('createdBy')).toBe(sam.uid);
  });

  it('retires the code before when a parent makes another', async () => {
    const { sam, householdId, mia } = await aFamily();
    const first = await pairingFor(sam, householdId, mia);
    const second = await pairingFor(sam, householdId, mia);
    expect((await adminDb().collection('kidPairings').doc(first.code).get()).exists).toBe(false);
    expect((await adminDb().collection('kidPairings').doc(second.code).get()).exists).toBe(true);
  });

  it('refuses anybody who is not an admin of the household', async () => {
    const { householdId, mia } = await aFamily();
    const thandi = await signUp();
    await household(householdId).update({ [`members.${thandi.uid}`]: 'helper' });
    await expectRefusal(pairingFor(thandi, householdId, mia), 'notAnAdmin');
    await expectRefusal(pairingFor(await signUp(), householdId, mia), 'notAnAdmin');
    await expectRefusal(
      callAs(null, 'createKidPairing', { householdId, memberId: mia }),
      'notSignedIn',
    );
  });

  it('refuses a profile that is not a child nobody has claimed', async () => {
    const { sam, householdId } = await aFamily();
    const teen = await addProfile(householdId, 'Teen', 'kid', 'uid-teen');
    const helper = await addProfile(householdId, 'Thandi', 'helper');
    // `member` is an adult now — read as a parent (accounts ADR-0004).
    const grandad = await addProfile(householdId, 'Grandad', 'member');
    await expectRefusal(pairingFor(sam, householdId, teen), 'notEligible');
    await expectRefusal(pairingFor(sam, householdId, helper), 'notEligible');
    await expectRefusal(pairingFor(sam, householdId, grandad), 'notEligible');
    await expectRefusal(pairingFor(sam, householdId, 'm-nobody'), 'memberNotFound');
  });

  it('refuses a sixth device for one profile', async () => {
    const { sam, householdId, mia } = await aFamily();
    for (let index = 0; index < 5; index += 1) {
      await household(householdId)
        .collection('kidDevices')
        .doc(`kid_seeded${String(index)}`)
        .set({ memberId: mia, label: '', pairedBy: sam.uid, pairedAt: new Date() });
    }
    await expectRefusal(pairingFor(sam, householdId, mia), 'tooManyDevices');
  });
});

describe('redeemKidPairing', () => {
  it('signs a device in as the kid profile, with no email and no password', async () => {
    const { sam, householdId, mia } = await aFamily();
    const { code } = await pairingFor(sam, householdId, mia, 'Tablet');

    const tablet = await pairDevice(code);

    expect(tablet.uid).toMatch(/^kid_/);
    expect(claimsOf(tablet.idToken)['kidProfile']).toEqual({ householdId, memberId: mia });
    const home = await household(householdId).get();
    expect(home.get('kids')).toEqual({ [tablet.uid]: mia });
    expect(home.get('members')).not.toHaveProperty(tablet.uid);

    const device = await household(householdId).collection('kidDevices').doc(tablet.uid).get();
    expect(device.get('memberId')).toBe(mia);
    expect(device.get('label')).toBe('Tablet');
    expect(device.get('pairedBy')).toBe(sam.uid);
    expect((await adminAuth().getUser(tablet.uid)).email).toBeUndefined();
  });

  it('works once: the code is spent by the device that used it', async () => {
    const { sam, householdId, mia } = await aFamily();
    const { code } = await pairingFor(sam, householdId, mia);
    await pairDevice(code);
    await expectRefusal(callAs(null, 'redeemKidPairing', { code }), 'codeNotFound');
  });

  it('accepts the code however a child types it', async () => {
    const { sam, householdId, mia } = await aFamily();
    const { code } = await pairingFor(sam, householdId, mia);
    const tablet = await pairDevice(` ${code.toLowerCase()} `);
    expect(claimsOf(tablet.idToken)['kidProfile']).toEqual({ householdId, memberId: mia });
  });

  it('refuses a code that is not one, or is no longer one', async () => {
    const { sam, householdId, mia } = await aFamily();
    await expectRefusal(callAs(null, 'redeemKidPairing', { code: 'ZZZZZZ' }), 'codeNotFound');
    await expectRefusal(callAs(null, 'redeemKidPairing', { code: 'O0O0O0' }), 'codeNotFound');

    const { code } = await pairingFor(sam, householdId, mia);
    await adminDb()
      .collection('kidPairings')
      .doc(code)
      .update({ expiresAt: Timestamp.fromMillis(Date.now() - 1000) });
    await expectRefusal(callAs(null, 'redeemKidPairing', { code }), 'codeExpired');
  });

  it('refuses when the profile was claimed after the code was made, and leaves nobody behind', async () => {
    const { sam, householdId, mia } = await aFamily();
    const { code } = await pairingFor(sam, householdId, mia);
    await household(householdId).collection('members').doc(mia).update({ claimedBy: 'uid-teen' });

    await expectRefusal(callAs(null, 'redeemKidPairing', { code }), 'notEligible');

    expect((await household(householdId).get()).get('kids')).toBeUndefined();
    const kidUsers = (await adminAuth().listUsers(1000)).users.filter((user) =>
      user.uid.startsWith('kid_'),
    );
    const paired = await household(householdId).collection('kidDevices').get();
    expect(paired.empty).toBe(true);
    // Any kid user still in Auth belongs to a household's device list — the
    // one this refusal minted was closed again (`BE-06`).
    for (const user of kidUsers) {
      expect(user.customClaims?.['kidProfile']).not.toEqual({ householdId, memberId: mia });
    }
  });
});

describe('a kid device is refused every household callable', () => {
  it('cannot create a household, join one, invite, pair or remove anybody', async () => {
    const { sam, householdId, mia } = await aFamily();
    const tablet = await pairDevice((await pairingFor(sam, householdId, mia)).code);
    const leo = await addProfile(householdId, 'Leo');

    for (const [name, body] of [
      [
        'createHousehold',
        { name: 'Mia HQ', timeZone: 'UTC', adminDisplayName: 'Mia', adminColor: 'pink' },
      ],
      ['redeemInvite', { code: 'ABCD2345' }],
      ['createInvite', { householdId, memberId: leo }],
      ['createKidPairing', { householdId, memberId: leo }],
      ['removeMember', { householdId, memberId: leo }],
      ['setMemberRole', { householdId, memberId: mia, role: 'admin' }],
      ['leaveHousehold', { householdId }],
      ['syncDocumentAccess', {}],
    ] as const) {
      await expectRefusal(callAs(tablet, name, body), 'kidAccount');
    }
    expect((await household(householdId).get()).get('members')).toEqual({ [sam.uid]: 'admin' });
  });
});

describe('ending a kid sign-in', () => {
  it('revokeKidDevice signs one device out and leaves the other', async () => {
    const { sam, householdId, mia } = await aFamily();
    const tablet = await pairDevice((await pairingFor(sam, householdId, mia)).code);
    const phone = await pairDevice((await pairingFor(sam, householdId, mia)).code);

    await callAs(sam, 'revokeKidDevice', { householdId, deviceUid: tablet.uid });

    expect((await household(householdId).get()).get('kids')).toEqual({ [phone.uid]: mia });
    const devices = await household(householdId).collection('kidDevices').get();
    expect(devices.docs.map((device) => device.id)).toEqual([phone.uid]);
    await expect(adminAuth().getUser(tablet.uid)).rejects.toThrow();
    await expect(adminAuth().getUser(phone.uid)).resolves.toBeDefined();
  });

  it('revokeKidDevice refuses a non-admin and a device that is not there', async () => {
    const { sam, householdId, mia } = await aFamily();
    const tablet = await pairDevice((await pairingFor(sam, householdId, mia)).code);
    await expectRefusal(
      callAs(await signUp(), 'revokeKidDevice', { householdId, deviceUid: tablet.uid }),
      'notAnAdmin',
    );
    await expectRefusal(
      callAs(tablet, 'revokeKidDevice', { householdId, deviceUid: tablet.uid }),
      'kidAccount',
    );
    await expectRefusal(
      callAs(sam, 'revokeKidDevice', { householdId, deviceUid: 'kid_nothing' }),
      'deviceNotFound',
    );
  });

  it('resetKidSignIn signs every device out and retires a live code', async () => {
    const { sam, householdId, mia } = await aFamily();
    await pairDevice((await pairingFor(sam, householdId, mia)).code);
    await pairDevice((await pairingFor(sam, householdId, mia)).code);
    const waiting = await pairingFor(sam, householdId, mia);

    const result = await callAs<{ revoked: number }>(sam, 'resetKidSignIn', {
      householdId,
      memberId: mia,
    });

    expect(result.revoked).toBe(2);
    expect((await household(householdId).get()).get('kids')).toEqual({});
    expect((await household(householdId).collection('kidDevices').get()).empty).toBe(true);
    await expectRefusal(callAs(null, 'redeemKidPairing', { code: waiting.code }), 'codeNotFound');
    await expectRefusal(
      callAs(await signUp(), 'resetKidSignIn', { householdId, memberId: mia }),
      'notAnAdmin',
    );
  });

  it('cancelKidPairing retires a code nobody used, once, and only its own', async () => {
    const { sam, householdId, mia } = await aFamily();
    const { code } = await pairingFor(sam, householdId, mia);

    const other = await aFamily();
    const theirs = await pairingFor(other.sam, other.householdId, other.mia);
    expect(
      await callAs<{ cancelled: boolean }>(sam, 'cancelKidPairing', {
        householdId,
        code: theirs.code,
      }),
    ).toEqual({ cancelled: false });

    expect(await callAs(sam, 'cancelKidPairing', { householdId, code })).toEqual({
      cancelled: true,
    });
    expect(await callAs(sam, 'cancelKidPairing', { householdId, code })).toEqual({
      cancelled: false,
    });
    await expectRefusal(callAs(null, 'redeemKidPairing', { code }), 'codeNotFound');
    await pairDevice(theirs.code);
  });

  it('removing the profile signs its devices out with it', async () => {
    const { sam, householdId, mia } = await aFamily();
    const tablet = await pairDevice((await pairingFor(sam, householdId, mia)).code);

    await callAs(sam, 'removeMember', { householdId, memberId: mia });

    expect((await household(householdId).get()).get('kids')).toEqual({});
    expect((await household(householdId).collection('kidDevices').get()).empty).toBe(true);
    await expect(adminAuth().getUser(tablet.uid)).rejects.toThrow();
  });
});
