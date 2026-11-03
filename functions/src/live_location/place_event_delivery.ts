import type { Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { todayIn } from '../documents/expiry_schedule';
import { loadRoster, type HouseholdRoster } from '../notifications/household_roster';
import { deliverDrafts } from '../notifications/inbox_delivery';
import type { InboxDraft } from '../notifications/inbox_item';
import type { PushSender } from '../notifications/push_sender';
import {
  PLACE_ARRIVAL_TEXT,
  PLACE_DEPARTURE_TEXT,
  type PushText,
} from '../notifications/push_text';
import { canSee } from '../notifications/recipients';
import { PLACE_EVENTS, placeRef, trailRef } from './location_refs';

export type PlaceEventKind = 'arrive' | 'leave';

const placeEvent = z.object({
  placeId: z.string().min(1),
  kind: z.enum(['arrive', 'leave']),
});

const storedPlace = z.object({
  name: z.string(),
  alerts: z.object({ arrive: z.boolean(), leave: z.boolean() }),
});

const lastEvent = z.object({ kind: z.enum(['arrive', 'leave']), at: z.number() });

const storedTrail = z.object({
  lastPlaceEvents: z.record(z.string(), z.unknown()).default({}),
});

/** The same kind again this soon is the same crossing told twice. */
export const REPEAT_WINDOW_MS = 30 * 60 * 1000;

/** Anything at all this soon after the last crossing is a fence flapping. */
export const FLAP_WINDOW_MS = 2 * 60 * 1000;

/**
 * Whether a crossing is news. A missed exit must not silence tomorrow's
 * arrival, so a repeat is only a repeat inside the window. Pure, and tested.
 */
export function isNews(previous: unknown, kind: PlaceEventKind, nowMs: number): boolean {
  const last = lastEvent.safeParse(previous);
  if (!last.success) return true;
  const since = nowMs - last.data.at;
  if (since < FLAP_WINDOW_MS) return false;
  return !(last.data.kind === kind && since < REPEAT_WINDOW_MS);
}

export interface PlaceEventTarget {
  readonly householdId: string;
  readonly memberId: string;
  readonly eventId: string;
  readonly now: Date;
}

/**
 * Everybody who can see the map hears, except the person who moved. Family
 * see who and where on the lock screen (notifications ADR-0004); anybody else
 * sees the kind only, with the names behind sign-in. Pure, and tested.
 */
export function placeEventDrafts(
  roster: HouseholdRoster,
  target: { memberId: string; eventId: string },
  event: { kind: PlaceEventKind; placeName: string },
  localDate: string,
): InboxDraft[] {
  const who = roster.names[target.memberId] ?? 'Somebody';
  const detail =
    event.kind === 'arrive'
      ? `${who} arrived at ${event.placeName}`
      : `${who} left ${event.placeName}`;
  return roster.recipients
    .filter((recipient) => recipient.memberId !== target.memberId && canSee(recipient, 'location'))
    .map((recipient) => ({
      id: `place_${target.eventId}_${recipient.memberId}`,
      memberId: recipient.memberId,
      category: 'places',
      text: recipient.isFamily
        ? namedText(who, detail, event.kind)
        : event.kind === 'arrive'
          ? PLACE_ARRIVAL_TEXT
          : PLACE_DEPARTURE_TEXT,
      detail,
      sections: [],
      target: { kind: 'whereWeAre', id: target.memberId },
      source: { kind: 'placeEvent', id: target.eventId },
      localDate,
    }));
}

function namedText(who: string, detail: string, kind: PlaceEventKind): PushText {
  return { title: kind === 'arrive' ? `${who} arrived` : `${who} left`, body: detail };
}

export type PlaceEventOutcome = 'sent' | 'repeat' | 'silenced' | 'nobody' | 'unreadable';

/**
 * A geofence that flaps, or a retried trigger, says the same thing twice; the
 * trail document remembers the last crossing per place, and `isNews` decides.
 */
export async function deliverPlaceEvent(
  store: Firestore,
  sender: PushSender,
  target: PlaceEventTarget,
): Promise<PlaceEventOutcome> {
  const { householdId, memberId, eventId, now } = target;
  const trail = trailRef(store, householdId, memberId);
  const event = placeEvent.safeParse(
    (await trail.collection(PLACE_EVENTS).doc(eventId).get()).data(),
  );
  if (!event.success) return 'unreadable';
  const { placeId, kind } = event.data;

  const change = await store.runTransaction(async (transaction) => {
    const [trailSnapshot, placeSnapshot] = await Promise.all([
      transaction.get(trail),
      transaction.get(placeRef(store, householdId, placeId)),
    ]);
    const last = storedTrail.safeParse(trailSnapshot.data() ?? {});
    const previous = last.success ? last.data.lastPlaceEvents[placeId] : undefined;
    if (!isNews(previous, kind, now.getTime())) return null;
    transaction.set(
      trail,
      { lastPlaceEvents: { [placeId]: { kind, at: now.getTime() } } },
      { merge: true },
    );
    const place = storedPlace.safeParse(placeSnapshot.data());
    return place.success ? place.data : 'gone';
  });
  if (change === null) return 'repeat';
  if (change === 'gone' || !change.alerts[kind]) return 'silenced';

  const roster = await loadRoster(store, householdId);
  if (roster === null) return 'nobody';
  const drafts = placeEventDrafts(
    roster,
    { memberId, eventId },
    { kind, placeName: change.name },
    todayIn(roster.zone, now),
  );
  if (drafts.length === 0) return 'nobody';
  await deliverDrafts({ store, sender, householdId, zone: roster.zone, now }, drafts);
  logger.info('place event delivered', { householdId, eventId, kind, recipients: drafts.length });
  return 'sent';
}
