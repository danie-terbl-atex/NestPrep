import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { HOUSEHOLDS } from '../household/documents';
import { reconcileChore } from './chore_reconcile';
import { TASK_COMPLETIONS } from './point_refs';

/**
 * A chore ticked, unticked or changed: its stars follow (todos ADR-0003).
 *
 * The only writer of a child's stars for a chore. It listens on every write to
 * a completion and reconciles the claim with the completion as it stands, so
 * the event itself — which may arrive twice, or late — decides nothing.
 */
export const awardChorePoints = onDocumentWritten(
  `${HOUSEHOLDS}/{householdId}/${TASK_COMPLETIONS}/{completionId}`,
  async (event) => {
    const { householdId, completionId } = event.params;
    const outcome = await reconcileChore(db(), householdId, completionId, new Date());
    logger.info('chore points reconciled', { householdId, completionId, outcome });
  },
);
