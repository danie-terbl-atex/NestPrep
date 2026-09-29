import { adminDb, callAs, CallFailed, signUp, type TestUser } from './emulator_harness';
import { weekKeyOf } from '../../src/product_analytics/iso_week';
import { expect } from 'vitest';

/**
 * What the product-analytics emulator suites share: a household made the way
 * the app makes one, a second member who really joined, and a bounded wait for
 * a trigger (product-analytics ADR-0001).
 */

export interface CreatedHousehold {
  householdId: string;
  memberId: string;
}

export const HOUSEHOLD_NAME = 'The Parkers';
export const ADMIN_NAME = 'Sam Parent';
export const PARTNER_NAME = 'Alex Parent';
export const CHILD_NAME = 'Mia Parent';

export async function createHousehold(user: TestUser): Promise<CreatedHousehold> {
  return callAs<CreatedHousehold>(user, 'createHousehold', {
    name: HOUSEHOLD_NAME,
    timeZone: 'Africa/Johannesburg',
    adminDisplayName: ADMIN_NAME,
    adminColor: 'violet',
  });
}

export async function addMember(
  householdId: string,
  displayName: string,
  role: string,
): Promise<string> {
  const ref = adminDb().collection('households').doc(householdId).collection('members').doc();
  await ref.set({ displayName, color: 'mint', role, claimedBy: null, createdAt: new Date() });
  return ref.id;
}

/** Invites [role] and redeems it as a fresh account, so the household has a second real member. */
export async function joinAs(
  admin: TestUser,
  householdId: string,
): Promise<{ user: TestUser; memberId: string; code: string }> {
  const memberId = await addMember(householdId, PARTNER_NAME, 'member');
  const { code } = await callAs<{ code: string }>(admin, 'createInvite', { householdId, memberId });
  const user = await signUp();
  await callAs(user, 'redeemInvite', { code });
  return { user, memberId, code };
}

/**
 * A trigger runs after the write that caused it has returned, so its result is
 * waited for rather than read at once — bounded, so a trigger that never fires
 * fails the test instead of hanging it.
 */
export async function eventually<T>(
  read: () => Promise<T>,
  isReady: (value: T) => boolean,
): Promise<T> {
  const deadline = Date.now() + 15_000;
  for (;;) {
    const value = await read();
    if (isReady(value) || Date.now() > deadline) return value;
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
}

export async function ledger(path: string): Promise<Record<string, unknown> | undefined> {
  return (await adminDb().doc(path).get()).data();
}

export function thisWeek(): string {
  return weekKeyOf(new Date(), 'Africa/Johannesburg');
}

export async function expectRefusal(promise: Promise<unknown>, reason: string): Promise<void> {
  await expect(promise).rejects.toThrow(CallFailed);
  await promise.catch((error: unknown) => {
    expect(error instanceof CallFailed ? error.reason : undefined).toBe(reason);
  });
}
