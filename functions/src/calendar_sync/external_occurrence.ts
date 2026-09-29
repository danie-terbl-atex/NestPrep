import { hash as digest } from 'node:crypto';

import type { Provider, SyncedEventDocument } from './sync_documents';
import { addDays, instantOf, wallClockOf } from './zoned_time';

/**
 * One occurrence as a provider hands it over, before it is on the household's
 * clock. Every provider adapter produces these and nothing else, so the
 * conversion below is the one place an imported time is decided.
 */
export type OccurrenceTime =
  | { readonly kind: 'timed'; readonly start: Date; readonly end: Date }
  | {
      readonly kind: 'allDay';
      readonly startDate: string;
      /** The day after the last one, as Google, Graph and ICS all write it. */
      readonly endDateExclusive: string;
    };

export interface ExternalOccurrence {
  /** Unique within its connection: an instance id, or a UID plus its start. */
  readonly externalId: string;
  readonly title: string;
  readonly time: OccurrenceTime;
}

/** The days a sync reads: a week back, four months ahead (calendar ADR-0003). */
export interface SyncWindow {
  readonly zone: string;
  readonly fromDate: string;
  readonly toDate: string;
  readonly timeMin: Date;
  readonly timeMax: Date;
}

export const WINDOW_DAYS_BACK = 7;
export const WINDOW_DAYS_AHEAD = 120;
export const MAX_TITLE_LENGTH = 200;

export function syncWindow(zone: string, now: Date): SyncWindow {
  const today = wallClockOf(now, zone).date;
  const fromDate = addDays(today, -WINDOW_DAYS_BACK);
  const toDate = addDays(today, WINDOW_DAYS_AHEAD);
  return {
    zone,
    fromDate,
    toDate,
    timeMin: instantOf(fromDate, 0, zone),
    timeMax: instantOf(addDays(toDate, 1), 0, zone),
  };
}

export interface SyncedEventDraft {
  readonly id: string;
  readonly document: SyncedEventDocument;
}

export interface ConnectionIdentity {
  readonly connectionId: string;
  readonly provider: Provider;
  readonly memberId: string;
  /** The connection's account label, which tells the badge an iCloud link is Apple's. */
  readonly sourceLabel?: string;
}

/**
 * An occurrence on the household's clock. A timed one is converted from its
 * instant — which the provider computed in the event's own zone — so a weekly
 * 07:30 stays 07:30 across a clocks change without this code ever adding a
 * day to an instant (calendar ADR-0002).
 */
export function toSyncedEvent(
  occurrence: ExternalOccurrence,
  connection: ConnectionIdentity,
  zone: string,
): SyncedEventDraft {
  const title = occurrence.title.trim().slice(0, MAX_TITLE_LENGTH);
  const when = placeOnClock(occurrence.time, zone);
  const fields = {
    connectionId: connection.connectionId,
    provider: connection.provider,
    memberId: connection.memberId,
    sourceLabel: connection.sourceLabel ?? '',
    title,
    ...when,
  };
  return {
    id: syncedEventId(connection.connectionId, occurrence.externalId),
    document: { ...fields, fingerprint: hash(JSON.stringify(fields)) },
  };
}

function placeOnClock(
  time: OccurrenceTime,
  zone: string,
): Pick<SyncedEventDocument, 'date' | 'endDate' | 'startMinute' | 'endMinute'> {
  if (time.kind === 'allDay') {
    const lastDay = addDays(time.endDateExclusive, -1);
    return {
      date: time.startDate,
      endDate: lastDay < time.startDate ? time.startDate : lastDay,
      startMinute: null,
      endMinute: null,
    };
  }
  const start = wallClockOf(time.start, zone);
  const end = wallClockOf(time.end < time.start ? time.start : time.end, zone);
  return { date: start.date, endDate: end.date, startMinute: start.minute, endMinute: end.minute };
}

/** Whether an occurrence touches the window at all. */
export function overlapsWindow(time: OccurrenceTime, window: SyncWindow): boolean {
  if (time.kind === 'allDay') {
    return time.startDate <= window.toDate && time.endDateExclusive > window.fromDate;
  }
  return time.start < window.timeMax && time.end > window.timeMin;
}

/** Stable across syncs, so the same occurrence is the same document. */
export function syncedEventId(connectionId: string, externalId: string): string {
  return `${connectionId}_${hash(externalId).slice(0, 24)}`;
}

function hash(text: string): string {
  return digest('sha256', text, 'hex');
}
