import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { POINT_CLAIMS } from '../chore_points/point_refs';
import { HOUSEHOLDS } from '../household/documents';
import { db } from '../shared/firestore';
import { deliverChoreCheck } from './chore_delivery';
import { pushService } from './push_service';

/**
 * A starred chore now waits on a parent's check: the family hears (todos
 * ADR-0003, notifications ADR-0001). Only a claim that has *just* become
 * pending — or a new round of one — tells anybody; every other write to a
 * claim is silent.
 */
export const notifyChoreCheck = onDocumentWritten(
  `${HOUSEHOLDS}/{householdId}/${POINT_CLAIMS}/{claimId}`,
  async (event) => {
    const { householdId, claimId } = event.params;
    const report = await deliverChoreCheck(db(), pushService(), {
      householdId,
      documentId: claimId,
      before: event.data?.before.data(),
      after: event.data?.after.data(),
      now: new Date(event.time),
    });
    if (report !== null) {
      logger.info('chore check announced', { householdId, claimId, created: report.created });
    }
  },
);
