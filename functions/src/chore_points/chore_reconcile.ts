import {
  FieldValue,
  type DocumentReference,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';

import { householdRef, memberRef } from '../household/documents';
import { todayIn } from '../documents/expiry_schedule';
import { decideClaim, type DesiredClaim, type Ineligible } from './chore_eligibility';
import { readBalance, stageLine, type LedgerLine } from './point_ledger';
import { claimRef, completionRef, routineRef, taskRef } from './point_refs';
import {
  parseSnapshot,
  storedClaim,
  storedCompletion,
  storedRoutine,
  storedTask,
  type StoredBalance,
  type StoredClaim,
  type StoredCompletion,
} from './point_documents';

/**
 * Brings one occurrence's claim into line with its completion as it is *now*
 * (todos ADR-0003).
 *
 * It never trusts the event that woke it: it reads the completion, and decides
 * from that. A tick awards (or waits for a parent), an untick reverses exactly
 * what the tick gave, a completion moved to a different child moves the stars,
 * and a delivery that arrives twice or out of order finds the claim already
 * where it should be and writes nothing.
 */

export type ReconcileOutcome =
  'householdGone' | 'unchanged' | 'awarded' | 'pending' | 'withdrawn' | Ineligible;

const LIVE: readonly StoredClaim['status'][] = ['pending', 'awarded'];

export async function reconcileChore(
  store: Firestore,
  householdId: string,
  completionId: string,
  now: Date,
): Promise<ReconcileOutcome> {
  return store.runTransaction(async (transaction) => {
    const household = await transaction.get(householdRef(store, householdId));
    if (!household.exists) return 'householdGone';
    const zone: unknown = household.get('timeZone');
    const today = todayIn(typeof zone === 'string' ? zone : 'UTC', now);

    const completion = parseSnapshot(
      await transaction.get(completionRef(store, householdId, completionId)),
      storedCompletion,
    );
    const claimSnapshot = await transaction.get(claimRef(store, householdId, completionId));
    const claim = parseSnapshot(claimSnapshot, storedClaim);
    const decided =
      completion === undefined
        ? undefined
        : await decide(transaction, store, householdId, completion, today);
    const desired = typeof decided === 'object' ? decided : undefined;
    const live = claim !== undefined && LIVE.includes(claim.status) ? claim : undefined;

    if (live !== undefined && desired !== undefined && live.memberId === desired.memberId) {
      return 'unchanged';
    }
    if (live === undefined && desired === undefined) {
      return typeof decided === 'string' ? decided : 'unchanged';
    }

    // Every balance this will move, read before anything is written. When a
    // claim both reverses and awards, the two are different children — the
    // same child returned `unchanged` above.
    const undoBalance =
      live?.status === 'awarded'
        ? await readBalance(transaction, store, householdId, live.memberId)
        : undefined;
    const awardBalance =
      desired?.awardsAtOnce === true
        ? await readBalance(transaction, store, householdId, desired.memberId)
        : undefined;

    const ref = claimRef(store, householdId, completionId);
    if (live !== undefined && undoBalance !== undefined) {
      stageLine(transaction, store, householdId, undoBalance, {
        entryId: `undo_${completionId}_${String(live.round)}`,
        memberId: live.memberId,
        delta: -live.points,
        kind: 'choreUndone',
        sourceId: completionId,
        title: live.title,
      });
    }
    if (desired === undefined) {
      transaction.set(
        ref,
        { status: 'withdrawn', settledAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      return 'withdrawn';
    }
    return stageClaim(transaction, ref, {
      desired,
      round: (claim?.round ?? 0) + 1,
      balance: awardBalance,
      today,
      stage: (balance, line) => stageLine(transaction, store, householdId, balance, line),
      completionId,
    });
  });
}

/** Writes the claim a completion should have, and its stars when they land now. */
function stageClaim(
  transaction: Transaction,
  ref: DocumentReference,
  claim: {
    readonly desired: DesiredClaim;
    readonly round: number;
    readonly balance: StoredBalance | undefined;
    readonly today: string;
    readonly completionId: string;
    readonly stage: (balance: StoredBalance, line: LedgerLine) => void;
  },
): 'awarded' | 'pending' {
  const { desired: next, round } = claim;
  transaction.set(ref, {
    memberId: next.memberId,
    taskId: next.taskId,
    occurrenceDate: next.occurrenceDate,
    title: next.title,
    points: next.points,
    completedBy: next.completedBy,
    status: next.awardsAtOnce ? 'awarded' : 'pending',
    round,
    claimedAt: FieldValue.serverTimestamp(),
    settledAt: next.awardsAtOnce ? FieldValue.serverTimestamp() : null,
    settledBy: next.awardsAtOnce ? next.completedBy : null,
  });
  const balance = claim.balance;
  if (!next.awardsAtOnce || balance === undefined) return 'pending';
  claim.stage(balance, {
    entryId: `chore_${claim.completionId}_${String(round)}`,
    memberId: next.memberId,
    delta: next.points,
    kind: 'chore',
    sourceId: claim.completionId,
    title: next.title,
    earnedOn: claim.today,
  });
  return 'awarded';
}

/** Reads what the decision needs — task, routine, both roles — and decides. */
async function decide(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  completion: StoredCompletion,
  today: string,
): Promise<DesiredClaim | Ineligible> {
  const task = parseSnapshot(
    await transaction.get(taskRef(store, householdId, completion.taskId)),
    storedTask,
  );
  const routine =
    task === undefined || task.routineId === null
      ? undefined
      : parseSnapshot(
          await transaction.get(routineRef(store, householdId, task.routineId)),
          storedRoutine,
        );
  const roleOf = async (memberId: string): Promise<string | undefined> => {
    const role: unknown = (await transaction.get(memberRef(store, householdId, memberId))).get(
      'role',
    );
    return typeof role === 'string' ? role : undefined;
  };
  return decideClaim({
    completion,
    task,
    routine,
    forRole: await roleOf(completion.completedFor),
    byRole: await roleOf(completion.completedBy),
    today,
  });
}
