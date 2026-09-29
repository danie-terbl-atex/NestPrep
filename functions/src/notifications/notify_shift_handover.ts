import { onDocumentCreated } from 'firebase-functions/v2/firestore';

import { HOUSEHOLDS } from '../household/documents';
import { SUMMARIES } from '../nanny_hub/nanny_refs';
import { db } from '../shared/firestore';
import { pushService } from './push_service';
import { deliverShiftSummary } from './shift_delivery';

/**
 * A shift has ended and its summary is written: the family hears at once
 * (nanny-hub ADR-0002, notifications ADR-0001). A retried delivery finds the
 * summary no longer `pending`, and the inbox items already there.
 */
export const notifyShiftHandover = onDocumentCreated(
  `${HOUSEHOLDS}/{householdId}/${SUMMARIES}/{shiftId}`,
  async (event) => {
    const { householdId, shiftId } = event.params;
    await deliverShiftSummary(db(), pushService(), {
      householdId,
      shiftId,
      now: new Date(event.time),
    });
  },
);
