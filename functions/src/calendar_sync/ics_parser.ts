import { isKnownZone } from './zoned_time';

/**
 * Reads the parts of an iCalendar (RFC 5545) file that a family calendar
 * carries: each `VEVENT`'s UID, summary, status, start, end or duration,
 * repeat rule, excluded dates and — for an instance that was moved — the
 * occurrence it replaces (calendar ADR-0003). Everything else is skipped.
 */

/** A time as an ICS file writes it, before anybody's clock is applied. */
export type IcsTime =
  | { readonly kind: 'date'; readonly date: string }
  | {
      readonly kind: 'wall';
      readonly date: string;
      readonly minute: number;
      readonly zone: string | null;
    }
  | { readonly kind: 'utc'; readonly instant: Date };

export interface IcsDuration {
  readonly days: number;
  readonly ms: number;
}

export interface IcsEvent {
  readonly uid: string;
  readonly summary: string;
  readonly isCancelled: boolean;
  readonly start: IcsTime;
  readonly end: IcsTime | null;
  readonly duration: IcsDuration | null;
  readonly rule: string | null;
  readonly excluded: readonly IcsTime[];
  readonly replaces: IcsTime | null;
}

interface Property {
  readonly name: string;
  readonly params: Readonly<Record<string, string>>;
  readonly value: string;
}

/** The events in [text], or null when it is not a calendar at all. */
export function parseIcs(text: string): IcsEvent[] | null {
  const lines = unfold(text);
  if (!lines.some((line) => line.trim().toUpperCase() === 'BEGIN:VCALENDAR')) return null;
  const events: IcsEvent[] = [];
  let current: Property[] | null = null;
  let depth = 0;
  for (const line of lines) {
    const upper = line.trim().toUpperCase();
    if (upper === 'BEGIN:VEVENT') {
      current = [];
      depth = 0;
      continue;
    }
    if (current === null) continue;
    // An alarm or anything else nested in the event has properties of its own.
    if (upper.startsWith('BEGIN:')) depth++;
    else if (upper.startsWith('END:') && upper !== 'END:VEVENT') depth--;
    else if (upper === 'END:VEVENT') {
      const event = eventOf(current);
      if (event !== null) events.push(event);
      current = null;
    } else if (depth === 0) {
      const property = propertyOf(line);
      if (property !== null) current.push(property);
    }
  }
  return events;
}

function unfold(text: string): string[] {
  const lines: string[] = [];
  for (const raw of text.split(/\r?\n/)) {
    const previous = lines.at(-1);
    if ((raw.startsWith(' ') || raw.startsWith('\t')) && previous !== undefined) {
      lines[lines.length - 1] = previous + raw.slice(1);
    } else if (raw.length > 0) {
      lines.push(raw);
    }
  }
  return lines;
}

/** `NAME;PARAM=VALUE;PARAM="quoted:value":the value`. */
function propertyOf(line: string): Property | null {
  let inQuotes = false;
  let colon = -1;
  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    if (char === '"') inQuotes = !inQuotes;
    else if (char === ':' && !inQuotes) {
      colon = i;
      break;
    }
  }
  if (colon < 0) return null;
  const [name = '', ...rawParams] = line.slice(0, colon).split(';');
  const params: Record<string, string> = {};
  for (const raw of rawParams) {
    const equals = raw.indexOf('=');
    if (equals > 0) {
      params[raw.slice(0, equals).toUpperCase()] = raw.slice(equals + 1).replace(/^"|"$/g, '');
    }
  }
  return { name: name.toUpperCase(), params, value: line.slice(colon + 1) };
}

function eventOf(properties: readonly Property[]): IcsEvent | null {
  const find = (name: string): Property | undefined => properties.find((p) => p.name === name);
  const startProperty = find('DTSTART');
  const start =
    startProperty === undefined ? null : timeOf(startProperty.value, startProperty.params);
  if (start === null) return null;
  const endProperty = find('DTEND');
  const durationProperty = find('DURATION');
  const recurrenceId = find('RECURRENCE-ID');
  return {
    uid: find('UID')?.value ?? '',
    summary: unescapeText(find('SUMMARY')?.value ?? ''),
    isCancelled: find('STATUS')?.value.toUpperCase() === 'CANCELLED',
    start,
    end: endProperty === undefined ? null : timeOf(endProperty.value, endProperty.params),
    duration: durationProperty === undefined ? null : durationOf(durationProperty.value),
    rule: find('RRULE')?.value ?? null,
    excluded: properties
      .filter((p) => p.name === 'EXDATE')
      .flatMap((p) => p.value.split(',').flatMap((value) => timeOf(value, p.params) ?? [])),
    replaces: recurrenceId === undefined ? null : timeOf(recurrenceId.value, recurrenceId.params),
  };
}

const DATE = /^(\d{4})(\d{2})(\d{2})$/;
const DATE_TIME = /^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(Z?)$/;

/** A DTSTART-shaped value. Null when it is not one. */
export function timeOf(value: string, params: Readonly<Record<string, string>>): IcsTime | null {
  const trimmed = value.trim();
  const date = DATE.exec(trimmed);
  if (date !== null)
    return { kind: 'date', date: `${date[1] ?? ''}-${date[2] ?? ''}-${date[3] ?? ''}` };
  const stamp = DATE_TIME.exec(trimmed);
  if (stamp === null) return null;
  const [, year = '', month = '', day = '', hour = '0', minute = '0', , utc] = stamp;
  const iso = `${year}-${month}-${day}`;
  if (utc === 'Z') {
    const instant = new Date(`${iso}T${hour}:${minute}:00Z`);
    return Number.isNaN(instant.getTime()) ? null : { kind: 'utc', instant };
  }
  return {
    kind: 'wall',
    date: iso,
    minute: Number(hour) * 60 + Number(minute),
    zone: zoneOf(params['TZID']),
  };
}

/**
 * An IANA name the runtime knows, or null — which the expansion reads as the
 * household's own zone. Outlook's exports write Windows names ("South Africa
 * Standard Time"); those fall back rather than fail.
 */
function zoneOf(tzid: string | undefined): string | null {
  if (tzid === undefined) return null;
  const name = tzid.replace(/^\//, '');
  return isKnownZone(name) ? name : null;
}

const DURATION = /^([+-])?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$/;

export function durationOf(value: string): IcsDuration | null {
  const match = DURATION.exec(value.trim());
  if (match === null) return null;
  const [, sign, weeks, days, hours, minutes, seconds] = match;
  const direction = sign === '-' ? -1 : 1;
  return {
    days: direction * (Number(weeks ?? 0) * 7 + Number(days ?? 0)),
    ms:
      direction *
      ((Number(hours ?? 0) * 60 + Number(minutes ?? 0)) * 60 + Number(seconds ?? 0)) *
      1000,
  };
}

function unescapeText(value: string): string {
  return value.replace(/\\([\\;,nN])/g, (_, char: string) =>
    char === 'n' || char === 'N' ? ' ' : char,
  );
}
