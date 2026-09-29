import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { requireRole } from './coparent_caller';
import { authorityRef, mirrorRef, REQUESTS, requestRef } from './coparent_refs';
import { refuseCoParent } from './errors';
import { readLink, updateBothMirrors } from './link_context';
import { endCoParentLinkInput } from './schemas';

/**
 * Either home's admin ends a link (household ADR-0004). Nothing new is
 * shared from then on; what was already shared stays with each home as a
 * read-only record, because it was already seen. Requests still waiting for
 * an answer are closed on both sides, so neither home is left holding a
 * question nobody can answer.
 *
 * A pending link can be ended too — the accepting home changing its mind
 * before the other confirms.
 */
export const endCoParentLink = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(endCoParentLinkInput, request.data);
  const store = db();

  await store.runTransaction(async (transaction) => {
    await requireRole(transaction, store, input.householdId, uid, 'admin');
    const link = await readLink(transaction, store, input.linkId, input.householdId);
    if (link.status !== 'active' && link.status !== 'pending') {
      throw refuseCoParent('linkNotActive');
    }
    const waiting = await transaction.get(
      mirrorRef(store, input.householdId, link.linkId)
        .collection(REQUESTS)
        .where('status', '==', 'pending')
        .limit(50),
    );

    const now = FieldValue.serverTimestamp();
    transaction.update(authorityRef(store, link.linkId), {
      status: 'ended',
      awaitingSide: null,
      updatedAt: now,
    });
    updateBothMirrors(transaction, store, link, {
      status: 'ended',
      awaitingSide: null,
      endedBySide: link.side,
      updatedAt: now,
    });
    for (const pending of waiting.docs) {
      for (const householdId of Object.values(link.householdIds)) {
        transaction.update(requestRef(store, householdId, link.linkId, pending.id), {
          status: 'closed',
          answeredAt: now,
        });
      }
    }
  });

  logger.info('co-parent link ended', { linkId: input.linkId });
  return { status: 'ended' };
});
