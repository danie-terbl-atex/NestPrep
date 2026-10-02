import { type Firestore, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { type KidAuthAccounts, kidAuthAccounts } from '../accounts/kid_auth_accounts';
import { OAUTH_STATES } from '../calendar_sync/sync_documents';
import { checkersLinkRef } from '../checkers/firestore_link_store';
import { userRef } from '../household/documents';
import { STORE_PURCHASES } from '../subscriptions/subscription_documents';
import { db } from '../shared/firestore';
import { type ObjectStore, objectStore } from '../shared/storage';
import { type AccountAuth, accountAuth } from './account_auth';
import { readDeletionPlan } from './deletion_plan';
import { endHousehold } from './end_household';
import { refuseAccountData } from './errors';
import { endingsAgree } from './household_outcome';
import { leaveErasing } from './leave_erasing';
import { exportObjectPrefix } from './personal_refs';

/**
 * One line per erased account, keyed by the uid it had and holding no personal
 * information: when it started, how it was asked for, and when it finished.
 * It is how an interrupted erasure is found and finished (BE-07), and the
 * record that a request was honoured (accounts ADR-0006). Closed to clients.
 */
export const ACCOUNT_DELETIONS = 'accountDeletions';

/** Rows per page when clearing what the account left outside its households. */
const PAGE = 400;

export interface ErasureDeps {
  readonly store: Firestore;
  readonly objects: ObjectStore;
  readonly accountAuth: AccountAuth;
  readonly kidAccounts: KidAuthAccounts;
  readonly now: () => Date;
}

export function liveErasureDeps(): ErasureDeps {
  return {
    store: db(),
    objects: objectStore(),
    accountAuth: accountAuth(),
    kidAccounts: kidAuthAccounts(),
    now: () => new Date(),
  };
}

export interface ErasureRequest {
  readonly uid: string;
  readonly via: 'app' | 'webRequest';
  /** The households the person agreed to end; absent only for an operator-run erasure. */
  readonly agreedEndings?: readonly string[];
}

export interface ErasureSummary {
  readonly householdsLeft: number;
  readonly householdsHandedOver: number;
  readonly householdsEnded: number;
}

/**
 * Erases an account and everything that is only about the person (accounts
 * ADR-0006). The plan is read again here, never taken from the client, and
 * nothing is touched when the households it would end are not the ones the
 * person agreed to.
 *
 * Households first, then what lives outside them, then the account document,
 * and the Auth user last — so a failure part-way leaves somebody who can still
 * sign in and press delete again, and every step is safe to repeat.
 */
export async function eraseAccount(
  deps: ErasureDeps,
  request: ErasureRequest,
): Promise<ErasureSummary> {
  const { store, objects, uid } = { ...deps, uid: request.uid };
  const plan = await readDeletionPlan(store, uid, deps.now());
  const ending = plan.households.filter((household) => household.outcome.kind === 'end');
  if (
    request.agreedEndings !== undefined &&
    !endingsAgree(
      request.agreedEndings,
      ending.map((household) => household.householdId),
    )
  ) {
    throw refuseAccountData('deletionPlanChanged');
  }

  const ledger = store.collection(ACCOUNT_DELETIONS).doc(uid);
  await commitOne(store, (batch) =>
    batch.set(
      ledger,
      { via: request.via, startedAt: Timestamp.fromDate(deps.now()), completedAt: null },
      { merge: true },
    ),
  );

  for (const household of plan.households) {
    if (household.outcome.kind === 'end') {
      await endHousehold(deps, uid, household.householdId);
    } else {
      await leaveErasing(store, objects, { uid, household });
    }
  }

  await unlinkPurchasesOf(store, uid);
  await deleteOAuthStates(store, uid);
  // The member's Checkers link: a sealed session and a masked number.
  await store.recursiveDelete(checkersLinkRef(store, uid));
  await objects.deletePrefix(exportObjectPrefix(uid));
  await store.recursiveDelete(userRef(store, uid));

  const summary: ErasureSummary = {
    householdsLeft: plan.households.filter((h) => h.outcome.kind === 'leave').length,
    householdsHandedOver: plan.households.filter((h) => h.outcome.kind === 'handOver').length,
    householdsEnded: ending.length,
  };
  await commitOne(store, (batch) =>
    batch.set(ledger, { ...summary, completedAt: Timestamp.fromDate(deps.now()) }, { merge: true }),
  );
  await deps.accountAuth.remove(uid);
  logger.info('account erased', { via: request.via, ...summary });
  return summary;
}

async function commitOne(
  store: Firestore,
  stage: (batch: FirebaseFirestore.WriteBatch) => void,
): Promise<void> {
  const batch = store.batch();
  stage(batch);
  await batch.commit();
}

/**
 * The store subscriptions this account linked keep their household — premium
 * is the household's (subscriptions ADR-0001) — but no longer name who linked
 * them.
 */
async function unlinkPurchasesOf(store: Firestore, uid: string): Promise<void> {
  const linked = await store
    .collection(STORE_PURCHASES)
    .where('linkedByUid', '==', uid)
    .limit(PAGE)
    .get();
  if (linked.empty) return;
  const batch = store.batch();
  for (const purchase of linked.docs) batch.update(purchase.ref, { linkedByUid: null });
  await batch.commit();
}

/** A calendar connection this account had started and not finished. */
async function deleteOAuthStates(store: Firestore, uid: string): Promise<void> {
  const pending = await store.collection(OAUTH_STATES).where('uid', '==', uid).limit(PAGE).get();
  if (pending.empty) return;
  const batch = store.batch();
  for (const state of pending.docs) batch.delete(state.ref);
  await batch.commit();
}
