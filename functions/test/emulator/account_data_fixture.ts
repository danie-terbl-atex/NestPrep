import { Timestamp, type DocumentReference } from 'firebase-admin/firestore';
import { expect } from 'vitest';

import {
  CallFailed,
  adminBucket,
  adminDb,
  callAs,
  signInWithCustomToken,
  signUp,
  type TestUser,
} from './emulator_harness';

/**
 * The households the account-data suite deletes and exports (accounts
 * ADR-0006): Sam's, with whichever other people a test needs, and Sam's own
 * details spread across it the way the app writes them.
 */

export interface Household {
  readonly sam: TestUser;
  readonly householdId: string;
  readonly samMemberId: string;
}

export const household = (id: string): DocumentReference =>
  adminDb().collection('households').doc(id);

export async function samsHousehold(): Promise<Household> {
  const sam = await signUp();
  const created = await callAs<{ householdId: string; memberId: string }>(sam, 'createHousehold', {
    name: 'The Parkers',
    timeZone: 'Africa/Johannesburg',
    adminDisplayName: 'Sam',
    adminColor: 'violet',
  });
  return { sam, householdId: created.householdId, samMemberId: created.memberId };
}

export async function addProfile(
  householdId: string,
  displayName: string,
  role: string,
  createdAt = new Date(),
): Promise<string> {
  const ref = household(householdId).collection('members').doc();
  await ref.set({ displayName, color: 'mint', role, claimedBy: null, createdAt });
  return ref.id;
}

/** A second account joins as the profile, through the real invite. */
export async function joinAs(
  admin: TestUser,
  householdId: string,
  memberId: string,
): Promise<TestUser> {
  const person = await signUp();
  const invite = await callAs<{ code: string }>(admin, 'createInvite', { householdId, memberId });
  await callAs(person, 'redeemInvite', { code: invite.code });
  return person;
}

/** A kid device paired for a kid profile, as the parent's screen and the tablet do it. */
export async function pairKidDevice(
  admin: TestUser,
  householdId: string,
  memberId: string,
): Promise<TestUser> {
  const { code } = await callAs<{ code: string }>(admin, 'createKidPairing', {
    householdId,
    memberId,
    label: 'Tablet',
  });
  const { token } = await callAs<{ token: string }>(null, 'redeemKidPairing', { code });
  return signInWithCustomToken(token);
}

export function vaultObject(householdId: string, memberId: string, documentId: string): string {
  return `households/${householdId}/vaults/${memberId}/${documentId}`;
}

/** Sam's details, medication, position and a vault document with its bytes. */
export async function givenSamsDetails(h: Household): Promise<void> {
  const { householdId, samMemberId } = h;
  const home = household(householdId);
  await home.collection('members').doc(samMemberId).update({ birthday: '1988-04-02' });
  await home
    .collection('familyProfiles')
    .doc(samMemberId)
    .set({ likes: ['coffee'] });
  await home.collection('memberHealth').doc(samMemberId).set({ medication: [] });
  await home.collection('memberLocations').doc(samMemberId).set({ sharingUntil: Timestamp.now() });
  await home
    .collection('vaults')
    .doc(samMemberId)
    .collection('vaultDocuments')
    .doc('passport')
    .set({
      name: 'Passport',
      contentType: 'application/pdf',
      sizeBytes: 5,
      uploadedBy: samMemberId,
      uploadedAt: Timestamp.now(),
    });
  await adminBucket()
    .file(vaultObject(householdId, samMemberId, 'passport'))
    .save('%PDF-', { contentType: 'application/pdf' });
  await home.collection('groceryItems').doc('milk').set({ name: 'Milk', addedBy: samMemberId });
}

export async function exists(path: string): Promise<boolean> {
  return (await adminDb().doc(path).get()).exists;
}

export async function objectExists(path: string): Promise<boolean> {
  const [present] = await adminBucket().file(path).exists();
  return present;
}

export async function expectRefusal(promise: Promise<unknown>, reason: string): Promise<void> {
  const error: unknown = await promise.then(
    () => null,
    (caught: unknown) => caught,
  );
  expect(error).toBeInstanceOf(CallFailed);
  expect(error instanceof CallFailed ? error.reason : undefined).toBe(reason);
}

export interface Preview {
  renewingSubscriptions: number;
  households: {
    householdId: string;
    name: string;
    outcome: 'leave' | 'handOver' | 'end';
    successorName: string | null;
    othersLosingAccess: number;
    hasPremium: boolean;
  }[];
}
