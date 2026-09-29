import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { db } from '../shared/firestore';
import { parseInput, requireUid } from '../household/parse_input';
import { refusePoints } from './errors';
import { requireFamily } from './family_caller';
import { readBalance, stageLine } from './point_ledger';
import { requestRef } from './point_refs';
import { parseSnapshot, storedRequest } from './point_documents';
import { settleRewardInput } from './schemas';

/**
 * A parent hands a reward over, or says not now (todos ADR-0003).
 *
 * The stars were taken when the child asked, so *Given* only records it, and
 * *Not now* returns exactly what was taken — the cost the request recorded,
 * not whatever the reward costs today — in the same transaction as the status.
 */
export const settleReward = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(settleRewardInput, request.data);
  const store = db();

  const status = await store.runTransaction(async (transaction) => {
    const caller = await requireFamily(transaction, store, input.householdId, uid);
    const ref = requestRef(store, input.householdId, input.requestId);
    const snapshot = await transaction.get(ref);
    const stored = parseSnapshot(snapshot, storedRequest);
    if (stored === undefined) throw refusePoints('requestNotFound');
    if (stored.status !== 'waiting') throw refusePoints('alreadySettled');

    const settled = { settledAt: FieldValue.serverTimestamp(), settledBy: caller.memberId };
    if (input.decision === 'fulfil') {
      transaction.update(ref, { status: 'fulfilled', ...settled });
      return 'fulfilled';
    }

    const balance = await readBalance(transaction, store, input.householdId, stored.memberId);
    const title: unknown = snapshot.get('title');
    transaction.update(ref, { status: 'declined', ...settled });
    stageLine(transaction, store, input.householdId, balance, {
      entryId: `return_${input.requestId}`,
      memberId: stored.memberId,
      delta: stored.cost ?? 0,
      kind: 'rewardReturned',
      sourceId: input.requestId,
      title: typeof title === 'string' ? title : '',
    });
    return 'declined';
  });

  logger.info('reward settled', { householdId: input.householdId, status });
  return { status };
});
