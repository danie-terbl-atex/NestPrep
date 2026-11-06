import { describe, expect, it } from 'vitest';

import { calendarSourcesFor } from '../../../src/calendar_sync/calendar_sources';
import { IcsCalendar } from '../../../src/calendar_sync/ics_calendar';
import { appleConnectionId, inWindow } from '../../../src/calendar_sync/push_apple_calendar';
import { MAX_PUSHED_OCCURRENCES, pushAppleCalendarInput } from '../../../src/calendar_sync/schemas';
import { ScriptedHttp, json } from './fakes';

const NOW = new Date('2026-09-29T10:00:00Z');
const ZONE = 'Africa/Johannesburg';
const at = (iso: string): number => new Date(iso).getTime();

describe('what an iPhone may push', () => {
  const body = (occurrences: unknown[]): unknown => ({
    householdId: 'h1',
    link: false,
    occurrences,
  });

  it('takes timed and all-day occurrences', () => {
    const parsed = pushAppleCalendarInput.safeParse(
      body([
        {
          id: 'a',
          title: 'Dentist',
          allDay: false,
          start: at('2026-10-01T14:00:00Z'),
          end: at('2026-10-01T15:00:00Z'),
        },
        {
          id: 'b',
          title: 'Half term',
          allDay: true,
          startDate: '2026-10-05',
          endDateExclusive: '2026-10-10',
        },
      ]),
    );
    expect(parsed.success).toBe(true);
  });

  it('refuses an all-day occurrence with a time, or a timed one with dates', () => {
    for (const occurrence of [
      { id: 'a', title: '', allDay: true, start: 1, end: 2 },
      {
        id: 'a',
        title: '',
        allDay: false,
        startDate: '2026-10-05',
        endDateExclusive: '2026-10-06',
      },
      { id: 'a', title: '', allDay: true, startDate: '5 Oct', endDateExclusive: '2026-10-06' },
      { id: '', title: '', allDay: false, start: 1, end: 2 },
    ]) {
      expect(
        pushAppleCalendarInput.safeParse(body([occurrence])).success,
        JSON.stringify(occurrence),
      ).toBe(false);
    }
  });

  it('refuses more than the engine would keep', () => {
    const many = Array.from({ length: MAX_PUSHED_OCCURRENCES + 1 }, (_, i) => ({
      id: `e${String(i)}`,
      title: '',
      allDay: false,
      start: 1,
      end: 2,
    }));
    expect(pushAppleCalendarInput.safeParse(body(many)).success).toBe(false);
  });

  it('never names whose calendar it is', () => {
    const parsed = pushAppleCalendarInput.parse({ ...(body([]) as object), memberId: 'm-someone' });
    expect(parsed).not.toHaveProperty('memberId');
  });
});

describe('the pushed occurrences the engine keeps', () => {
  it('keeps what touches the window, as the engine reads it', () => {
    const kept = inWindow(
      [
        {
          id: 'soon',
          title: 'Dentist',
          allDay: false,
          start: at('2026-10-01T14:00:00Z'),
          end: at('2026-10-01T15:00:00Z'),
        },
        {
          id: 'term',
          title: 'Half term',
          allDay: true,
          startDate: '2026-10-05',
          endDateExclusive: '2026-10-10',
        },
        {
          id: 'old',
          title: 'Last year',
          allDay: false,
          start: at('2025-09-01T14:00:00Z'),
          end: at('2025-09-01T15:00:00Z'),
        },
        {
          id: 'far',
          title: 'Next year',
          allDay: true,
          startDate: '2027-09-01',
          endDateExclusive: '2027-09-02',
        },
      ],
      ZONE,
      NOW,
    );
    expect(kept).toEqual([
      {
        externalId: 'soon',
        title: 'Dentist',
        time: {
          kind: 'timed',
          start: new Date('2026-10-01T14:00:00Z'),
          end: new Date('2026-10-01T15:00:00Z'),
        },
      },
      {
        externalId: 'term',
        title: 'Half term',
        time: { kind: 'allDay', startDate: '2026-10-05', endDateExclusive: '2026-10-10' },
      },
    ]);
  });

  it('drops an occurrence that ends before it starts', () => {
    expect(
      inWindow(
        [
          {
            id: 'a',
            title: '',
            allDay: false,
            start: at('2026-10-01T15:00:00Z'),
            end: at('2026-10-01T14:00:00Z'),
          },
          {
            id: 'b',
            title: '',
            allDay: true,
            startDate: '2026-10-05',
            endDateExclusive: '2026-10-05',
          },
        ],
        ZONE,
        NOW,
      ),
    ).toEqual([]);
  });

  it('files every member under one connection, so two phones are one calendar', () => {
    expect(appleConnectionId('m-sam')).toBe('apple_m-sam');
  });
});

describe('the sources', () => {
  it('have nothing a Function could fetch an Apple connection from', () => {
    const http = new ScriptedHttp(() => json(500, {}));
    const sources = calendarSourcesFor(
      {
        google: { clientId: 'g', clientSecret: 's' },
        microsoft: { clientId: 'm', clientSecret: 's' },
      },
      http,
      new IcsCalendar(http, () => Promise.resolve([]), false),
    );
    expect(sources.source('apple')).toBeNull();
    expect(sources.source('google')).not.toBeNull();
  });
});
