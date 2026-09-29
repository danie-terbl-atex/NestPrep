import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { db } from '../shared/firestore';
import { todayIn } from '../documents/expiry_schedule';
import { parseInput, requireUid } from '../household/parse_input';
import { refusePoints } from './errors';
import { requireFamily } from './family_caller';
import { readBalance, stageLine } from './point_ledger';
import { claimRef, completionRef } from './point_refs';
import { parseSnapshot, storedClaim } from './point_documents';
import { reviewChoreInput } from './schemas';

/**
 * A parent looks at a chore that was waiting for them (todos ADR-0003).
 *
 * *Looks good* moves the claim to `awarded` and writes the stars in the same
 * transaction, so a claim is never approved without its stars or paid twice.
 * *Send back* marks the claim `sentBack` and deletes the completion, so the
 * chore is undone again on the child's screen; the trigger that wakes on that
 * delete finds nothing live to reverse.
 *
 * Only family may do either. A kid device is refused before anything is read.
 */
export const reviewChore = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(reviewChoreInput, request.data);
  const store = db();

  const status = await store.runTransaction(async (transaction) => {
    const caller = await requireFamily(transaction, store, input.householdId, uid);
    const ref = claimRef(store, input.householdId, input.completionId);
    const claim = parseSnapshot(await transaction.get(ref), storedClaim);
    if (claim === undefined) throw refusePoints('claimNotFound');
    if (claim.status !== 'pending') throw refusePoints('alreadySettled');

    const settled = { settledAt: FieldValue.serverTimestamp(), settledBy: caller.memberId };
    if (input.decision === 'sendBack') {
      transaction.update(ref, { status: 'sentBack', ...settled });
      transaction.delete(completionRef(store, input.householdId, input.completionId));
      return 'sentBack';
    }

    const balance = await readBalance(transaction, store, input.householdId, claim.memberId);
    transaction.update(ref, { status: 'awarded', ...settled });
    stageLine(transaction, store, input.householdId, balance, {
      entryId: `chore_${input.completionId}_${String(claim.round)}`,
      memberId: claim.memberId,
      delta: claim.points,
      kind: 'chore',
      sourceId: input.completionId,
      title: claim.title,
      earnedOn: todayIn(caller.timeZone, new Date()),
    });
    return 'awarded';
  });

  logger.info('chore reviewed', { householdId: input.householdId, status });
  return { status };
});
