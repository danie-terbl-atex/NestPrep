import {
  type DocumentReference,
  type Firestore,
  Timestamp,
  type Transaction,
} from 'firebase-admin/firestore';

import type { Entitlement } from './entitlement';
import {
  type HouseholdPremium,
  linkedOf,
  readHouseholdPremium,
  stageHouseholdPremium,
} from './household_premium';
import { entitlementFrom } from './entitlement';
import { refuseSubscription } from './errors';
import type { Plan } from './purchase_state';
import type { Cohort } from './subscription_config';
import { type StoredPurchase, storePurchaseRef, storedPurchase } from './subscription_documents';
import type { VerifiedPurchase } from './verified_purchase';

/**
 * Records what a store said about one subscription and brings every
 * household it touches up to date, in one transaction (BE-06, BE-07;
 * subscriptions ADR-0001).
 *
 * A purchase is linked to a household only by a verified call from a parent
 * in it. Once linked it stays with that household: a notification or the
 * daily reconcile only changes its state. The person who linked it may move
 * it — a parent who leaves takes their subscription to their new household —
 * and anybody else trying to is refused, so one store account cannot unlock
 * every household it has ever been in.
 */
export interface LinkRequest {
  readonly householdId: string;
  readonly uid: string;
  readonly memberId: string;
  readonly cohort: Cohort;
}

export interface RecordRequest {
  readonly purchase: VerifiedPurchase;
  readonly plan: Plan | null;
  /** Absent for a notification or the reconcile, which never link. */
  readonly link?: LinkRequest;
}

export interface RecordOutcome {
  /** The household the purchase gives premium to now, if any. */
  readonly householdId: string | null;
  readonly entitlement: Entitlement | null;
  /** True the first time NestPrep has ever seen this subscription. */
  readonly isFirstSighting: boolean;
}

export async function recordPurchase(
  store: Firestore,
  request: RecordRequest,
  now: Date,
): Promise<RecordOutcome> {
  return store.runTransaction(async (transaction) => {
    const { purchase, link } = request;
    const ref = storePurchaseRef(store, purchase.store, purchase.storeRef);
    const existing = await readStored(transaction, ref);
    const previousHousehold = existing?.householdId ?? null;
    if (
      link !== undefined &&
      previousHousehold !== null &&
      previousHousehold !== link.householdId
    ) {
      if (existing?.linkedByUid !== link.uid) throw refuseSubscription('purchaseInUseElsewhere');
    }
    const replacedRef =
      purchase.replaces === null
        ? null
        : storePurchaseRef(store, purchase.store, purchase.replaces);
    const replaced = replacedRef === null ? undefined : await readStored(transaction, replacedRef);

    const householdId = link?.householdId ?? previousHousehold;
    const affected = [
      ...new Set([householdId, previousHousehold, replaced?.householdId ?? null]),
    ].filter((id): id is string => id !== null);
    const premiumOf: Record<string, HouseholdPremium> = {};
    for (const id of affected) premiumOf[id] = await readHouseholdPremium(transaction, store, id);

    // Every read is done; from here on, only writes (a transaction's rule).
    const updated = storedAfter(request, existing, householdId);
    transaction.set(
      ref,
      {
        ...storedFields(updated),
        ...(link === undefined ? {} : { cohort: link.cohort }),
        ...(existing === undefined ? { firstSeenAt: Timestamp.fromDate(now) } : {}),
        updatedAt: Timestamp.fromDate(now),
      },
      { merge: true },
    );
    if (replacedRef !== null && replaced !== undefined) {
      transaction.update(replacedRef, { supersededBy: ref.id, updatedAt: Timestamp.fromDate(now) });
    }

    const entitlement = restateEntitlements(transaction, store, {
      premiumOf,
      recounted: new Set([ref.id, replacedRef?.id]),
      householdId,
      updated,
      now,
    });
    return { householdId, entitlement, isFirstSighting: existing === undefined };
  });
}

interface Restatement {
  readonly premiumOf: Readonly<Record<string, HouseholdPremium>>;
  /** Documents whose stored copy is out of date: the one just recorded, and the one it replaced. */
  readonly recounted: ReadonlySet<string | undefined>;
  readonly householdId: string | null;
  readonly updated: StoredPurchase;
  readonly now: Date;
}

/**
 * Writes the entitlement of every household the purchase touched, from what
 * was read plus what was just recorded — composed with each household's
 * granted months (subscriptions ADR-0002) — and answers with [householdId]'s.
 */
function restateEntitlements(
  transaction: Transaction,
  store: Firestore,
  restatement: Restatement,
): Entitlement | null {
  const { premiumOf, recounted, householdId, updated, now } = restatement;
  let entitlement: Entitlement | null = null;
  for (const [id, premium] of Object.entries(premiumOf)) {
    const others = Object.entries(premium.purchases)
      .filter(([key]) => !recounted.has(key))
      .map(([, other]) => other);
    const isGiving = id === householdId && updated.supersededBy === null;
    const storeEntitlement = entitlementFrom(
      (isGiving ? [...others, updated] : others).map(linkedOf),
      now,
    );
    const next = stageHouseholdPremium(
      transaction,
      store,
      { householdId: id, storeEntitlement, premium },
      now,
    );
    if (id === householdId) entitlement = next;
  }
  return entitlement;
}

function storedAfter(
  request: RecordRequest,
  existing: StoredPurchase | undefined,
  householdId: string | null,
): StoredPurchase {
  const { purchase, link } = request;
  return {
    store: purchase.store,
    storeRef: purchase.storeRef,
    productId: purchase.state.productId,
    plan: request.plan ?? existing?.plan ?? null,
    status: purchase.state.status,
    accessUntil: purchase.state.accessUntil,
    willRenew: purchase.state.willRenew,
    isTest: purchase.state.isTest,
    householdId,
    linkedByUid: link?.uid ?? existing?.linkedByUid ?? null,
    linkedByMemberId: link?.memberId ?? existing?.linkedByMemberId ?? null,
    supersededBy: existing?.supersededBy ?? null,
  };
}

function storedFields(purchase: StoredPurchase): Record<string, unknown> {
  return {
    ...purchase,
    accessUntil: purchase.accessUntil === null ? null : Timestamp.fromDate(purchase.accessUntil),
  };
}

async function readStored(
  transaction: Transaction,
  ref: DocumentReference,
): Promise<StoredPurchase | undefined> {
  const snapshot = await transaction.get(ref);
  if (!snapshot.exists) return undefined;
  const parsed = storedPurchase.safeParse(snapshot.data());
  // A document this code cannot read is one an older or newer build wrote;
  // treating it as absent would let a second household claim the purchase.
  if (!parsed.success) throw new Error(`unreadable store purchase ${ref.id}`);
  return parsed.data;
}
