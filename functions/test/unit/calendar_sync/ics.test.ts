import { describe, expect, it } from 'vitest';

import { toSyncedEvent } from '../../../src/calendar_sync/external_occurrence';
import { icsOccurrences } from '../../../src/calendar_sync/ics_occurrences';
import { durationOf, parseIcs } from '../../../src/calendar_sync/ics_parser';
import type { SyncedEventDocument } from '../../../src/calendar_sync/sync_documents';
import { parseRule } from '../../../src/calendar_sync/ics_rule';
import { windowIn } from './fakes';

/**
 * A calendar link — Apple's way in (calendar ADR-0003): the RFC 5545 a family
 * calendar uses, parsed and expanded on each event's own wall clock.
 */
function calendar(...events: string[]): string {
  return ['BEGIN:VCALENDAR', 'VERSION:2.0', ...events, 'END:VCALENDAR'].join('\r\n');
}

function vevent(...lines: string[]): string {
  return ['BEGIN:VEVENT', ...lines, 'END:VEVENT'].join('\r\n');
}

function occurrencesOf(text: string, zone = 'Africa/Johannesburg'): SyncedEventDocument[] {
  const events = parseIcs(text);
  if (events === null) throw new Error('not a calendar');
  const window = windowIn(zone);
  return icsOccurrences(events, window).map(
    (occurrence) =>
      toSyncedEvent(occurrence, { connectionId: 'c', provider: 'ics', memberId: 'm' }, zone)
        .document,
  );
}

describe('parsing', () => {
  it('is null for something that is not a calendar', () => {
    expect(parseIcs('<html><body>Sign in</body></html>')).toBeNull();
  });

  it('unfolds long lines, unescapes text, and ignores an alarm inside the event', () => {
    const events = parseIcs(
      calendar(
        vevent(
          'UID:1',
          'SUMMARY:Parents\\, teachers\\; and a very long title that the file',
          '  folded onto a second line',
          'DTSTART;VALUE=DATE:20261002',
          'BEGIN:VALARM',
          'SUMMARY:Reminder that is not the title',
          'END:VALARM',
        ),
      ),
    );
    expect(events?.[0]?.summary).toBe(
      'Parents, teachers; and a very long title that the file folded onto a second line',
    );
  });

  it('reads a quoted TZID and an unknown Windows zone as floating', () => {
    const [known, windows] =
      parseIcs(
        calendar(
          vevent('UID:a', 'DTSTART;TZID="Europe/London":20261002T090000'),
          vevent('UID:b', 'DTSTART;TZID=South Africa Standard Time:20261002T090000'),
        ),
      ) ?? [];
    expect(known?.start).toEqual({
      kind: 'wall',
      date: '2026-10-02',
      minute: 540,
      zone: 'Europe/London',
    });
    expect(windows?.start).toEqual({ kind: 'wall', date: '2026-10-02', minute: 540, zone: null });
  });

  it('reads durations in weeks, days and time', () => {
    expect(durationOf('PT1H30M')).toEqual({ days: 0, ms: 90 * 60_000 });
    expect(durationOf('P1W')).toEqual({ days: 7, ms: 0 });
    expect(durationOf('P2DT3H')).toEqual({ days: 2, ms: 3 * 3_600_000 });
    expect(durationOf('soon')).toBeNull();
  });
});

describe('repeat rules', () => {
  it('reads the subset families use', () => {
    expect(parseRule('FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,TH;UNTIL=20261231', '2026-09-29')).toEqual({
      frequency: 'WEEKLY',
      interval: 2,
      count: null,
      until: '20261231',
      weekdays: [2, 4],
      nthWeekday: null,
    });
    expect(parseRule('FREQ=MONTHLY;BYDAY=1MO', '2026-10-05')?.nthWeekday).toEqual({
      nth: 1,
      weekday: 1,
    });
  });

  it('refuses what it cannot expand honestly', () => {
    expect(parseRule('FREQ=HOURLY', '2026-09-29')).toBeNull();
    expect(parseRule('FREQ=MONTHLY;BYSETPOS=-1;BYDAY=MO,TU', '2026-09-29')).toBeNull();
    expect(parseRule('FREQ=WEEKLY;BYHOUR=9', '2026-09-29')).toBeNull();
  });
});

