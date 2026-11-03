import { onDocumentCreated } from 'firebase-functions/v2/firestore';

import { HOUSEHOLDS } from '../household/documents';
import { pushService } from '../notifications/push_service';
import { db } from '../shared/firestore';
import { LOCATION_TRAILS, PLACE_EVENTS } from './location_refs';
import { deliverPlaceEvent } from './place_event_delivery';

/** A member's phone crossed one of the household's places (live-location ADR-0006). */
export const notifyPlaceEvent = onDocumentCreated(
  `${HOUSEHOLDS}/{householdId}/${LOCATION_TRAILS}/{memberId}/${PLACE_EVENTS}/{eventId}`,
  async (event) => {
    const { householdId, memberId, eventId } = event.params;
    await deliverPlaceEvent(db(), pushService(), {
      householdId,
      memberId,
      eventId,
      now: new Date(event.time),
    });
  },
);
