import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { requireHandoverDate } from './change_rules';
import { requireRole } from './coparent_caller';
import { handoverRef } from './coparent_refs';
import { bothRefs, readLink, requireActive } from './link_context';
import { saveCoParentHandoverInput } from './schemas';

/**
 * Family in either home writes up one handover (household ADR-0004): what is
 * in the bag, medicine given, homework, clothes, anything else. It is written
 * whole to both homes' mirrors at once, and says which home saved it last —
 * never which person. Last write wins; a handover is prepared by one home and
 * read by the other.
 */
export const saveCoParentHandover = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(saveCoParentHandoverInput, request.data);
  requireHandoverDate(input.date);
  const store = db();

  await store.runTransaction(async (transaction) => {
    await requireRole(transaction, store, input.householdId, uid, 'family');
    const link = await readLink(transaction, store, input.linkId, input.householdId);
    requireActive(link);
    const record = {
      date: input.date,
      items: input.items,
      medicine: input.medicine,
      homework: input.homework,
      clothes: input.clothes,
      note: input.note,
      updatedBySide: link.side,
      updatedAt: FieldValue.serverTimestamp(),
    };
    for (const ref of bothRefs(link, (householdId) =>
      handoverRef(store, householdId, link.linkId, input.date),
    )) {
      transaction.set(ref, record);
    }
  });

  // Ids and counts only: a handover is about a child (ENG-22).
  logger.info('co-parent handover saved', {
    linkId: input.linkId,
    itemCount: input.items.length,
  });
  return { date: input.date };
});
