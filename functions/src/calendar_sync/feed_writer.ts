import { z } from 'zod';

import { addDays, instantOf } from './zoned_time';

/**
 * The household's own events as an iCalendar feed (calendar ADR-0003) — what
 * Apple, Google or Outlook subscribe to. Each event keeps its rule: an `RRULE`
 * on the household's `TZID`, so 07:30 every weekday stays 07:30 in whatever
 * calendar shows it, and a skipped occurrence is an `EXDATE`. Titles and times
 * only: no notes, no names.
 */
export const storedRecurrence = z.object({
  frequency: z.enum(['daily', 'weekly', 'monthly']),
  interval: z.number().int().min(1).max(366),
  weekdays: z.array(z.number().int().min(1).max(7)),
  until: z.string().nullable(),
});

export const storedEvent = z.object({
  title: z.string(),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  startMinute: z.number().int().min(0).max(1439).nullable().optional(),
  endMinute: z.number().int().min(0).max(1439).nullable().optional(),
  recurrence: storedRecurrence.nullable().optional(),
});

export type StoredEvent = z.infer<typeof storedEvent>;

export interface FeedEvent {
  readonly id: string;
  readonly event: StoredEvent;
  /** Skipped occurrences, as `YYYY-MM-DD`. */
  readonly skipped: readonly string[];
}

export interface FeedInput {
  readonly calendarName: string;
  readonly zone: string;
  readonly events: readonly FeedEvent[];
  readonly now: Date;
}

const CODES = ['', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
const DEFAULT_MINUTES = 60;

export function writeFeed(input: FeedInput): string {
  const lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//NestPrep//Family week//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    `X-WR-CALNAME:${escapeText(input.calendarName)}`,
    `X-WR-TIMEZONE:${input.zone}`,
    'REFRESH-INTERVAL;VALUE=DURATION:PT1H',
    'X-PUBLISHED-TTL:PT1H',
    ...input.events.flatMap((feedEvent) => eventLines(feedEvent, input)),
    'END:VCALENDAR',
  ];
  return `${lines.map(fold).join('\r\n')}\r\n`;
}

function eventLines({ id, event, skipped }: FeedEvent, input: FeedInput): string[] {
  const start = event.startMinute ?? null;
  const lines = [
    'BEGIN:VEVENT',
    `UID:${id}@nestprep`,
    `DTSTAMP:${utcStamp(input.now)}`,
    `SUMMARY:${escapeText(event.title)}`,
  ];
  if (start === null) {
    lines.push(`DTSTART;VALUE=DATE:${compact(event.date)}`);
    lines.push(`DTEND;VALUE=DATE:${compact(addDays(event.date, 1))}`);
  } else {
    const end = event.endMinute ?? (start + DEFAULT_MINUTES) % 1440;
    // An end before the start is the next morning (calendar ADR-0002).
    const endDate = end <= start ? addDays(event.date, 1) : event.date;
    lines.push(`DTSTART;TZID=${input.zone}:${local(event.date, start)}`);
    lines.push(`DTEND;TZID=${input.zone}:${local(endDate, end)}`);
  }
  const rule = event.recurrence;
  if (rule !== null && rule !== undefined) lines.push(ruleLine(rule, event, input.zone));
  if (rule !== null && rule !== undefined && skipped.length > 0) {
    lines.push(
      start === null
        ? `EXDATE;VALUE=DATE:${skipped.map(compact).join(',')}`
        : `EXDATE;TZID=${input.zone}:${skipped.map((day) => local(day, start)).join(',')}`,
    );
  }
  lines.push('END:VEVENT');
  return lines;
}

function ruleLine(
  rule: z.infer<typeof storedRecurrence>,
  event: StoredEvent,
  zone: string,
): string {
  const parts = [`FREQ=${rule.frequency.toUpperCase()}`, `INTERVAL=${String(rule.interval)}`];
  if (rule.frequency === 'weekly') {
    const weekdays = rule.weekdays.length > 0 ? rule.weekdays : [weekdayOfDate(event.date)];
    parts.push(
      `BYDAY=${[...weekdays]
        .sort()
        .map((day) => CODES[day] ?? '')
        .join(',')}`,
    );
  }
  if (rule.frequency === 'monthly') parts.push(`BYMONTHDAY=${String(Number(event.date.slice(8)))}`);
  if (rule.until !== null) {
    // RFC 5545: with a zoned start, UNTIL is the UTC instant; with a date, a date.
    parts.push(
      event.startMinute === null || event.startMinute === undefined
        ? `UNTIL=${compact(rule.until)}`
        : `UNTIL=${utcStamp(new Date(instantOf(addDays(rule.until, 1), 0, zone).getTime() - 1000))}`,
    );
  }
  return `RRULE:${parts.join(';')}`;
}

function weekdayOfDate(date: string): number {
  const day = new Date(`${date}T00:00:00Z`).getUTCDay();
  return day === 0 ? 7 : day;
}

function compact(date: string): string {
  return date.replace(/-/g, '');
}

function local(date: string, minute: number): string {
  const hours = String(Math.floor(minute / 60)).padStart(2, '0');
  const minutes = String(minute % 60).padStart(2, '0');
  return `${compact(date)}T${hours}${minutes}00`;
}

function utcStamp(instant: Date): string {
  return `${instant.toISOString().replace(/[-:]/g, '').slice(0, 15)}Z`;
}

export function escapeText(text: string): string {
  return text
    .replace(/\\/g, '\\\\')
    .replace(/;/g, '\\;')
    .replace(/,/g, '\\,')
    .replace(/\r?\n/g, '\\n');
}

/** Lines longer than 75 octets continue on the next line after a space (RFC 5545). */
export function fold(line: string): string {
  const bytes = Buffer.from(line, 'utf8');
  if (bytes.length <= 75) return line;
  const pieces: string[] = [];
  let current = '';
  for (const char of line) {
    const limit = pieces.length === 0 ? 75 : 74;
    if (Buffer.byteLength(current + char, 'utf8') > limit) {
      pieces.push(current);
      current = char;
    } else {
      current += char;
    }
  }
  pieces.push(current);
  return pieces.join('\r\n ');
}
