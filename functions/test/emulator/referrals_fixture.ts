import { Timestamp } from 'firebase-admin/firestore';

import { adminDb, callAs, signUp, type TestUser } from './emulator_harness';
import { addMember, createHousehold } from './product_analytics_fixture';

/**
 * What the referral emulator suites share (subscriptions ADR-0002): a family
 * made the way the app makes one, somebody who really joined it in a given
 * role, and the switch set either way.
 */
export interface Family {
  readonly admin: TestUser;
  readonly householdId: string;
}

export async function aFamily(): Promise<Family> {
  const admin = await signUp();
  const { householdId } = await createHousehold(admin);
  return { admin, householdId };
}

/** Invites a profile of [role] and redeems it as [user], or a fresh account. */
export async function joins(family: Family, role: string, user?: TestUser): Promise<TestUser> {
  const memberId = await addMember(family.householdId, `A ${role}`, role);
  const { code } = await callAs<{ code: string }>(family.admin, 'createInvite', {
    householdId: family.householdId,
    memberId,
  });
  const joiner = user ?? (await signUp());
  await callAs(joiner, 'redeemInvite', { code });
  return joiner;
}

export async function codeOf(family: Family): Promise<string> {
  const { code } = await callAs<{ code: string }>(family.admin, 'ensureReferralCode', {
    householdId: family.householdId,
  });
  return code;
}

export async function redeem(family: Family, code: string, as?: TestUser): Promise<string> {
  const { qualifyBy } = await callAs<{ qualifyBy: string }>(
    as ?? family.admin,
    'redeemReferralCode',
    {
      householdId: family.householdId,
      code,
    },
  );
  return qualifyBy;
}

export async function opens(user: TestUser, family: Family): Promise<void> {
  await callAs(user, 'recordActivity', { householdId: family.householdId });
}

export async function setReferrals(isOn: boolean): Promise<void> {
  await adminDb().doc('appConfig/flags').set({ referralRewards: isOn }, { merge: true });
}

export async function read(path: string): Promise<Record<string, unknown>> {
  return (await adminDb().doc(path).get()).data() ?? {};
}

export async function grantsOf(householdId: string): Promise<Record<string, unknown>[]> {
  const found = await adminDb().collection(`households/${householdId}/premiumGrants`).get();
  return found.docs.map((doc) => doc.data());
}

export async function historyOf(householdId: string): Promise<Record<string, unknown>[]> {
  const found = await adminDb().collection(`households/${householdId}/referralHistory`).get();
  return found.docs.map((doc) => doc.data());
}

export function instant(value: unknown): Date | null {
  return value instanceof Timestamp ? value.toDate() : null;
}

export const DAY_MS = 24 * 60 * 60 * 1000;

/** Roughly [days] from now — within a minute, for instants a callable wrote. */
export function isAbout(value: unknown, days: number): boolean {
  const at = instant(value);
  if (at === null) return false;
  return Math.abs(at.getTime() - (Date.now() + days * DAY_MS)) < 60_000;
}
