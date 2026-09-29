import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { HOUSEHOLDS } from '../household/documents';
import { stringField } from './analytics_documents';
import { recordHouseholdCreated } from './household_cohort_ledger';

/**
 * A new household joins the invite-rate cohort of the week it was made in
 * (product-analytics ADR-0001). The time is the event's — when the document was
 * written — so nothing a client sent can move a household between cohorts.
 * Only the timezone is read off the document; its name never is.
 */
export const countHouseholdCreated = onDocumentCreated(
  `${HOUSEHOLDS}/{householdId}`,
  async (event) => {
    const { householdId } = event.params;
    await recordHouseholdCreated(db(), {
      householdId,
      createdAt: new Date(event.time),
      timeZone: stringField(event.data?.get('timeZone')),
    });
    logger.info('household counted into its cohort', { householdId });
  },
);
