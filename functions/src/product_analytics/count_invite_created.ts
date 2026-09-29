import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { INVITES } from '../household/documents';
import { stringField } from './analytics_documents';
import { recordInviteCreated } from './household_cohort_ledger';

/**
 * An invite counts toward its household's invite rate when it is for an adult
 * (product-analytics ADR-0001). The document id is the invite code, which is a
 * secret; it is never read, stored or logged here.
 */
export const countInviteCreated = onDocumentCreated(`${INVITES}/{code}`, async (event) => {
  const householdId = stringField(event.data?.get('householdId'));
  const memberId = stringField(event.data?.get('memberId'));
  if (householdId === undefined || memberId === undefined) {
    logger.error('invite not counted: it names no household or profile');
    return;
  }
  const outcome = await recordInviteCreated(db(), {
    householdId,
    memberId,
    invitedAt: new Date(event.time),
  });
  logger.info('invite counted', { householdId, outcome });
});
