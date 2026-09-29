import { Timestamp } from 'firebase-admin/firestore';

import type { StoreVerifiers } from '../../src/subscriptions/store_verifiers';
import type { BillingStore, PurchaseState } from '../../src/subscriptions/purchase_state';
import {
  PurchaseRejected,
  StoreUnreachable,
  type VerifiedPurchase,
} from '../../src/subscriptions/verified_purchase';
import { IN_A_MONTH, MONTHLY } from '../unit/subscriptions/store_fixtures';
import { adminDb } from './emulator_harness';

/**
 * A household for the subscriptions emulator suites (subscriptions
 * ADR-0001): an admin, a parent, a helper, and a kid profile — each claimed
 * by the uid given — written straight through the admin SDK, as the
 * household callables would have left them.
 */
export interface Household {
  readonly id: string;
  readonly admin: string;
  readonly parent: string;
  readonly helper: string;
}

export async function givenAHousehold(people: {
  admin: string;
  parent?: string;
  helper?: string;
}): Promise<Household> {
  const db = adminDb();
  const household = db.collection('households').doc();
  const parent = people.parent ?? `${people.admin}-parent`;
  const helper = people.helper ?? `${people.admin}-helper`;
  await household.set({
    name: 'The Parkers',
    timeZone: 'Africa/Johannesburg',
    members: { [people.admin]: 'admin', [parent]: 'parent', [helper]: 'helper' },
    profiles: { [people.admin]: 'm-sam', [parent]: 'm-mia', [helper]: 'm-thandi' },
  });
  for (const [id, role, claimedBy] of [
    ['m-sam', 'admin', people.admin],
    ['m-mia', 'parent', parent],
    ['m-thandi', 'helper', helper],
    ['m-emma', 'kid', null],
    ['m-leo', 'kid', null],
  ] as const) {
    await household
      .collection('members')
      .doc(id)
      .set({ displayName: id, color: 'violet', role, claimedBy });
  }
  return { id: household.id, admin: people.admin, parent, helper };
}

export async function givenPremiumUntil(householdId: string, until: Date): Promise<void> {
  await adminDb()
    .doc(`households/${householdId}/entitlement/current`)
    .set({ premiumUntil: Timestamp.fromDate(until), status: 'active' });
}

export async function givenAChild(householdId: string, memberId: string): Promise<void> {
  await adminDb()
    .doc(`households/${householdId}/familyProfiles/${memberId}`)
    .set({ isChild: true }, { merge: true });
}

export async function entitlementOf(householdId: string): Promise<Record<string, unknown>> {
  const snapshot = await adminDb().doc(`households/${householdId}/entitlement/current`).get();
  return snapshot.data() ?? {};
}

export function purchaseOf(
  store: BillingStore,
  storeRef: string,
  state: Partial<PurchaseState> = {},
  replaces: string | null = null,
): VerifiedPurchase {
  return {
    store,
    storeRef,
    replaces,
    state: {
      status: 'active',
      accessUntil: IN_A_MONTH,
      willRenew: true,
      productId: MONTHLY,
      isTest: true,
      ...state,
    },
  };
}

/**
 * Stores that answer from a script: a map from what the phone sent (or the
 * store's own ref, for a refresh) to what the store says — or a rejection or
 * an outage.
 */
export class ScriptedStores implements StoreVerifiers {
  readonly asked: string[] = [];

  constructor(
    private readonly answers: Record<string, VerifiedPurchase | 'rejected' | 'unreachable'>,
  ) {}

  verifyFromDevice(_store: BillingStore, verificationData: string): Promise<VerifiedPurchase> {
    return this.answer(verificationData);
  }

  refresh(_store: BillingStore, storeRef: string): Promise<VerifiedPurchase | null> {
    return this.answer(storeRef);
  }

  private answer(key: string): Promise<VerifiedPurchase> {
    this.asked.push(key);
    const answer = this.answers[key];
    if (answer === undefined || answer === 'rejected') {
      return Promise.reject(new PurchaseRejected('scripted'));
    }
    if (answer === 'unreachable') return Promise.reject(new StoreUnreachable('scripted'));
    return Promise.resolve(answer);
  }
}
