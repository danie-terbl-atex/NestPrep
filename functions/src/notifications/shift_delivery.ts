import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { summaryRef, SUMMARIES } from '../nanny_hub/nanny_refs';
import { todayIn } from '../documents/expiry_schedule';
import { loadRoster, type HouseholdRoster } from './household_roster';
import { deliverDrafts } from './inbox_delivery';
import type { InboxDraft } from './inbox_item';
import type { PushSender } from './push_sender';
import { HANDOVER_TEXT } from './push_text';
import { canSee } from './recipients';

/**
 * Delivers a shift's handover to the family (nanny-hub ADR-0002 — this is its
 * consumer). A summary is born `delivery.state: 'pending'`; this sends it to
 * every family member who can see the hub and sets `delivery` to `sent` — or
 * `failed` when there is nobody to send it to — with the time, from the
 * Admin SDK. The trigger does it the moment the shift ends; the delivery job
 * catches any the trigger missed.
 *
 * The push says a handover is ready and nothing more; the carer's words are
 * in the hub, behind the rules.
 */
const pendingSummary = z.object({
  carerMemberId: z.string(),
  entryCount: z.number().int().min(0).default(0),
  delivery: z.object({ state: z.literal('pending') }),
});

/** Who hears about a handover: family with the hub. Pure, and tested. */
export function handoverDrafts(
  roster: HouseholdRoster,
  shiftId: string,
  summary: { carerMemberId: string; entryCount: number },
  localDate: string,
): InboxDraft[] {
  const carer = roster.names[summary.carerMemberId] ?? 'The carer';
  const moments = summary.entryCount === 1 ? '1 moment' : `${String(summary.entryCount)} moments`;
  return roster.recipients
    .filter((recipient) => recipient.isFamily && canSee(recipient, 'nannyHub'))
    .map((recipient) => ({
      id: `handover_${shiftId}_${recipient.memberId}`,
      memberId: recipient.memberId,
      category: 'handover',
      text: HANDOVER_TEXT,
      detail: `From ${carer} · ${moments}`,
      sections: [],
      target: { kind: 'shiftSummary', id: shiftId },
      source: { kind: 'shiftSummary', id: shiftId },
      localDate,
    }));
}

export type HandoverOutcome = 'sent' | 'failed' | 'notPending';

export async function deliverShiftSummary(
  store: Firestore,
  sender: PushSender,
  target: { householdId: string; shiftId: string; now: Date },
): Promise<HandoverOutcome> {
  const { householdId, shiftId, now } = target;
  const ref = summaryRef(store, householdId, shiftId);
  const summary = pendingSummary.safeParse((await ref.get()).data());
  if (!summary.success) return 'notPending';
  const roster = await loadRoster(store, householdId);
  const drafts =
    roster === null ? [] : handoverDrafts(roster, shiftId, summary.data, todayIn(roster.zone, now));
  if (roster !== null && drafts.length > 0) {
    await deliverDrafts({ store, sender, householdId, zone: roster.zone, now }, drafts);
  }
  const outcome = drafts.length > 0 ? 'sent' : 'failed';
  const batch = store.batch();
  batch.update(ref, { delivery: { state: outcome, at: FieldValue.serverTimestamp() } });
  await batch.commit();
  logger.info('shift handover delivered', {
    householdId,
    shiftId,
    outcome,
    recipients: drafts.length,
  });
  return outcome;
}

/** The job's backstop: summaries the trigger never reached. */
export async function deliverPendingSummaries(
  store: Firestore,
  sender: PushSender,
  now: Date,
): Promise<number> {
  const pending = await store
    .collectionGroup(SUMMARIES)
    .where('delivery.state', '==', 'pending')
    .limit(50)
    .get();
  let delivered = 0;
  for (const document of pending.docs) {
    const householdId = document.ref.path.split('/')[1];
    if (householdId === undefined) continue;
    const outcome = await deliverShiftSummary(store, sender, {
      householdId,
      shiftId: document.id,
      now,
    });
    if (outcome === 'sent') delivered += 1;
  }
  return delivered;
}
