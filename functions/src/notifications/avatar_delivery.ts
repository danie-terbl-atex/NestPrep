import type { Firestore } from 'firebase-admin/firestore';

import { todayIn } from '../documents/expiry_schedule';
import { loadRoster, recipientIn } from './household_roster';
import { deliverDrafts, type DeliveryReport } from './inbox_delivery';
import type { PushSender } from './push_sender';
import { BUDDY_HATCHED_TEXT, PORTRAIT_READY_TEXT } from './push_text';

export interface AvatarReady {
  readonly householdId: string;
  readonly creationId: string;
  readonly requestedBy: string;
  readonly portrait: boolean;
  readonly now: Date;
}

/** Tells whoever asked for a creation that it is ready (avatars ADR-0003), once. */
export async function deliverAvatarReady(
  store: Firestore,
  sender: PushSender,
  ready: AvatarReady,
): Promise<DeliveryReport | null> {
  const roster = await loadRoster(store, ready.householdId);
  if (roster === null || recipientIn(roster, ready.requestedBy) === undefined) return null;
  const id = `avatar_${ready.creationId}`;
  return deliverDrafts(
    {
      store,
      sender,
      householdId: ready.householdId,
      zone: roster.zone,
      now: ready.now,
    },
    [
      {
        id,
        memberId: ready.requestedBy,
        category: 'chores',
        text: ready.portrait ? PORTRAIT_READY_TEXT : BUDDY_HATCHED_TEXT,
        detail: null,
        sections: [],
        target: { kind: 'inboxItem', id },
        source: { kind: 'avatarCreation', id: ready.creationId },
        localDate: todayIn(roster.zone, ready.now),
      },
    ],
  );
}
