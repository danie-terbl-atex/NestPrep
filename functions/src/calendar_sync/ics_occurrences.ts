import { hash } from 'node:crypto';

import { logger } from 'firebase-functions/v2';

import {
  type ExternalOccurrence,
  type OccurrenceTime,
  type SyncWindow,
  overlapsWindow,
} from './external_occurrence';
import type { IcsDuration, IcsEvent, IcsTime } from './ics_parser';
import { type IcsRule, parseRule, ruleDates } from './ics_rule';
import { addDays, daysBetween, instantOf, wallClockOf } from './zoned_time';

/**
 * An ICS file's events as occurrences inside the sync window (calendar
 * ADR-0003). A repeat is expanded on **the event's own wall clock** — 07:30
 * in its `TZID`, every week — and each occurrence is turned into an instant
 * there, which is what keeps it at 07:30 across a clocks change. A floating
 * time is read in the household's zone.
 */
export function icsOccurrences(
  events: readonly IcsEvent[],
  window: SyncWindow,
): ExternalOccurrence[] {
  // A record and a set rather than a Map: the atomic-writes check reads every
  // Map write in this codebase as a Firestore write.
  const overrides: Record<string, IcsEvent | undefined> = {};
  const used = new Set<string>();
  for (const event of events) {
    if (event.replaces !== null) {
      overrides[`${uidOf(event)}|${keyOf(event.replaces, window.zone)}`] = event;
    }
  }
  const occurrences: ExternalOccurrence[] = [];
  for (const event of events) {
    if (event.replaces !== null) continue;
    for (const start of startsOf(event, window)) {
      const key = keyOf(start, window.zone);
      if (isExcluded(event, start, window.zone)) continue;
      const override = overrides[`${uidOf(event)}|${key}`];
      used.add(`${uidOf(event)}|${key}`);
      const source = override ?? event;
      if (source.isCancelled) continue;
      const time = timeOf(source, override === undefined ? start : source.start, window.zone);
      if (time === null || !overlapsWindow(time, window)) continue;
      occurrences.push({ externalId: `${uidOf(event)}|${key}`, title: source.summary, time });
    }
  }
  // A moved instance whose series is not in the file still happened.
  for (const [key, orphan] of Object.entries(overrides)) {
    if (orphan === undefined || used.has(key)) continue;
    const time = timeOf(orphan, orphan.start, window.zone);
    if (orphan.isCancelled || time === null || !overlapsWindow(time, window)) continue;
    occurrences.push({ externalId: key, title: orphan.summary, time });
  }
  return occurrences;
}

/** The starts of every occurrence the window could touch. */
function startsOf(event: IcsEvent, window: SyncWindow): IcsTime[] {
  if (event.rule === null) return [event.start];
  const zone = zoneOf(event.start, window.zone);
  const startDate = dateOf(event.start, zone);
  const rule = parseRule(event.rule, startDate);
  if (rule === null) {
    logger.info('calendar link rule not supported; imported once', { rule: event.rule });
    return [event.start];
  }
  const lastDate = lastDateOf(rule, window, zone);
  const reach = spanDays(event) + 2;
  return ruleDates(rule, startDate, lastDate, addDays(window.fromDate, -reach)).map((date) =>
    atDate(event.start, date, zone),
  );
}

function lastDateOf(rule: IcsRule, window: SyncWindow, zone: string): string {
  const windowEnd = addDays(window.toDate, 1);
  if (rule.until === null) return windowEnd;
  const until = /^(\d{4})(\d{2})(\d{2})/.exec(rule.until);
  if (until === null) return windowEnd;
  let date = `${until[1] ?? ''}-${until[2] ?? ''}-${until[3] ?? ''}`;
  if (rule.until.endsWith('Z')) {
    const [, h = '00', m = '00'] = /T(\d{2})(\d{2})/.exec(rule.until) ?? [];
    date = wallClockOf(new Date(`${date}T${h}:${m}:00Z`), zone).date;
  }
  return date < windowEnd ? date : windowEnd;
}

/** The same kind of time as [start], moved to [date]. */
function atDate(start: IcsTime, date: string, zone: string): IcsTime {
  switch (start.kind) {
    case 'date':
      return { kind: 'date', date };
    case 'wall':
      return { ...start, date };
    case 'utc':
      return {
        kind: 'utc',
        instant: instantOf(date, wallClockOf(start.instant, zone).minute, zone),
      };
  }
}

function timeOf(event: IcsEvent, start: IcsTime, householdZone: string): OccurrenceTime | null {
  if (start.kind === 'date') {
    const days = Math.max(1, spanDays(event));
    return { kind: 'allDay', startDate: start.date, endDateExclusive: addDays(start.date, days) };
  }
  const startAt = instantOfTime(start, householdZone);
  return {
    kind: 'timed',
    start: startAt,
    end: new Date(startAt.getTime() + durationMs(event, householdZone)),
  };
}

/** Whole days an all-day event covers, from its end or its duration. */
function spanDays(event: IcsEvent): number {
  if (event.end?.kind === 'date' && event.start.kind === 'date') {
    return daysBetween(event.start.date, event.end.date);
  }
  return event.duration?.days ?? (event.start.kind === 'date' ? 1 : 0);
}

function durationMs(event: IcsEvent, householdZone: string): number {
  const { start, end } = event;
  if (end !== null && end.kind !== 'date' && start.kind !== 'date') {
    const elapsed =
      instantOfTime(end, householdZone).getTime() - instantOfTime(start, householdZone).getTime();
    return Math.max(0, elapsed);
  }
  const duration: IcsDuration | null = event.duration;
  return duration === null ? 0 : Math.max(0, duration.days * 86_400_000 + duration.ms);
}

function instantOfTime(time: Exclude<IcsTime, { kind: 'date' }>, householdZone: string): Date {
  if (time.kind === 'utc') return time.instant;
  return instantOf(time.date, time.minute, time.zone ?? householdZone);
}

function zoneOf(time: IcsTime, householdZone: string): string {
  if (time.kind === 'wall') return time.zone ?? householdZone;
  return time.kind === 'utc' ? 'UTC' : householdZone;
}

function dateOf(time: IcsTime, zone: string): string {
  return time.kind === 'utc' ? wallClockOf(time.instant, zone).date : time.date;
}

/** How an occurrence is named for EXDATE and RECURRENCE-ID: its day, or its instant. */
function keyOf(time: IcsTime, householdZone: string): string {
  return time.kind === 'date'
    ? `d:${time.date}`
    : `t:${String(instantOfTime(time, householdZone).getTime())}`;
}

function isExcluded(event: IcsEvent, start: IcsTime, householdZone: string): boolean {
  const key = keyOf(start, householdZone);
  const day = `d:${dateOf(start, zoneOf(start, householdZone))}`;
  return event.excluded.some((excluded) => {
    const excludedKey = keyOf(excluded, householdZone);
    return excludedKey === key || excludedKey === day;
  });
}

function uidOf(event: IcsEvent): string {
  if (event.uid !== '') return event.uid;
  return hash('sha256', `${event.summary}|${JSON.stringify(event.start)}`, 'hex');
}
