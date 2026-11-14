import { FieldValue, type Firestore, type Transaction } from 'firebase-admin/firestore';

import { parseSnapshot } from '../chore_points/point_documents';
import { readBalance, stageLine } from '../chore_points/point_ledger';
import { todayIn } from '../documents/expiry_schedule';
import { householdRef, memberRef } from '../household/documents';
import {
  storedKidRoutine,
  storedRoutineAward,
  storedRoutineTick,
  type StoredRoutineTick,
} from './routine_documents';
import { decideAward, type DesiredAward, type Ineligible } from './routine_eligibility';
import { kidRoutineRef, routineAwardRef, routineTickRef } from './routine_refs';

/**
 * Brings one child's day of a routine into line with its tick as it is *now*
 * (kid-routines ADR-0001), the way `reconcileChore` does a chore.
 *
 * It never trusts the event that woke it. Finishing awards once, unticking a
 * step takes back exactly what was given, finishing again awards a new round,
 * and a delivery that arrives twice finds the award where it should be and
 * writes nothing. A live award is never re-priced.
 */

export type RoutineOutcome = 'householdGone' | 'unchanged' | 'awarded' | 'withdrawn' | Ineligible;

export async function reconcileRoutine(
  store: Firestore,
  householdId: string,
  tickId: string,
  now: Date,
): Promise<RoutineOutcome> {
  return store.runTransaction(async (transaction) => {
    const household = await transaction.get(householdRef(store, householdId));
    if (!household.exists) return 'householdGone';
    const zone: unknown = household.get('timeZone');
    const today = todayIn(typeof zone === 'string' ? zone : 'UTC', now);

    const tick = parseSnapshot(
      await transaction.get(routineTickRef(store, householdId, tickId)),
      storedRoutineTick,
    );
    const ref = routineAwardRef(store, householdId, tickId);
    const award = parseSnapshot(await transaction.get(ref), storedRoutineAward);
    const decided =
      tick === undefined ? undefined : await decide(transaction, store, householdId, tick, today);
    const desired = typeof decided === 'object' ? decided : undefined;
    const live = award?.status === 'awarded' ? award : undefined;

    if (desired === undefined) {
      if (live === undefined) return typeof decided === 'string' ? decided : 'unchanged';
      const balance = await readBalance(transaction, store, householdId, live.memberId);
      stageLine(transaction, store, householdId, balance, {
        entryId: `routine_undo_${tickId}_${String(live.round)}`,
        memberId: live.memberId,
        delta: -live.points,
        kind: 'routineUndone',
        sourceId: tickId,
        title: live.title,
      });
      transaction.set(
        ref,
        { status: 'withdrawn', settledAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      return 'withdrawn';
    }
    if (live !== undefined) return 'unchanged';

    const round = (award?.round ?? 0) + 1;
    const balance = await readBalance(transaction, store, householdId, desired.memberId);
    transaction.set(ref, {
      memberId: desired.memberId,
      routineId: desired.routineId,
      occurrenceDate: desired.occurrenceDate,
      title: desired.title,
      points: desired.points,
      status: 'awarded',
      round,
      awardedAt: FieldValue.serverTimestamp(),
      settledAt: null,
    });
    stageLine(transaction, store, householdId, balance, {
      entryId: `routine_${tickId}_${String(round)}`,
      memberId: desired.memberId,
      delta: desired.points,
      kind: 'routine',
      sourceId: tickId,
      title: desired.title,
      earnedOn: today,
    });
    return 'awarded';
  });
}

/** Reads what the decision needs — the routine and the child's role — and decides. */
async function decide(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  tick: StoredRoutineTick,
  today: string,
): Promise<DesiredAward | Ineligible> {
  const routine = parseSnapshot(
    await transaction.get(kidRoutineRef(store, householdId, tick.routineId)),
    storedKidRoutine,
  );
  const role: unknown = (await transaction.get(memberRef(store, householdId, tick.kidId))).get(
    'role',
  );
  return decideAward({
    tick,
    routine,
    kidRole: typeof role === 'string' ? role : undefined,
    today,
  });
}
