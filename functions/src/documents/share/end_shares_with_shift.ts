import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';

import { HOUSEHOLDS } from '../../household/documents';
import { SHIFTS } from '../../nanny_hub/nanny_refs';
import { db } from '../../shared/firestore';
import { MAX_LIVE_SHARES } from './share_policy';
import { liveSharesOfShift } from './share_refs';

/**
 * A link made "until the shift ends" is marked `ended` when its shift ends
 * (documents ADR-0006). This keeps the family's list honest; it is not what
 * keeps the link safe — serving reads the shift live on every request, so a
 * link whose shift has ended stops working whether or not this has run.
 *
 * It only reads the nanny hub's shift, and only the status field of its
 * before and after: nothing about the shift's content reaches documents.
 */
export const endSharesWithShift = onDocumentUpdated(
  `${HOUSEHOLDS}/{householdId}/${SHIFTS}/{shiftId}`,
  async (event) => {
    const before: unknown = event.data?.before.get('status');
    const after: unknown = event.data?.after.get('status');
    if (before !== 'open' || after !== 'ended') return;

    const { householdId, shiftId } = event.params;
    const store = db();
    const live = await liveSharesOfShift(store, householdId, shiftId, MAX_LIVE_SHARES).get();
    if (live.empty) return;
    const batch = store.batch();
    for (const share of live.docs) {
      batch.update(share.ref, { status: 'ended', endedAt: FieldValue.serverTimestamp() });
    }
    await batch.commit();
    logger.info('document shares ended with their shift', { householdId, count: live.size });
  },
);
