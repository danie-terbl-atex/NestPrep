import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { REWARD_REQUESTS } from '../chore_points/point_refs';
import { HOUSEHOLDS } from '../household/documents';
import { db } from '../shared/firestore';
import { deliverRewardAsked } from './chore_delivery';
import { pushService } from './push_service';

/**
 * A child's reward request is waiting to be handed over: the family hears
 * (todos ADR-0003, notifications ADR-0001). Only the move into `waiting`
 * tells anybody.
 */
export const notifyRewardRequest = onDocumentWritten(
  `${HOUSEHOLDS}/{householdId}/${REWARD_REQUESTS}/{requestId}`,
  async (event) => {
    const { householdId, requestId } = event.params;
    const report = await deliverRewardAsked(db(), pushService(), {
      householdId,
      documentId: requestId,
      before: event.data?.before.data(),
      after: event.data?.after.data(),
      now: new Date(event.time),
    });
    if (report !== null) {
      logger.info('reward request announced', { householdId, requestId, created: report.created });
    }
  },
);
