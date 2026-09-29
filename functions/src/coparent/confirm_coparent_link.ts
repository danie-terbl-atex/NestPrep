import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { requireRole } from './coparent_caller';
import { authorityRef } from './coparent_refs';
import { refuseCoParent } from './errors';
import { readLink, updateBothMirrors } from './link_context';
import { confirmCoParentLinkInput } from './schemas';

/**
 * The home that made the code confirms the home that accepted it — or says
 * no (household ADR-0004). Only an admin of the side the link is waiting on
 * may answer, and only while it is pending. Yes makes the link active on the
 * authority and both mirrors at once; no marks it declined, and nothing was
 * ever shared but the two homes' names and the proposed schedule.
 */
export const confirmCoParentLink = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(confirmCoParentLinkInput, request.data);
  const store = db();

  const status = await store.runTransaction(async (transaction) => {
    await requireRole(transaction, store, input.householdId, uid, 'admin');
    const link = await readLink(transaction, store, input.linkId, input.householdId);
    if (link.status !== 'pending') throw refuseCoParent('linkNotActive');
    if (link.awaitingSide !== link.side) throw refuseCoParent('notYourTurn');

    const next = input.accept ? 'active' : 'declined';
    const patch = { status: next, awaitingSide: null, updatedAt: FieldValue.serverTimestamp() };
    transaction.update(authorityRef(store, link.linkId), patch);
    updateBothMirrors(transaction, store, link, patch);
    return next;
  });

  logger.info('co-parent link answered', { linkId: input.linkId, status });
  return { status };
});
