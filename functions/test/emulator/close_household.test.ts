import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import { linkedHomes, mirrorOf } from './coparent_fixture';
import {
  adminAuth,
  adminBucket,
  adminDb,
  callAs,
  clearFirestore,
  closeAdmin,
} from './emulator_harness';
import {
  addProfile,
  exists,
  expectRefusal,
  household,
  joinAs,
  objectExists,
  pairKidDevice,
  samsHousehold,
} from './account_data_fixture';

/**
 * Close household, end to end over HTTP with real tokens (household
 * ADR-0007): the last adult ends the household with everything in it and
 * keeps their account; anybody else, or a household somebody could still
 * run, is refused and nothing changes.
 */

beforeEach(clearFirestore);
afterAll(closeAdmin);

const CLOSE = (householdId: string): { householdId: string; confirmation: string } => ({
  householdId,
  confirmation: 'CLOSE',
});

async function userIsGone(uid: string): Promise<boolean> {
  return adminAuth()
    .getUser(uid)
    .then(
      () => false,
      () => true,
    );
}

describe('closeHousehold — the last adult closes it', () => {
  it('ends the household, its bytes, codes and devices, and keeps Sam’s account', async () => {
    const h = await samsHousehold();
    const thandi = await joinAs(
      h.sam,
      h.householdId,
      await addProfile(h.householdId, 'Thandi', 'helper'),
    );
    const tablet = await pairKidDevice(
      h.sam,
      h.householdId,
      await addProfile(h.householdId, 'Mia', 'kid'),
    );
    const pending = await addProfile(h.householdId, 'Gran', 'parent');
    await callAs(h.sam, 'createInvite', { householdId: h.householdId, memberId: pending });
    const sharedDocument = `households/${h.householdId}/documents/lease`;
    await adminBucket().file(sharedDocument).save('%PDF-');

    await callAs(h.sam, 'closeHousehold', CLOSE(h.householdId));

    expect(await exists(`households/${h.householdId}`)).toBe(false);
    const leftovers = await household(h.householdId).collection('members').limit(1).get();
    expect(leftovers.empty).toBe(true);
    expect(await objectExists(sharedDocument)).toBe(false);
    const invites = await adminDb()
      .collection('invites')
      .where('householdId', '==', h.householdId)
      .get();
    expect(invites.empty).toBe(true);
    expect(await userIsGone(tablet.uid)).toBe(true);

    const thandiAccount = await adminDb().doc(`users/${thandi.uid}`).get();
    expect(thandiAccount.get('householdIds')).toEqual([]);

    // Sam keeps the account, now in no household — the app opens on the
    // start-or-join screen, and Delete my account is still there.
    const samAccount = await adminDb().doc(`users/${h.sam.uid}`).get();
    expect(samAccount.get('householdIds')).toEqual([]);
    expect(samAccount.get('activeHouseholdId')).toBeNull();
    expect(await userIsGone(h.sam.uid)).toBe(false);
  });

  it('a household with nobody else in it closes too', async () => {
    const h = await samsHousehold();
    await callAs(h.sam, 'closeHousehold', CLOSE(h.householdId));
    expect(await exists(`households/${h.householdId}`)).toBe(false);
  });

  it('is safe to ask again once the household has gone', async () => {
    const h = await samsHousehold();
    await callAs(h.sam, 'closeHousehold', CLOSE(h.householdId));
    // An interrupted close leaves the household listed on Sam's account.
    await adminDb()
      .doc(`users/${h.sam.uid}`)
      .update({ householdIds: [h.householdId], activeHouseholdId: h.householdId });

    await callAs(h.sam, 'closeHousehold', CLOSE(h.householdId));
    const samAccount = await adminDb().doc(`users/${h.sam.uid}`).get();
    expect(samAccount.get('householdIds')).toEqual([]);
  });

  it('ends a child-in-two-homes link, and the other home keeps its side as ended', async () => {
    // Dad's home is Dad and a carer, so Dad is its last adult.
    const homes = await linkedHomes();
    await callAs(homes.dad.sam, 'closeHousehold', CLOSE(homes.dad.householdId));

    const authority = await adminDb().doc(`coParentLinks/${homes.linkId}`).get();
    expect(authority.get('status')).toBe('ended');
    const mumsSide = await mirrorOf(homes.mum.householdId, homes.linkId);
    expect(mumsSide).toMatchObject({ status: 'ended', endedBySide: 'b' });
    expect(await exists(`households/${homes.mum.householdId}`)).toBe(true);
  });
});

describe('closeHousehold — refusals that change nothing', () => {
  it('without the typed confirmation', async () => {
    const h = await samsHousehold();
    await expectRefusal(
      callAs(h.sam, 'closeHousehold', { householdId: h.householdId, confirmation: 'close it' }),
      'closeNotConfirmed',
    );
    expect(await exists(`households/${h.householdId}`)).toBe(true);
  });

  it('while another parent has joined, who could run it', async () => {
    const h = await samsHousehold();
    await joinAs(h.sam, h.householdId, await addProfile(h.householdId, 'Alex', 'parent'));
    await expectRefusal(callAs(h.sam, 'closeHousehold', CLOSE(h.householdId)), 'otherAdultsRemain');
    expect(await exists(`households/${h.householdId}`)).toBe(true);
  });

  it('for a parent who is not the admin', async () => {
    const h = await samsHousehold();
    const alex = await joinAs(
      h.sam,
      h.householdId,
      await addProfile(h.householdId, 'Alex', 'parent'),
    );
    await expectRefusal(callAs(alex, 'closeHousehold', CLOSE(h.householdId)), 'notAnAdmin');
  });

  it('for somebody not in the household', async () => {
    const h = await samsHousehold();
    const stranger = await samsHousehold();
    await expectRefusal(callAs(stranger.sam, 'closeHousehold', CLOSE(h.householdId)), 'notAMember');
    expect(await exists(`households/${h.householdId}`)).toBe(true);
  });

  it('from a kid device', async () => {
    const h = await samsHousehold();
    const tablet = await pairKidDevice(
      h.sam,
      h.householdId,
      await addProfile(h.householdId, 'Mia', 'kid'),
    );
    await expectRefusal(callAs(tablet, 'closeHousehold', CLOSE(h.householdId)), 'kidAccount');
  });
});
