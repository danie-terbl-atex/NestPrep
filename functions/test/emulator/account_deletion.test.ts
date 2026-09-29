import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import {
  adminAuth,
  adminBucket,
  adminDb,
  callAs,
  clearFirestore,
  closeAdmin,
  signUp,
} from './emulator_harness';
import {
  type Preview,
  addProfile,
  exists,
  expectRefusal,
  givenSamsDetails,
  household,
  joinAs,
  objectExists,
  pairKidDevice,
  samsHousehold,
  vaultObject,
} from './account_data_fixture';

/**
 * Delete my account, end to end over HTTP with real tokens (accounts
 * ADR-0006, `BE-14`): what the preview promises, what deleting then does to
 * each household — leave, hand over, end — and that the person's own details,
 * vault bytes, account document and Auth user are gone afterwards while the
 * household's records stay.
 */

beforeEach(clearFirestore);
afterAll(closeAdmin);

const DELETE = (
  endingHouseholdIds: string[] = [],
): { confirmation: string; endingHouseholdIds: string[] } => ({
  confirmation: 'DELETE',
  endingHouseholdIds,
});

async function userIsGone(uid: string): Promise<boolean> {
  return adminAuth()
    .getUser(uid)
    .then(
      () => false,
      () => true,
    );
}

describe('previewAccountDeletion', () => {
  it('says a household where Sam is the only adult ends, and how many people lose it', async () => {
    const h = await samsHousehold();
    const helper = await addProfile(h.householdId, 'Thandi', 'helper');
    await joinAs(h.sam, h.householdId, helper);

    const preview = await callAs<Preview>(h.sam, 'previewAccountDeletion', null);
    expect(preview.households).toEqual([
      expect.objectContaining({
        householdId: h.householdId,
        outcome: 'end',
        othersLosingAccess: 1,
        successorName: null,
      }),
    ]);
  });

  it('names the adult a household is handed to', async () => {
    const h = await samsHousehold();
    const alex = await addProfile(h.householdId, 'Alex', 'parent');
    await joinAs(h.sam, h.householdId, alex);

    const preview = await callAs<Preview>(h.sam, 'previewAccountDeletion', null);
    expect(preview.households[0]).toMatchObject({ outcome: 'handOver', successorName: 'Alex' });
  });

  it('refuses a caller who is not signed in', async () => {
    await expectRefusal(callAs(null, 'previewAccountDeletion', null), 'notSignedIn');
  });
});

describe('deleteAccount — refusals that change nothing', () => {
  it('without the typed confirmation', async () => {
    const h = await samsHousehold();
    await expectRefusal(
      callAs(h.sam, 'deleteAccount', { confirmation: 'delete me', endingHouseholdIds: [] }),
      'deletionNotConfirmed',
    );
    expect(await exists(`users/${h.sam.uid}`)).toBe(true);
  });

  it('when the households that would end are not the ones Sam agreed to', async () => {
    const h = await samsHousehold();
    // The preview said "ends"; Sam's client sent an agreement to end nothing.
    await expectRefusal(callAs(h.sam, 'deleteAccount', DELETE([])), 'deletionPlanChanged');
    expect(await exists(`households/${h.householdId}`)).toBe(true);
    expect(await userIsGone(h.sam.uid)).toBe(false);
  });

  it('from a kid device, which is a parent’s to sign out and never an account to delete', async () => {
    const h = await samsHousehold();
    const mia = await addProfile(h.householdId, 'Mia', 'kid');
    const tablet = await pairKidDevice(h.sam, h.householdId, mia);
    await expectRefusal(callAs(tablet, 'deleteAccount', DELETE()), 'kidAccount');
  });
});

