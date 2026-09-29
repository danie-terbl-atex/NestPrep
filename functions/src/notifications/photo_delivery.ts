import { FieldValue, type DocumentReference, type Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { todayIn } from '../documents/expiry_schedule';
import { shiftRef } from '../nanny_hub/nanny_refs';
import { loadRoster, type HouseholdRoster } from './household_roster';
import { deliverDrafts } from './inbox_delivery';
import type { InboxDraft } from './inbox_item';
import type { PushSender } from './push_sender';
import { PHOTO_UPDATE_TEXT } from './push_text';
import { canSee } from './recipients';

/**
 * Delivers a carer's photo update to the family (nanny-hub ADR-0004 — this is
 * its consumer, notifications ADR-0001). An update is born
 * `delivery.state: 'pending'` under its shift; this tells every family member
 * who can see the hub — never the sender — and sets `delivery` to `sent`, or
 * `failed` when there is nobody to tell, with the time, from the Admin SDK.
 * The trigger does it the moment the photo lands; the delivery job catches
 * any the trigger missed.
 *
 * The push says a photo arrived and nothing more — no caption, no child's
 * name. The photo and its words are in the hub, behind the rules.
 */
export const PHOTO_UPDATES = 'photoUpdates';

const pendingUpdate = z.object({
  byMemberId: z.string(),
  delivery: z.object({ state: z.literal('pending') }),
});

export function photoUpdateRef(
  store: Firestore,
  householdId: string,
  shiftId: string,
  updateId: string,
): DocumentReference {
  return shiftRef(store, householdId, shiftId).collection(PHOTO_UPDATES).doc(updateId);
}

/** Who hears about a photo: family with the hub, but not whoever sent it. Pure, and tested. */
export function photoUpdateDrafts(
  roster: HouseholdRoster,
  target: { shiftId: string; updateId: string },
  update: { byMemberId: string },
  localDate: string,
): InboxDraft[] {
  const sender = roster.names[update.byMemberId] ?? 'The carer';
  return roster.recipients
    .filter(
      (recipient) =>
        recipient.isFamily &&
        recipient.memberId !== update.byMemberId &&
        canSee(recipient, 'nannyHub'),
    )
    .map((recipient) => ({
      id: `photo_${target.updateId}_${recipient.memberId}`,
      memberId: recipient.memberId,
      category: 'photos',
      text: PHOTO_UPDATE_TEXT,
      detail: `From ${sender}`,
      sections: [],
      target: { kind: 'photoUpdates', id: target.shiftId },
      source: { kind: 'photoUpdate', id: target.updateId },
      localDate,
    }));
}

export type PhotoOutcome = 'sent' | 'failed' | 'notPending';

export async function deliverPhotoUpdate(
  store: Firestore,
  sender: PushSender,
  target: { householdId: string; shiftId: string; updateId: string; now: Date },
): Promise<PhotoOutcome> {
  const { householdId, shiftId, updateId, now } = target;
  const ref = photoUpdateRef(store, householdId, shiftId, updateId);
  const update = pendingUpdate.safeParse((await ref.get()).data());
  if (!update.success) return 'notPending';
  const roster = await loadRoster(store, householdId);
  const drafts =
    roster === null
      ? []
      : photoUpdateDrafts(roster, { shiftId, updateId }, update.data, todayIn(roster.zone, now));
  if (roster !== null && drafts.length > 0) {
    await deliverDrafts({ store, sender, householdId, zone: roster.zone, now }, drafts);
  }
  const outcome = drafts.length > 0 ? 'sent' : 'failed';
  const batch = store.batch();
  batch.update(ref, { delivery: { state: outcome, at: FieldValue.serverTimestamp() } });
  await batch.commit();
  // Ids and counts only: a photo update is about a child (ENG-22).
  logger.info('photo update delivered', {
    householdId,
    shiftId,
    updateId,
    outcome,
    recipients: drafts.length,
  });
  return outcome;
}

/** The job's backstop: photo updates the trigger never reached. */
export async function deliverPendingPhotoUpdates(
  store: Firestore,
  sender: PushSender,
  now: Date,
): Promise<number> {
  const pending = await store
    .collectionGroup(PHOTO_UPDATES)
    .where('delivery.state', '==', 'pending')
    .limit(50)
    .get();
  let delivered = 0;
  for (const document of pending.docs) {
    // households/{h}/nannyShifts/{s}/photoUpdates/{id}
    const [, householdId, , shiftId] = document.ref.path.split('/');
    if (householdId === undefined || shiftId === undefined) continue;
    const outcome = await deliverPhotoUpdate(store, sender, {
      householdId,
      shiftId,
      updateId: document.id,
      now,
    });
    if (outcome === 'sent') delivered += 1;
  }
  return delivered;
}
