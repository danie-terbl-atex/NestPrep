import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { MAX_OPEN_REQUESTS, swapDays } from './change_rules';
import { requireRole } from './coparent_caller';
import { mirrorRef, REQUESTS, requestRef } from './coparent_refs';
import { refuseCoParent } from './errors';
import { bothRefs, readLink, requireActive } from './link_context';
import { proposeCoParentChangeInput, type ProposedChange } from './schemas';

/**
 * Family in either home asks the other home for a change (household
 * ADR-0004): a swap — these days with this home — or a whole new schedule.
 * Nothing moves until the other home accepts; the request is written to both
 * homes' mirrors at once and stays there, answered or not, as the history.
 */
export const proposeCoParentChange = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(proposeCoParentChangeInput, request.data);
  const store = db();

  const requestId = await store.runTransaction(async (transaction) => {
    await requireRole(transaction, store, input.householdId, uid, 'family');
    const link = await readLink(transaction, store, input.linkId, input.householdId);
    requireActive(link);
    const open = await transaction.get(
      mirrorRef(store, input.householdId, link.linkId)
        .collection(REQUESTS)
        .where('status', '==', 'pending')
        .limit(MAX_OPEN_REQUESTS),
    );
    if (open.size >= MAX_OPEN_REQUESTS) throw refuseCoParent('tooManyRequests');

    const id = mirrorRef(store, input.householdId, link.linkId).collection(REQUESTS).doc().id;
    const record = {
      ...changeFields(input.change),
      note: input.note,
      proposedBySide: link.side,
      status: 'pending',
      createdAt: FieldValue.serverTimestamp(),
      answeredAt: null,
      answeredBySide: null,
      answerNote: null,
    };
    for (const ref of bothRefs(link, (householdId) =>
      requestRef(store, householdId, link.linkId, id),
    )) {
      transaction.set(ref, record);
    }
    return id;
  });

  logger.info('co-parent change proposed', { linkId: input.linkId, kind: input.change.kind });
  return { requestId };
});

/** The stored half of a change: what a swap moves, or the schedule proposed. */
function changeFields(change: ProposedChange): Record<string, unknown> {
  if (change.kind === 'schedule') return { kind: 'schedule', schedule: change.schedule };
  // Checked here, before anything is written, rather than when it is accepted.
  swapDays(change.from, change.to);
  return { kind: 'swap', from: change.from, to: change.to, toSide: change.toSide };
}