describe('deleteAccount — a household that goes on', () => {
  it('hands the household to the other adult and erases only what is Sam’s', async () => {
    const h = await samsHousehold();
    const alexMember = await addProfile(h.householdId, 'Alex', 'parent');
    const alex = await joinAs(h.sam, h.householdId, alexMember);
    await givenSamsDetails(h);
    const grantToSam = `households/${h.householdId}/vaults/${alexMember}/grants/${h.sam.uid}`;
    await adminDb().doc(grantToSam).set({ memberId: h.samMemberId, grantedBy: alexMember });

    const summary = await callAs<Record<string, number>>(h.sam, 'deleteAccount', DELETE());
    expect(summary).toEqual({ householdsLeft: 0, householdsHandedOver: 1, householdsEnded: 0 });

    const home = await household(h.householdId).get();
    expect(home.get('members')).toEqual({ [alex.uid]: 'admin' });
    const alexProfile = await household(h.householdId).collection('members').doc(alexMember).get();
    expect(alexProfile.get('role')).toBe('admin');

    const samProfile = await household(h.householdId)
      .collection('members')
      .doc(h.samMemberId)
      .get();
    expect(samProfile.exists).toBe(true);
    expect(samProfile.get('claimedBy')).toBeNull();
    expect(samProfile.get('birthday')).toBeNull();

    const base = `households/${h.householdId}`;
    for (const detail of ['familyProfiles', 'memberHealth', 'memberLocations']) {
      expect(await exists(`${base}/${detail}/${h.samMemberId}`), detail).toBe(false);
    }
    expect(await exists(`${base}/vaults/${h.samMemberId}/vaultDocuments/passport`)).toBe(false);
    expect(await objectExists(vaultObject(h.householdId, h.samMemberId, 'passport'))).toBe(false);
    expect(await exists(grantToSam)).toBe(false);
    // The household's own record of what Sam added stays.
    expect(await exists(`${base}/groceryItems/milk`)).toBe(true);

    expect(await exists(`users/${h.sam.uid}`)).toBe(false);
    expect(await userIsGone(h.sam.uid)).toBe(true);
    const ledger = await adminDb().doc(`accountDeletions/${h.sam.uid}`).get();
    expect(ledger.get('completedAt')).not.toBeNull();
    expect(ledger.get('via')).toBe('app');
  });

  it('a parent who is not the admin simply leaves, and the admin is untouched', async () => {
    const h = await samsHousehold();
    const alexMember = await addProfile(h.householdId, 'Alex', 'parent');
    const alex = await joinAs(h.sam, h.householdId, alexMember);

    const summary = await callAs<Record<string, number>>(alex, 'deleteAccount', DELETE());
    expect(summary).toMatchObject({ householdsLeft: 1 });
    const home = await household(h.householdId).get();
    expect(home.get('members')).toEqual({ [h.sam.uid]: 'admin' });
    expect(await userIsGone(alex.uid)).toBe(true);
  });
});

describe('deleteAccount — a household that ends', () => {
  it('removes the household, its bytes, its codes and devices, and takes it off everyone else', async () => {
    const h = await samsHousehold();
    const thandiMember = await addProfile(h.householdId, 'Thandi', 'helper');
    const thandi = await joinAs(h.sam, h.householdId, thandiMember);
    const mia = await addProfile(h.householdId, 'Mia', 'kid');
    const tablet = await pairKidDevice(h.sam, h.householdId, mia);
    await givenSamsDetails(h);
    const pending = await addProfile(h.householdId, 'Gran', 'parent');
    await callAs(h.sam, 'createInvite', { householdId: h.householdId, memberId: pending });
    const purchase = adminDb().collection('storePurchases').doc('p1');
    await purchase.set({
      store: 'playStore',
      storeRef: 'purchase-token',
      householdId: h.householdId,
      linkedByUid: h.sam.uid,
      linkedByMemberId: h.samMemberId,
    });
    const sharedDocument = `households/${h.householdId}/documents/lease`;
    await adminBucket().file(sharedDocument).save('%PDF-');

    const summary = await callAs<Record<string, number>>(
      h.sam,
      'deleteAccount',
      DELETE([h.householdId]),
    );
    expect(summary).toMatchObject({ householdsEnded: 1 });

    expect(await exists(`households/${h.householdId}`)).toBe(false);
    const leftovers = await household(h.householdId).collection('members').limit(1).get();
    expect(leftovers.empty).toBe(true);
    expect(await objectExists(sharedDocument)).toBe(false);
    const invites = await adminDb()
      .collection('invites')
      .where('householdId', '==', h.householdId)
      .get();
    expect(invites.empty).toBe(true);

    const thandiAccount = await adminDb().doc(`users/${thandi.uid}`).get();
    expect(thandiAccount.get('householdIds')).toEqual([]);
    expect(thandiAccount.get('activeHouseholdId')).toBeNull();
    expect(await userIsGone(tablet.uid)).toBe(true);
    expect(await userIsGone(thandi.uid)).toBe(false);

    const unlinked = await purchase.get();
    expect(unlinked.get('householdId')).toBeNull();
    expect(unlinked.get('linkedByUid')).toBeNull();
    expect(await userIsGone(h.sam.uid)).toBe(true);
  });

  it('is safe to ask again: a second deletion of a half-erased account finishes the job', async () => {
    const h = await samsHousehold();
    const second = await signUp();
    // Sam's account lists a household that has already gone — what an
    // interrupted erasure leaves behind.
    await adminDb()
      .doc(`users/${second.uid}`)
      .set({ displayName: 'Jo', householdIds: ['gone'], activeHouseholdId: 'gone' });
    const summary = await callAs<Record<string, number>>(second, 'deleteAccount', DELETE());
    expect(summary).toEqual({ householdsLeft: 0, householdsHandedOver: 0, householdsEnded: 0 });
    expect(await userIsGone(second.uid)).toBe(true);
    expect(await exists(`households/${h.householdId}`)).toBe(true);
  });
});
