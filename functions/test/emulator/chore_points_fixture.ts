import type { DocumentReference } from 'firebase-admin/firestore';

import { addDays, todayIn } from '../../src/documents/expiry_schedule';
import { adminDb, callAs, signInWithCustomToken, signUp, type TestUser } from './emulator_harness';
import { expect } from 'vitest';

import { eventually } from './product_analytics_fixture';

/**
 * What the chore-points emulator suite shares (todos ADR-0003): a family made
 * the way the app makes one, chores and ticks written in the shapes the Flutter
 * client writes, and a bounded wait for the triggers to settle.
 */

export const ZONE = 'Africa/Johannesburg';

export function today(): string {
  return todayIn(ZONE, new Date());
}

export function daysAgo(days: number): string {
  return addDays(today(), -days);
}

export interface Family {
  readonly sam: TestUser;
  readonly householdId: string;
  readonly samMember: string;
  readonly mia: string;
}

export function household(householdId: string): DocumentReference {
  return adminDb().collection('households').doc(householdId);
}

export async function addProfile(
  householdId: string,
  displayName: string,
  role: string,
): Promise<string> {
  const ref = household(householdId).collection('members').doc();
  await ref.set({ displayName, color: 'mint', role, claimedBy: null, createdAt: new Date() });
  return ref.id;
}

export async function aFamily(): Promise<Family> {
  const sam = await signUp();
  const created = await callAs<{ householdId: string; memberId: string }>(sam, 'createHousehold', {
    name: 'The Parkers',
    timeZone: ZONE,
    adminDisplayName: 'Sam',
    adminColor: 'violet',
  });
  const mia = await addProfile(created.householdId, 'Mia', 'kid');
  return { sam, householdId: created.householdId, samMember: created.memberId, mia };
}

/** A chore as the client writes one: daily from a week ago unless told otherwise. */
export async function aChore(
  family: Family,
  taskId: string,
  overrides: Record<string, unknown> = {},
): Promise<void> {
  await household(family.householdId)
    .collection('tasks')
    .doc(taskId)
    .set({
      title: 'Make your bed',
      note: null,
      dueDate: daysAgo(10),
      recurrence: { frequency: 'daily', interval: 1, weekdays: [], until: null },
      assigneeIds: [family.mia],
      createdBy: family.samMember,
      routineId: null,
      createdAt: new Date(),
      points: 5,
      needsApproval: false,
      ...overrides,
    });
}

export function completionId(taskId: string, date: string): string {
  return `${taskId}_${date}`;
}

/** A tick, keyed the way the client keys one (todos ADR-0002). */
export async function tick(
  family: Family,
  taskId: string,
  options: { date?: string; by?: string; forMember?: string } = {},
): Promise<string> {
  const date = options.date ?? today();
  const id = completionId(taskId, date);
  await household(family.householdId)
    .collection('taskCompletions')
    .doc(id)
    .set({
      taskId,
      occurrenceDate: date,
      completedBy: options.by ?? family.mia,
      completedFor: options.forMember ?? family.mia,
      completedAt: new Date(),
    });
  return id;
}

export async function untick(family: Family, id: string): Promise<void> {
  await household(family.householdId).collection('taskCompletions').doc(id).delete();
}

export async function read(
  family: Family,
  collection: string,
  id: string,
): Promise<Record<string, unknown> | undefined> {
  return (await household(family.householdId).collection(collection).doc(id).get()).data();
}

/** Waits until a document satisfies [isReady], or gives up after 15 s. */
export async function settled(
  family: Family,
  collection: string,
  id: string,
  isReady: (value: Record<string, unknown> | undefined) => boolean,
): Promise<Record<string, unknown> | undefined> {
  return eventually(() => read(family, collection, id), isReady);
}

export async function balanceOf(family: Family, memberId: string): Promise<number | undefined> {
  const value = (await read(family, 'pointBalances', memberId))?.['balance'];
  return typeof value === 'number' ? value : undefined;
}

/** The sum of a child's ledger lines — what the balance must always equal. */
export async function ledgerSum(family: Family, memberId: string): Promise<number> {
  const lines = await household(family.householdId)
    .collection('pointEntries')
    .where('memberId', '==', memberId)
    .get();
  return lines.docs.reduce((sum, line) => {
    const delta: unknown = line.get('delta');
    return sum + (typeof delta === 'number' ? delta : 0);
  }, 0);
}

/** A trigger that should *not* write needs a moment to have had its chance. */
export async function aMoment(): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, 2500));
}

/** A signed-in kid device for [memberId], paired the way a parent pairs one. */
export async function aKidDevice(family: Family, memberId: string): Promise<TestUser> {
  const { code } = await callAs<{ code: string }>(family.sam, 'createKidPairing', {
    householdId: family.householdId,
    memberId,
    label: '',
  });
  const { token } = await callAs<{ token: string }>(null, 'redeemKidPairing', { code });
  return signInWithCustomToken(token);
}

/** A second adult who really joined, in [role]. */
export async function aMember(family: Family, role: string): Promise<TestUser> {
  const memberId = await addProfile(family.householdId, 'Thandi', role);
  const { code } = await callAs<{ code: string }>(family.sam, 'createInvite', {
    householdId: family.householdId,
    memberId,
  });
  const user = await signUp();
  await callAs(user, 'redeemInvite', { code });
  return user;
}

export function status(value: Record<string, unknown> | undefined): unknown {
  return value?.['status'];
}

/** Waits for a child's balance, then checks it is the sum of their ledger. */
export async function expectBalance(
  family: Family,
  memberId: string,
  stars: number,
): Promise<void> {
  await settled(family, 'pointBalances', memberId, (value) => value?.['balance'] === stars);
  expect(await balanceOf(family, memberId)).toBe(stars);
  expect(await ledgerSum(family, memberId)).toBe(stars);
}
