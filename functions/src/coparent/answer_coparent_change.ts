import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';

import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { mayAnswer, statusAfter, storedSwapDays, withSwap } from './change_rules';
import { requireRole } from './coparent_caller';
import { requestRef } from './coparent_refs';
import { refuseCoParent } from './errors';
import { bothRefs, readLink, requireActive, updateBothMirrors } from './link_context';
import { custodySchedule, side } from './schedule_schema';
import { answerCoParentChangeInput } from './schemas';

const storedRequest = z.discriminatedUnion('kind', [
  z.object({
    kind: z.literal('swap'),
    from: z.string(),
    to: z.string(),
    toSide: side,
    proposedBySide: side,
    status: z.string(),
  }),
  z.object({
    kind: z.literal('schedule'),
    schedule: custodySchedule,
    proposedBySide: side,
    status: z.string(),
  }),
]);

/**
 * The other home accepts or declines a request, or the home that asked
 * withdraws it (household ADR-0004). Accepting applies it in the same
 * transaction — a swap's days become overrides, a schedule replaces the old
 * one — on both homes' mirrors at once, and the request keeps its answer as
 * history. Somebody got there first is `requestAlreadyAnswered`, never a
 * second change.
 */
export const answerCoParentChange = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(answerCoParentChangeInput, request.data);
  const store = db();

  const status = await store.runTransaction(async (transaction) => {
    await requireRole(transaction, store, input.householdId, uid, 'family');
    const link = await readLink(transaction, store, input.linkId, input.householdId);
    requireActive(link);
    const snapshot = await transaction.get(
      requestRef(store, input.householdId, link.linkId, input.requestId),
    );
    const stored = storedRequest.safeParse(snapshot.data());
    if (!snapshot.exists || !stored.success) throw refuseCoParent('requestNotFound');
    if (stored.data.status !== 'pending') throw refuseCoParent('requestAlreadyAnswered');
    if (!mayAnswer(link.side, stored.data.proposedBySide, input.answer)) {
      throw refuseCoParent('notYourTurn');
    }

    const now = FieldValue.serverTimestamp();
    const next = statusAfter(input.answer);
    if (next === 'accepted') {
      const change = stored.data;
      updateBothMirrors(
        transaction,
        store,
        link,
        change.kind === 'swap'
          ? {
              overrides: withSwap(
                link.overrides,
                storedSwapDays(change.from, change.to),
                change.toSide,
              ),
              updatedAt: now,
            }
          : { schedule: change.schedule, updatedAt: now },
      );
    }
    for (const ref of bothRefs(link, (householdId) =>
      requestRef(store, householdId, link.linkId, input.requestId),
    )) {
      transaction.update(ref, {
        status: next,
        answeredAt: now,
        answeredBySide: link.side,
        answerNote: input.note,
      });
    }
    return next;
  });

  logger.info('co-parent change answered', { linkId: input.linkId, status });
  return { status };
});
