import { hash } from 'node:crypto';

import {
  type DocumentReference,
  type Firestore,
  Timestamp,
  type Transaction,
} from 'firebase-admin/firestore';
import { z } from 'zod';

import { householdRef } from '../household/documents';
import type { Entitlement } from './entitlement';
import { BILLING_STORES, type BillingStore, PLANS, PURCHASE_STATUSES } from './purchase_state';

/**
 * Where subscriptions keep what they know (subscriptions ADR-0001):
 *
 * - `households/{h}/entitlement/current` — what the household may do, read
 *   by everybody in it and by the rules; written only here.
 * - `households/{h}/entitlement/freeChild` — `{ memberId }`, the one child
 *   the free tier plans for (lunch-box ADR-0009); kept by `setChildProfile`,
 *   read by the rules and the app, written only here.
 * - `storePurchases/{key}` — one document per store subscription, keyed by a
 *   hash of the store and its own id; the purchase token or original
 *   transaction id, the household it gives premium to and who linked it.
 *   No client reads or writes it: a purchase token is the store's, not ours
 *   to hand around.
 */
export const ENTITLEMENT = 'entitlement';
export const CURRENT = 'current';
export const FREE_CHILD = 'freeChild';
export const STORE_PURCHASES = 'storePurchases';

/** How many subscriptions one household's entitlement is read from, at most. */
export const PURCHASES_PER_HOUSEHOLD = 20;

export function entitlementRef(store: Firestore, householdId: string): DocumentReference {
  return householdRef(store, householdId).collection(ENTITLEMENT).doc(CURRENT);
}

export function freeChildRef(store: Firestore, householdId: string): DocumentReference {
  return householdRef(store, householdId).collection(ENTITLEMENT).doc(FREE_CHILD);
}

export function purchaseKey(billingStore: BillingStore, storeRef: string): string {
  return hash('sha256', `${billingStore}:${storeRef}`, 'hex');
}

export function storePurchaseRef(
  store: Firestore,
  billingStore: BillingStore,
  storeRef: string,
): DocumentReference {
  return store.collection(STORE_PURCHASES).doc(purchaseKey(billingStore, storeRef));
}

const timestamp = z.instanceof(Timestamp).transform((value) => value.toDate());

/** A `storePurchases` document as read back — parsed, never cast (`ENG-09`). */
export const storedPurchase = z.object({
  store: z.enum(BILLING_STORES),
  storeRef: z.string().min(1),
  productId: z.string(),
  plan: z.enum(PLANS).nullable().default(null),
  status: z.enum(PURCHASE_STATUSES),
  accessUntil: timestamp.nullable().default(null),
  willRenew: z.boolean().nullable().default(null),
  isTest: z.boolean().default(false),
  householdId: z.string().nullable().default(null),
  linkedByUid: z.string().nullable().default(null),
  linkedByMemberId: z.string().nullable().default(null),
  supersededBy: z.string().nullable().default(null),
});
export type StoredPurchase = z.infer<typeof storedPurchase>;

/** The entitlement as it is written: instants as Timestamps, nothing undefined. */
export function entitlementFields(entitlement: Entitlement): Record<string, unknown> {
  return {
    premiumUntil:
      entitlement.premiumUntil === null ? null : Timestamp.fromDate(entitlement.premiumUntil),
    status: entitlement.status,
    plan: entitlement.plan,
    store: entitlement.store,
    willRenew: entitlement.willRenew,
    managedByMemberId: entitlement.managedByMemberId,
    isTest: entitlement.isTest,
    updatedAt: Timestamp.now(),
  };
}

/**
 * Whether the household has premium at [now] — the Functions' copy of the
 * rules' `hasPremium`, read inside the caller's transaction so a limit and
 * the write it guards see the same entitlement (BE-06).
 */
export async function householdHasPremium(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  now: Date,
): Promise<boolean> {
  const snapshot = await transaction.get(entitlementRef(store, householdId));
  const until: unknown = snapshot.get('premiumUntil');
  return until instanceof Timestamp && until.toMillis() > now.getTime();
}
