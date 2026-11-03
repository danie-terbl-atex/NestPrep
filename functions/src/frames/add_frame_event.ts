import { FieldValue } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';

import { parseInput } from '../household/parse_input';
import { db } from '../shared/firestore';
import { readLinkedFrame } from './frame_access';
import { refuseFrame } from './frame_errors';
import {
  adderNamed,
  frameEventDocument,
  frameEventId,
  inEventReach,
  peopleNamed,
} from './frame_events';
import { FRAME_ADD_EVENT_PER_CREDENTIAL, FRAME_DEVICE_OPTIONS, addsEvents } from './frame_policy';
import { readMembersWithGrants } from './frame_reads';
import { addFrameEventInput } from './frame_schemas';

export type AddFrameEventResult = { status: 'unlinked' } | { status: 'linked'; added: true };

const UNLINKED: AddFrameEventResult = { status: 'unlinked' };

/**
 * A linked frame adds an event to the household's calendar (photo-frames
 * ADR-0008), by writing exactly the document the app would, credited to the
 * calendar editor who says they are adding it — so they, or an admin, edit
 * and delete it from their phone. Only while the frame shows the calendar
 * and family switched adding on. A retry with the same `requestId` answers
 * added and writes nothing.
 */
export const addFrameEvent = onCall(
  FRAME_DEVICE_OPTIONS,
  async (request): Promise<AddFrameEventResult> => {
    const input = parseInput(addFrameEventInput, request.data);
    const store = db();
    const linked = await readLinkedFrame(store, input.secret, FRAME_ADD_EVENT_PER_CREDENTIAL);
    if (linked === null) return UNLINKED;
    if (!addsEvents(linked.frame.panels)) throw refuseFrame('addingOff');
    if (!inEventReach(input.date, linked.clock.date)) throw refuseFrame('eventOutOfReach');

    const { names, adders } = await readMembersWithGrants(linked.home);
    const createdBy = adderNamed(adders, names, input.by);
    const memberIds = peopleNamed(input.who, names);

    const events = linked.home.collection('events');
    const ref =
      input.requestId === null
        ? events.doc()
        : events.doc(frameEventId(linked.frameId, input.requestId));
    await store.runTransaction(async (transaction) => {
      if ((await transaction.get(ref)).exists) return;
      transaction.create(ref, {
        ...frameEventDocument(input, createdBy, memberIds),
        createdAt: FieldValue.serverTimestamp(),
      });
    });
    return { status: 'linked', added: true };
  },
);
