import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { HOUSEHOLDS } from '../household/documents';
import { LUNCH_PLANS } from './analytics_documents';
import { recordLunchPlanCreated } from './household_week_ledger';

/**
 * One lunch plan made, counted against the week it was made in
 * (product-analytics ADR-0001). This is the contract with lunch-box: a
 * document created at `households/{householdId}/lunchPlans/{planId}` is a plan.
 *
 * **The document is never read.** The path says everything the count needs, so
 * a child's name, allergies or lunch cannot reach analytics even by mistake —
 * and lunch-box can change its plan's shape without this noticing. It counts as
 * soon as the collection exists; until then it simply never fires.
 */
export const countLunchPlanCreated = onDocumentCreated(
  `${HOUSEHOLDS}/{householdId}/${LUNCH_PLANS}/{planId}`,
  async (event) => {
    const { householdId, planId } = event.params;
    const week = await recordLunchPlanCreated(db(), {
      householdId,
      planId,
      createdAt: new Date(event.time),
    });
    logger.info('lunch plan counted', { householdId, week });
  },
);
