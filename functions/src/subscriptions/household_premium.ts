import {
  type DocumentReference,
  type Firestore,
  Timestamp,
  type Transaction,
} from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { householdRef } from '../household/documents';
import { type Entitlement, entitlementFrom, type LinkedPurchase } from './entitlement';
import { composePremium, type ComposedPremium, type PremiumGrant } from './premium_composition';
import {
  PURCHASES_PER_HOUSEHOLD,
  STORE_PURCHASES,
  type StoredPurchase,
  entitlementFields,
  entitlementRef,
  storedPurchase,
} from './subscription_documents';

/**
 * Everything a household's premium is made of, read inside the transaction
 * that restates it, and the one way it is written back (subscriptions
 * ADR-0001, ADR-0002). Every write that changes a household's premium — a
 * verified purchase, a store notification, the reconcile, a referral reward —
 * reads with [readHouseholdPremium] and writes with [stageHouseholdPremium],
 * so the store's answer and the months a household was given are always
 * composed the same way.
 */
export const PREMIUM_GRANTS = 'premiumGrants';

/** How many grants one restatement reads, newest first — eight years at the yearly cap. */
export const GRANTS_PER_HOUSEHOLD = 50;

export const GRANT_SOURCES = ['referral'] as const;
export type GrantSource = (typeof GRANT_SOURCES)[number];

const timestamp = z.instanceof(Timestamp).transform((value) => value.toDate());

/** A `premiumGrants` document as read back — parsed, never cast (`ENG-09`). */
export const storedGrant = z.object({
  source: z.enum(GRANT_SOURCES),
  days: z.number().int().positive(),
  grantedAt: timestamp,
  startsAt: timestamp.nullable().default(null),
});

export function premiumGrantRef(
  store: Firestore,
  householdId: string,
  grantId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(PREMIUM_GRANTS).doc(grantId);
}

/** A grant as stored: what the composition needs, and where it came from. */
export interface StoredPremiumGrant extends PremiumGrant {
  readonly source: GrantSource;
}

export interface HouseholdPremium {
  /** The store subscriptions giving the household premium, keyed by document id. */
  readonly purchases: Readonly<Record<string, StoredPurchase>>;
  readonly grants: readonly StoredPremiumGrant[];
  readonly previous: { readonly referralFrom: Date | null; readonly premiumUntil: Date | null };
}

export async function readHouseholdPremium(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
): Promise<HouseholdPremium> {
  const [purchases, grants, current] = await Promise.all([
    readLinked(transaction, store, householdId),
    readGrants(transaction, store, householdId),
    transaction.get(entitlementRef(store, householdId)),
  ]);
  return {
    purchases,
    grants,
    previous: {
      referralFrom: instantOf(current.get('referralFrom')),
      premiumUntil: instantOf(current.get('premiumUntil')),
    },
  };
}

export interface PremiumRestatement {
  readonly householdId: string;
  /** What the stores give, from [HouseholdPremium.purchases] as they now stand. */
  readonly storeEntitlement: Entitlement;
  readonly premium: HouseholdPremium;
  /** A grant made in this same transaction, not yet in [premium.grants]. */
  readonly newGrant?: PremiumGrant;
}

/**
 * Writes the household's entitlement — the stores' answer composed with its
 * grants — and the start of any grant that has begun, on the caller's
 * transaction. Answers the entitlement as it now stands.
 */
export function stageHouseholdPremium(
  transaction: Transaction,
  store: Firestore,
  restatement: PremiumRestatement,
  now: Date,
): Entitlement & ComposedPremium {
  const { householdId, storeEntitlement, premium, newGrant } = restatement;
  const grants = newGrant === undefined ? premium.grants : [...premium.grants, newGrant];
  const composed = composePremium(
    { storeUntil: storeEntitlement.premiumUntil, grants, previous: premium.previous },
    now,
  );
  transaction.set(
    entitlementRef(store, householdId),
    entitlementFields(storeEntitlement, composed),
  );
  for (const [grantId, startsAt] of Object.entries(composed.started)) {
    // A grant made in this transaction is created by its maker with its start.
    if (grantId === newGrant?.id) continue;
    transaction.update(premiumGrantRef(store, householdId, grantId), {
      startsAt: Timestamp.fromDate(startsAt),
    });
  }
  return { ...storeEntitlement, ...composed };
}

/** The stores' answer alone, from what is linked to the household. */
export function storeEntitlementOf(
  purchases: Readonly<Record<string, StoredPurchase>>,
  now: Date,
): Entitlement {
  return entitlementFrom(Object.values(purchases).map(linkedOf), now);
}

export function linkedOf(purchase: StoredPurchase): LinkedPurchase {
  return {
    store: purchase.store,
    plan: purchase.plan,
    linkedByMemberId: purchase.linkedByMemberId,
    state: {
      status: purchase.status,
      accessUntil: purchase.accessUntil,
      willRenew: purchase.willRenew,
      productId: purchase.productId,
      isTest: purchase.isTest,
    },
  };
}

/** The subscriptions giving [householdId] premium, keyed by document id. */
async function readLinked(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
): Promise<Record<string, StoredPurchase>> {
  const snapshot = await transaction.get(
    store
      .collection(STORE_PURCHASES)
      .where('householdId', '==', householdId)
      .limit(PURCHASES_PER_HOUSEHOLD),
  );
  return Object.fromEntries(
    snapshot.docs.flatMap((doc) => {
      const parsed = storedPurchase.safeParse(doc.data());
      return parsed.success && parsed.data.supersededBy === null ? [[doc.id, parsed.data]] : [];
    }),
  );
}

async function readGrants(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
): Promise<StoredPremiumGrant[]> {
  const snapshot = await transaction.get(
    householdRef(store, householdId)
      .collection(PREMIUM_GRANTS)
      .orderBy('grantedAt', 'desc')
      .limit(GRANTS_PER_HOUSEHOLD),
  );
  if (snapshot.size === GRANTS_PER_HOUSEHOLD) {
    logger.error('premium grants truncated', { householdId, limit: GRANTS_PER_HOUSEHOLD });
  }
  return snapshot.docs.flatMap((doc) => {
    const parsed = storedGrant.safeParse(doc.data());
    if (!parsed.success) {
      // A grant this build cannot read gives nothing rather than guessing.
      logger.error('premium grant unreadable', { householdId, grantId: doc.id });
      return [];
    }
    return [{ id: doc.id, ...parsed.data }];
  });
}

function instantOf(value: unknown): Date | null {
  return value instanceof Timestamp ? value.toDate() : null;
}
