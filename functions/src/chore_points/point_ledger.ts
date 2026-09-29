import { FieldValue, type Firestore, type Transaction } from 'firebase-admin/firestore';

import { balanceRef, entryRef } from './point_refs';
import { parseSnapshot, storedBalance, type StoredBalance } from './point_documents';
import { NO_STREAK, nextStreak } from './streak';

/**
 * The ledger and the balance beside it (todos ADR-0003).
 *
 * A balance is never written on its own: every change is a ledger line and the
 * balance it leads to, staged on the same transaction, so the balance is a
 * projection of the ledger that cannot drift from it. Line ids are derived by
 * the caller, so a retried trigger writes the same line again and changes
 * nothing (`BE-06`).
 *
 * Reads come first in a Firestore transaction, so [readBalance] is called for
 * every member a transaction will touch before [stageLine] is called for any.
 */

export type EntryKind = 'chore' | 'choreUndone' | 'reward' | 'rewardReturned';

export interface LedgerLine {
  readonly entryId: string;
  readonly memberId: string;
  readonly delta: number;
  readonly kind: EntryKind;
  readonly sourceId: string;
  readonly title: string;
  /** `YYYY-MM-DD` when these stars were earned today — moves the streak. */
  readonly earnedOn?: string;
}

const EMPTY: StoredBalance = { balance: 0, earned: 0, spent: 0, ...NO_STREAK };

export async function readBalance(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  memberId: string,
): Promise<StoredBalance> {
  const snapshot = await transaction.get(balanceRef(store, householdId, memberId));
  return parseSnapshot(snapshot, storedBalance) ?? EMPTY;
}

/** What a line does to a balance. Pure, so the arithmetic is tested alone. */
export function applyLine(balance: StoredBalance, line: LedgerLine): StoredBalance {
  const earnedDelta = line.kind === 'chore' || line.kind === 'choreUndone' ? line.delta : 0;
  const spentDelta = line.kind === 'reward' || line.kind === 'rewardReturned' ? -line.delta : 0;
  // Only the three streak fields are taken from it: `nextStreak` hands back
  // what it was given when nothing moves, which here is the whole balance.
  const streak = line.earnedOn === undefined ? balance : nextStreak(balance, line.earnedOn);
  return {
    balance: balance.balance + line.delta,
    earned: balance.earned + earnedDelta,
    spent: balance.spent + spentDelta,
    streakDays: streak.streakDays,
    bestStreak: streak.bestStreak,
    streakLastDay: streak.streakLastDay,
  };
}

/** Stages one line and its balance; returns the balance after it. */
export function stageLine(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  balance: StoredBalance,
  line: LedgerLine,
): StoredBalance {
  const after = applyLine(balance, line);
  transaction.set(entryRef(store, householdId, line.entryId), {
    memberId: line.memberId,
    delta: line.delta,
    kind: line.kind,
    sourceId: line.sourceId,
    title: line.title,
    at: FieldValue.serverTimestamp(),
  });
  transaction.set(balanceRef(store, householdId, line.memberId), {
    memberId: line.memberId,
    ...after,
    updatedAt: FieldValue.serverTimestamp(),
  });
  return after;
}
