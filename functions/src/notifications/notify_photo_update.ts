import { onDocumentCreated } from 'firebase-functions/v2/firestore';

import { HOUSEHOLDS } from '../household/documents';
import { SHIFTS } from '../nanny_hub/nanny_refs';
import { db } from '../shared/firestore';
import { deliverPhotoUpdate, PHOTO_UPDATES } from './photo_delivery';
import { pushService } from './push_service';

/**
 * A carer sent a photo mid-shift: the family hears at once (nanny-hub
 * ADR-0004, notifications ADR-0001). A retried delivery finds the update no
 * longer `pending`, and the inbox items already there.
 */
export const notifyPhotoUpdate = onDocumentCreated(
  `${HOUSEHOLDS}/{householdId}/${SHIFTS}/{shiftId}/${PHOTO_UPDATES}/{updateId}`,
  async (event) => {
    const { householdId, shiftId, updateId } = event.params;
    await deliverPhotoUpdate(db(), pushService(), {
      householdId,
      shiftId,
      updateId,
      now: new Date(event.time),
    });
  },
);
