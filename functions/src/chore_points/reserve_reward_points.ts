import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { HOUSEHOLDS } from '../household/documents';
import { REWARD_REQUESTS } from './point_refs';
import { reserveReward } from './reward_reservation';

/**
 * A reward asked for: its stars are taken off, or the request is refused
 * (todos ADR-0003). The only thing that gives a request a status other than a
 * parent's `settleReward`.
 */
export const reserveRewardPoints = onDocumentCreated(
  `${HOUSEHOLDS}/{householdId}/${REWARD_REQUESTS}/{requestId}`,
  async (event) => {
    const { householdId, requestId } = event.params;
    const outcome = await reserveReward(db(), householdId, requestId);
    logger.info('reward request settled', { householdId, requestId, outcome });
  },
);
