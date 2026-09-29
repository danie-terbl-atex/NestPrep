import { describe, expect, it } from 'vitest';

import { toSyncedEvent } from '../../../src/calendar_sync/external_occurrence';
import {
  fold,
  storedRecurrence,
  writeFeed,
  type FeedEvent,
} from '../../../src/calendar_sync/feed_writer';
import { hashFeedToken } from '../../../src/calendar_sync/feed_link';
import { icsOccurrences } from '../../../src/calendar_sync/ics_occurrences';
import { parseIcs } from '../../../src/calendar_sync/ics_parser';
import type { SyncedEventDocument } from '../../../src/calendar_sync/sync_documents';
import { RECURRENCE_KEYS } from '../../recurrence_shape';
import { windowIn } from './fakes';

/**
 * The household's feed (calendar ADR-0003): each event keeps its rule in the
 * household's zone, and a skipped occurrence is an `EXDATE`. The proof is a
 * round trip — the feed read back by the same reader that imports calendar
 * links lands on exactly the days the app draws.
 */
const NOW = new Date('2026-09-29T10:00:00Z');

function feedOf(events: FeedEvent[], zone = 'Africa/Johannesburg'): string {
  return writeFeed({ calendarName: 'The Parkers', zone, events, now: NOW });
}

function readBack(feed: string, zone = 'Africa/Johannesburg'): SyncedEventDocument[] {
  const events = parseIcs(feed);
  if (events === null) throw new Error('the feed is not a calendar');
  return icsOccurrences(events, windowIn(zone)).map(
    (occurrence) =>
      toSyncedEvent(occurrence, { connectionId: 'c', provider: 'ics', memberId: 'm' }, zone)
        .document,
  );
}

const soccer: FeedEvent = {
  id: 'soccer',
  event: {
    title: 'Soccer',
    date: '2026-09-29',
    startMinute: 17 * 60,
    endMinute: 18 * 60,
    recurrence: { frequency: 'weekly', interval: 1, weekdays: [2], until: '2026-10-20' },
  },
  skipped: ['2026-10-06'],
};

describe('the feed', () => {
  it('writes a weekly event with its rule, its end in UTC, and its skipped day', () => {
    const feed = feedOf([soccer]);
    expect(feed).toContain('DTSTART;TZID=Africa/Johannesburg:20260929T170000');
    expect(feed).toContain('RRULE:FREQ=WEEKLY;INTERVAL=1;BYDAY=TU;UNTIL=20261020T215959Z');
    expect(feed).toContain('EXDATE;TZID=Africa/Johannesburg:20261006T170000');
    expect(feed).toContain('X-WR-CALNAME:The Parkers');
    expect(feed.endsWith('END:VCALENDAR\r\n')).toBe(true);
  });

  it('reads back onto the days the app would draw', () => {
    expect(readBack(feedOf([soccer])).map((s) => [s.date, s.startMinute, s.endMinute])).toEqual([
      ['2026-09-29', 1020, 1080],
      ['2026-10-13', 1020, 1080],
      ['2026-10-20', 1020, 1080],
    ]);
  });

  it('keeps a London 07:30 at 07:30 across the clocks going back', () => {
    const run: FeedEvent = {
      id: 'run',
      event: {
        title: 'School run',
        date: '2026-10-19',
        startMinute: 450,
        endMinute: 480,
        recurrence: { frequency: 'weekly', interval: 1, weekdays: [5], until: '2026-11-06' },
      },
      skipped: [],
    };
    expect(
      readBack(feedOf([run], 'Europe/London'), 'Europe/London').map((s) => s.startMinute),
    ).toEqual([450, 450, 450]);
  });

  it('writes an all-day event as dates, a monthly one on its day, and an overnight end tomorrow', () => {
    const feed = feedOf([
      {
        id: 'fete',
        event: { title: 'Fete', date: '2026-10-03', startMinute: null, endMinute: null },
        skipped: [],
      },
      {
        id: 'rent',
        event: {
          title: 'Rent',
          date: '2026-10-31',
          startMinute: null,
          recurrence: { frequency: 'monthly', interval: 1, weekdays: [], until: null },
        },
        skipped: [],
      },
      {
        id: 'party',
        event: { title: 'Party', date: '2026-10-10', startMinute: 1320, endMinute: 60 },
        skipped: [],
      },
    ]);
    expect(feed).toContain('DTSTART;VALUE=DATE:20261003');
    expect(feed).toContain('DTEND;VALUE=DATE:20261004');
    expect(feed).toContain('RRULE:FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=31');
    expect(feed).toContain('DTEND;TZID=Africa/Johannesburg:20261011T010000');
  });

  it('escapes text and folds long lines, and carries no note or name', () => {
    const feed = feedOf([
      {
        id: 'long',
        event: {
          title: `Parents, teachers; ${'and everybody else '.repeat(6)}`,
          date: '2026-10-03',
          startMinute: null,
        },
        skipped: [],
      },
    ]);
    expect(feed).toContain('SUMMARY:Parents\\, teachers\\; and');
    expect(feed.split('\r\n').every((line) => Buffer.byteLength(line) <= 75)).toBe(true);
    expect(fold('x'.repeat(200)).split('\r\n ').join('')).toBe('x'.repeat(200));
    expect(feed).not.toMatch(/DESCRIPTION|ATTENDEE|ORGANIZER/);
  });
});

describe('what it reads', () => {
  it('is the recurrence shape the app writes, key for key', () => {
    expect(Object.keys(storedRecurrence.shape).sort()).toEqual([...RECURRENCE_KEYS].sort());
  });

  it('looks a token up by its hash, never the token itself', () => {
    expect(hashFeedToken('abc')).toMatch(/^[0-9a-f]{64}$/);
    expect(hashFeedToken('abc')).not.toContain('abc');
  });
});
