import { logger } from 'firebase-functions/v2';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';

import { COPARENT_LINKS, HANDOVERS, REQUESTS } from '../coparent/coparent_refs';
import { HOUSEHOLDS } from '../household/documents';
import { db } from '../shared/firestore';
import { deliverCoParentHandover, deliverCoParentRequest } from './coparent_delivery';
import { pushService } from './push_service';

/**
 * The other home asked for a change — a swap or a new schedule — and it
 * landed in this home's mirror: this home's admins hear (household ADR-0004,
 * notifications ADR-0001). The copy in the asking home says nothing.
 */
export const notifyCoParentRequest = onDocumentCreated(
  `${HOUSEHOLDS}/{householdId}/${COPARENT_LINKS}/{linkId}/${REQUESTS}/{requestId}`,
  async (event) => {
    const { householdId, linkId, requestId } = event.params;
    const report = await deliverCoParentRequest(db(), pushService(), {
      householdId,
      linkId,
      requestId,
      data: event.data?.data(),
      now: new Date(event.time),
    });
    if (report !== null) {
      logger.info('co-parent request announced', { householdId, linkId, created: report.created });
    }
  },
);

/**
 * The other home wrote a handover note for a day: this home's admins hear,
 * once per handover day (household ADR-0004). A deleted note says nothing.
 */
export const notifyCoParentHandover = onDocumentWritten(
  `${HOUSEHOLDS}/{householdId}/${COPARENT_LINKS}/{linkId}/${HANDOVERS}/{date}`,
  async (event) => {
    const after = event.data?.after;
    if (after?.exists !== true) return;
    const { householdId, linkId } = event.params;
    const report = await deliverCoParentHandover(db(), pushService(), {
      householdId,
      linkId,
      data: after.data(),
      now: new Date(event.time),
    });
    if (report !== null) {
      logger.info('co-parent handover announced', { householdId, linkId, created: report.created });
    }
  },
);
