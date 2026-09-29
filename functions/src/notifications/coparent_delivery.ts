import type { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { authorityRef } from '../coparent/coparent_refs';
import { side as sideSchema, SIDES, type Side } from '../coparent/schedule_schema';
import { todayIn } from '../documents/expiry_schedule';
import { loadRoster, type HouseholdRoster } from './household_roster';
import { deliverDrafts, type DeliveryReport } from './inbox_delivery';
import type { InboxDraft } from './inbox_item';
import type { PushSender } from './push_sender';
import {
  COPARENT_HANDOVER_TEXT,
  COPARENT_SCHEDULE_TEXT,
  COPARENT_SWAP_TEXT,
  type PushText,
} from './push_text';
import { canSee, type Recipient } from './recipients';

/**
 * Tells a home when the other home of a co-parent link asks for a change or
 * leaves a handover note (household ADR-0004, notifications ADR-0001).
 *
 * The co-parenting Functions write every request and handover to both homes'
 * mirrors at once, so a trigger fires in each household. Each household's
 * copy says which side wrote it; only the copy in the *other* home produces
 * anything, so nobody is told about their own request, and each home's
 * people are told only from their own household's documents — nothing of
 * either household crosses.
 *
 * Who hears: the receiving home's admins, the ones who answer a change —
 * and for a handover, only those who may also read medical, as the rules
 * require to open one. The push names no child, no date and no home; the
 * inbox line carries the dates, behind the rules.
 */

const authority = z.object({
  householdIds: z.object({ a: z.string(), b: z.string() }),
});

const storedRequest = z.object({
  kind: z.enum(['swap', 'schedule']),
  proposedBySide: sideSchema,
  status: z.string(),
  from: z.string().optional(),
  to: z.string().optional(),
});

const storedHandover = z.object({
  date: z.string(),
  updatedBySide: sideSchema,
});

/** Which side [householdId] is on the link, or null when it is not on it. */
async function sideOf(store: Firestore, linkId: string, householdId: string): Promise<Side | null> {
  const link = authority.safeParse((await authorityRef(store, linkId).get()).data());
  if (!link.success) return null;
  return SIDES.find((candidate) => link.data.householdIds[candidate] === householdId) ?? null;
}

function answersChanges(recipient: Recipient): boolean {
  return recipient.role === 'admin' && canSee(recipient, 'calendar');
}

/** Drafts for this home's admins about a request the other home made. Pure, and tested. */
export function requestDrafts(
  roster: HouseholdRoster,
  target: { linkId: string; requestId: string },
  request: { kind: 'swap' | 'schedule'; from?: string | undefined; to?: string | undefined },
  localDate: string,
): InboxDraft[] {
  const text: PushText = request.kind === 'swap' ? COPARENT_SWAP_TEXT : COPARENT_SCHEDULE_TEXT;
  const detail =
    request.kind === 'swap' && request.from !== undefined && request.to !== undefined
      ? `Days ${request.from} to ${request.to}`
      : null;
  return roster.recipients.filter(answersChanges).map((recipient) => ({
    id: `coparent_request_${target.requestId}_${recipient.memberId}`,
    memberId: recipient.memberId,
    category: 'coParenting',
    text,
    detail,
    sections: [],
    target: { kind: 'coParentLink', id: target.linkId },
    source: { kind: 'coParentRequest', id: target.requestId },
    localDate,
  }));
}

/** Drafts for this home's admins about a handover note the other home wrote. Pure, and tested. */
export function handoverNoteDrafts(
  roster: HouseholdRoster,
  target: { linkId: string; date: string },
  localDate: string,
): InboxDraft[] {
  return roster.recipients
    .filter((recipient) => answersChanges(recipient) && canSee(recipient, 'medical'))
    .map((recipient) => ({
      // One per handover day: the first note from the other home tells; its
      // later edits are in the handover itself.
      id: `coparent_handover_${target.linkId}_${target.date}_${recipient.memberId}`,
      memberId: recipient.memberId,
      category: 'coParenting',
      text: COPARENT_HANDOVER_TEXT,
      detail: `For ${target.date}`,
      sections: [],
      target: { kind: 'coParentLink', id: target.linkId },
      source: { kind: 'coParentHandover', id: `${target.linkId}_${target.date}` },
      localDate,
    }));
}

interface CoParentEvent {
  readonly householdId: string;
  readonly linkId: string;
  readonly now: Date;
}

async function deliverFromTheOtherSide(
  store: Firestore,
  sender: PushSender,
  event: CoParentEvent,
  writtenBy: Side,
  draftsFor: (roster: HouseholdRoster, localDate: string) => InboxDraft[],
): Promise<DeliveryReport | null> {
  const own = await sideOf(store, event.linkId, event.householdId);
  if (own === null || own === writtenBy) return null;
  const roster = await loadRoster(store, event.householdId);
  if (roster === null) return null;
  const drafts = draftsFor(roster, todayIn(roster.zone, event.now));
  return deliverDrafts(
    { store, sender, householdId: event.householdId, zone: roster.zone, now: event.now },
    drafts,
  );
}

/** A new request in this home's mirror: told only when the other home made it, and only while it waits. */
export async function deliverCoParentRequest(
  store: Firestore,
  sender: PushSender,
  event: CoParentEvent & { requestId: string; data: unknown },
): Promise<DeliveryReport | null> {
  const request = storedRequest.safeParse(event.data);
  if (!request.success || request.data.status !== 'pending') return null;
  return deliverFromTheOtherSide(store, sender, event, request.data.proposedBySide, (roster, day) =>
    requestDrafts(roster, { linkId: event.linkId, requestId: event.requestId }, request.data, day),
  );
}

/** A handover written in this home's mirror: told only when the other home wrote it. */
export async function deliverCoParentHandover(
  store: Firestore,
  sender: PushSender,
  event: CoParentEvent & { data: unknown },
): Promise<DeliveryReport | null> {
  const handover = storedHandover.safeParse(event.data);
  if (!handover.success) return null;
  return deliverFromTheOtherSide(store, sender, event, handover.data.updatedBySide, (roster, day) =>
    handoverNoteDrafts(roster, { linkId: event.linkId, date: handover.data.date }, day),
  );
}
