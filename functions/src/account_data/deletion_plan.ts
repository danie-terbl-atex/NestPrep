import { type Firestore, Timestamp } from 'firebase-admin/firestore';

import {
  type HouseholdDocument,
  type Role,
  ROLES,
  HOUSEHOLDS,
  MEMBERS,
  householdRef,
  userRef,
} from '../household/documents';
import { findClaimedMember } from '../household/membership';
import { STORE_PURCHASES, householdHasPremium } from '../subscriptions/subscription_documents';
import { type ClaimedAdult, type HouseholdOutcome, decideOutcome } from './household_outcome';

/** The most households one account is read across — far past household ADR-0002's case. */
export const HOUSEHOLD_LIMIT = 20;

/** Profiles read when looking for somebody to hand a household to. */
const CANDIDATE_LIMIT = 50;

/** What deleting the account does to one household, as the preview shows it. */
export interface HouseholdPlan {
  readonly householdId: string;
  readonly name: string;
  readonly role: Role;
  readonly memberId: string | null;
  readonly outcome: HouseholdOutcome;
  /** Who becomes admin, on a hand-over. */
  readonly successorName: string | null;
  /** Other accounts and kid devices that lose the household, when it ends. */
  readonly othersLosingAccess: number;
  readonly hasPremium: boolean;
}

export interface DeletionPlan {
  readonly households: readonly HouseholdPlan[];
  /** Store subscriptions this account pays for that will keep renewing unless cancelled. */
  readonly renewingSubscriptions: number;
}

export async function readDeletionPlan(
  store: Firestore,
  uid: string,
  now: Date,
): Promise<DeletionPlan> {
  const listed: unknown = (await userRef(store, uid).get()).get('householdIds');
  const ids = Array.isArray(listed)
    ? listed.filter((id): id is string => typeof id === 'string').slice(0, HOUSEHOLD_LIMIT)
    : [];
  const households: HouseholdPlan[] = [];
  for (const householdId of ids) {
    const plan = await planHousehold(store, uid, householdId, now);
    if (plan !== null) households.push(plan);
  }
  const renewing = await store
    .collection(STORE_PURCHASES)
    .where('linkedByUid', '==', uid)
    .where('willRenew', '==', true)
    .limit(HOUSEHOLD_LIMIT)
    .get();
  return { households, renewingSubscriptions: renewing.size };
}

/**
 * One household's part of the plan, or null when the household has gone or
 * no longer lists the account — both of which a retried deletion meets, and
 * neither of which is anything left to do.
 */
export async function planHousehold(
  store: Firestore,
  uid: string,
  householdId: string,
  now: Date,
): Promise<HouseholdPlan | null> {
  return store.runTransaction(
    async (transaction) => {
      const snapshot = await transaction.get(householdRef(store, householdId));
      const household = snapshot.data() as HouseholdDocument | undefined;
      const role = household?.members[uid];
      if (household === undefined || role === undefined) return null;

      const claimed = await findClaimedMember(transaction, store, householdId, uid);
      const candidates = await transaction.get(
        store
          .collection(HOUSEHOLDS)
          .doc(householdId)
          .collection(MEMBERS)
          .where('role', 'in', ['admin', 'parent', 'member'])
          .limit(CANDIDATE_LIMIT),
      );
      const others: (ClaimedAdult & { name: string })[] = candidates.docs.flatMap((doc) => {
        const claimedBy: unknown = doc.get('claimedBy');
        const createdAt: unknown = doc.get('createdAt');
        const role: unknown = doc.get('role');
        if (typeof claimedBy !== 'string' || claimedBy === uid || !isRole(role)) return [];
        return [
          {
            uid: claimedBy,
            memberId: doc.id,
            role,
            name: stringOr(doc.get('displayName'), ''),
            createdAtMillis: createdAt instanceof Timestamp ? createdAt.toMillis() : 0,
          },
        ];
      });
      const outcome = decideOutcome(uid, household.members, others);
      const successor =
        outcome.kind === 'handOver'
          ? others.find((other) => other.memberId === outcome.toMemberId)
          : undefined;
      return {
        householdId,
        name: household.name,
        role,
        memberId: claimed?.id ?? null,
        outcome,
        successorName: successor?.name ?? null,
        othersLosingAccess:
          Object.keys(household.members).length - 1 + Object.keys(household.kids ?? {}).length,
        hasPremium: await householdHasPremium(transaction, store, householdId, now),
      };
    },
    { readOnly: true },
  );
}

function isRole(value: unknown): value is Role {
  return value === 'member' || ROLES.some((role) => role === value);
}

function stringOr(value: unknown, fallback: string): string {
  return typeof value === 'string' ? value : fallback;
}
