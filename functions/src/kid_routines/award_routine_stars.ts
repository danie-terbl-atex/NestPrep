import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { HOUSEHOLDS } from '../household/documents';
import { reconcileRoutine } from './routine_reconcile';
import { KID_ROUTINE_TICKS } from './routine_refs';

/**
 * A routine's step ticked or unticked: its stars follow (kid-routines
 * ADR-0001). The only writer of a child's stars for a routine; it reconciles
 * the award with the tick as it stands, so the event itself decides nothing.
 */
export const awardRoutineStars = onDocumentWritten(
  `${HOUSEHOLDS}/{householdId}/${KID_ROUTINE_TICKS}/{tickId}`,
  async (event) => {
    const { householdId, tickId } = event.params;
    const outcome = await reconcileRoutine(db(), householdId, tickId, new Date());
    logger.info('routine stars reconciled', { householdId, tickId, outcome });
  },
);