describe('occurrences in the window', () => {
  it('a weekly rule with an end lands on each chosen day and stops', () => {
    const synced = occurrencesOf(
      calendar(
        vevent(
          'UID:soccer',
          'SUMMARY:Soccer',
          'DTSTART;TZID=Africa/Johannesburg:20260915T170000',
          'DTEND;TZID=Africa/Johannesburg:20260915T180000',
          'RRULE:FREQ=WEEKLY;BYDAY=TU;UNTIL=20261013T235959Z',
        ),
      ),
    );
    expect(synced.map((s) => s.date)).toEqual([
      '2026-09-22',
      '2026-09-29',
      '2026-10-06',
      '2026-10-13',
    ]);
    expect(synced.every((s) => s.startMinute === 17 * 60 && s.endMinute === 18 * 60)).toBe(true);
  });

  it('a repeat in London stays at 07:30 across the clocks going back', () => {
    const synced = occurrencesOf(
      calendar(
        vevent(
          'UID:run',
          'SUMMARY:School run',
          'DTSTART;TZID=Europe/London:20261019T073000',
          'DURATION:PT30M',
          'RRULE:FREQ=WEEKLY;BYDAY=FR;COUNT=3',
        ),
      ),
      'Europe/London',
    );
    expect(synced.map((s) => [s.date, s.startMinute])).toEqual([
      ['2026-10-23', 450],
      ['2026-10-30', 450],
      ['2026-11-06', 450],
    ]);
  });

  it('COUNT counts from the first occurrence, not from the window', () => {
    const synced = occurrencesOf(
      calendar(
        vevent(
          'UID:c',
          'SUMMARY:Course',
          'DTSTART;VALUE=DATE:20260901',
          'RRULE:FREQ=WEEKLY;COUNT=5',
        ),
      ),
    );
    // 1, 8, 15, 22, 29 September — the window opens on the 22nd.
    expect(synced.map((s) => s.date)).toEqual(['2026-09-22', '2026-09-29']);
  });

  it('an excluded date is skipped, and a moved one appears where it moved to', () => {
    const synced = occurrencesOf(
      calendar(
        vevent(
          'UID:piano',
          'SUMMARY:Piano',
          'DTSTART;TZID=Africa/Johannesburg:20260929T150000',
          'DTEND;TZID=Africa/Johannesburg:20260929T160000',
          'RRULE:FREQ=WEEKLY;COUNT=4',
          'EXDATE;TZID=Africa/Johannesburg:20261006T150000',
        ),
        vevent(
          'UID:piano',
          'SUMMARY:Piano (moved)',
          'RECURRENCE-ID;TZID=Africa/Johannesburg:20261013T150000',
          'DTSTART;TZID=Africa/Johannesburg:20261014T160000',
          'DTEND;TZID=Africa/Johannesburg:20261014T170000',
        ),
      ),
    );
    expect(synced.map((s) => [s.date, s.title, s.startMinute])).toEqual([
      ['2026-09-29', 'Piano', 900],
      ['2026-10-14', 'Piano (moved)', 960],
      ['2026-10-20', 'Piano', 900],
    ]);
  });

  it('the first Monday of each month, and a yearly 29 February only in a leap year', () => {
    const meetings = occurrencesOf(
      calendar(
        vevent(
          'UID:pta',
          'SUMMARY:PTA',
          'DTSTART;VALUE=DATE:20260907',
          'RRULE:FREQ=MONTHLY;BYDAY=1MO',
        ),
      ),
    );
    expect(meetings.map((s) => s.date)).toEqual([
      '2026-10-05',
      '2026-11-02',
      '2026-12-07',
      '2027-01-04',
    ]);
    const leap = occurrencesOf(
      calendar(vevent('UID:l', 'SUMMARY:Leap', 'DTSTART;VALUE=DATE:20240229', 'RRULE:FREQ=YEARLY')),
    );
    expect(leap).toEqual([]);
  });

  it('a rule it cannot expand is imported once rather than guessed', () => {
    const synced = occurrencesOf(
      calendar(
        vevent(
          'UID:x',
          'SUMMARY:Odd',
          'DTSTART;VALUE=DATE:20261001',
          'RRULE:FREQ=MONTHLY;BYSETPOS=2;BYDAY=MO,TU',
        ),
      ),
    );
    expect(synced.map((s) => s.date)).toEqual(['2026-10-01']);
  });

  it('a daily rule from years ago costs only the window', () => {
    const synced = occurrencesOf(
      calendar(vevent('UID:d', 'SUMMARY:Meds', 'DTSTART:20150101T060000Z', 'RRULE:FREQ=DAILY')),
    );
    expect(synced).toHaveLength(128);
    expect(synced[0]?.date).toBe('2026-09-22');
  });

  it('cancelled events and events outside the window stay out', () => {
    const synced = occurrencesOf(
      calendar(
        vevent('UID:1', 'SUMMARY:Off', 'STATUS:CANCELLED', 'DTSTART;VALUE=DATE:20261001'),
        vevent('UID:2', 'SUMMARY:Long ago', 'DTSTART;VALUE=DATE:20200101'),
        vevent('UID:3', 'SUMMARY:On', 'DTSTART;VALUE=DATE:20261001'),
      ),
    );
    expect(synced.map((s) => s.title)).toEqual(['On']);
  });
});
