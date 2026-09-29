import type { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { todayIn } from '../documents/expiry_schedule';
import { loadRoster, type HouseholdRoster } from './household_roster';
import { deliverDrafts, type DeliveryReport } from './inbox_delivery';
import type { InboxDraft } from './inbox_item';
import type { PushSender } from './push_sender';
import { CHORE_CHECK_TEXT, REWARD_ASKED_TEXT, type PushText } from './push_text';

/**
 * Tells the family when a child's stars wait on them (todos ADR-0003): a
 * starred chore that needs a check, and a reward a child asked for. Both are
 * decisions only family may make, so only family hears.
 *
 * The decisions — "is this a new thing to check?" — are pure over the
 * document before and after, so a trigger delivered twice, or a write that
 * changes nothing that matters, tells nobody twice.
 */

const claimShape = z.object({
  memberId: z.string(),
  title: z.string(),
  status: z.string(),
  round: z.number().int().default(1),
});

/** The round of a claim that has just started waiting for a parent, or null. */
export function claimNowWaiting(before: unknown, after: unknown): number | null {
  const now = claimShape.safeParse(after);
  if (!now.success || now.data.status !== 'pending') return null;
  const was = claimShape.safeParse(before);
  if (was.success && was.data.status === 'pending' && was.data.round === now.data.round)
    return null;
  return now.data.round;
}

const requestShape = z.object({ memberId: z.string(), status: z.string().optional() });

/** Whether a reward request has just started waiting to be handed over. */
export function rewardNowWaiting(before: unknown, after: unknown): boolean {
  const now = requestShape.safeParse(after);
  if (!now.success || now.data.status !== 'waiting') return false;
  const was = requestShape.safeParse(before);
  return !(was.success && was.data.status === 'waiting');
}

interface FamilyNotice {
  readonly idPrefix: string;
  readonly text: PushText;
  readonly detail: string;
  readonly sourceKind: string;
  readonly sourceId: string;
  readonly localDate: string;
}

export function familyDrafts(roster: HouseholdRoster, notice: FamilyNotice): InboxDraft[] {
  return roster.recipients
    .filter((recipient) => recipient.isFamily)
    .map((recipient) => ({
      id: `${notice.idPrefix}_${recipient.memberId}`,
      memberId: recipient.memberId,
      category: 'chores',
      text: notice.text,
      detail: notice.detail,
      sections: [],
      target: { kind: 'stars', id: null },
      source: { kind: notice.sourceKind, id: notice.sourceId },
      localDate: notice.localDate,
    }));
}

export interface ChoreEvent {
  readonly householdId: string;
  readonly documentId: string;
  readonly before: unknown;
  readonly after: unknown;
  readonly now: Date;
}

export async function deliverChoreCheck(
  store: Firestore,
  sender: PushSender,
  event: ChoreEvent,
): Promise<DeliveryReport | null> {
  const round = claimNowWaiting(event.before, event.after);
  const claim = claimShape.safeParse(event.after);
  if (round === null || !claim.success) return null;
  const roster = await loadRoster(store, event.householdId);
  if (roster === null) return null;
  const child = roster.names[claim.data.memberId] ?? 'A child';
  const drafts = familyDrafts(roster, {
    idPrefix: `chore_${event.documentId}_${String(round)}`,
    text: CHORE_CHECK_TEXT,
    detail: `${child} · ${claim.data.title}`,
    sourceKind: 'pointClaim',
    sourceId: event.documentId,
    localDate: todayIn(roster.zone, event.now),
  });
  return deliverDrafts(
    { store, sender, householdId: event.householdId, zone: roster.zone, now: event.now },
    drafts,
  );
}

export async function deliverRewardAsked(
  store: Firestore,
  sender: PushSender,
  event: ChoreEvent,
): Promise<DeliveryReport | null> {
  const request = requestShape.safeParse(event.after);
  if (!rewardNowWaiting(event.before, event.after) || !request.success) return null;
  const roster = await loadRoster(store, event.householdId);
  if (roster === null) return null;
  const child = roster.names[request.data.memberId] ?? 'A child';
  const drafts = familyDrafts(roster, {
    idPrefix: `reward_${event.documentId}`,
    text: REWARD_ASKED_TEXT,
    detail: `${child} asked for a reward`,
    sourceKind: 'rewardRequest',
    sourceId: event.documentId,
    localDate: todayIn(roster.zone, event.now),
  });
  return deliverDrafts(
    { store, sender, householdId: event.householdId, zone: roster.zone, now: event.now },
    drafts,
  );
}
