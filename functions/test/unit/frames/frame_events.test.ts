import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { assembleFrameDay } from '../../../src/frames/frame_day';
import { frameDocument } from '../../../src/frames/frame_documents';
import { refuseFrame } from '../../../src/frames/frame_errors';
import {
  adderNamed,
  calendarEditors,
  frameEventDocument,
  frameEventId,
  inEventReach,
  peopleNamed,
} from '../../../src/frames/frame_events';
import { FRAME_ADD_EVENT_PER_CREDENTIAL, addsEvents } from '../../../src/frames/frame_policy';
import {
  type AddFrameEventInput,
  addFrameEventInput,
  claimFramePairingInput,
} from '../../../src/frames/frame_schemas';
import { ROLE_DEFAULTS, uniformGrant } from '../../../src/household/access';
import { parseInput } from '../../../src/household/parse_input';
import type { MemberRecord, StoredHousehold } from '../../../src/notifications/recipients';
import { weeklyOn } from '../../recurrence_shape';

/** An event added at the wall (photo-frames ADR-0008). */

const SECRET = 'a'.repeat(43);
const BODY = { secret: SECRET, title: 'Dentist', date: '2026-11-03', who: [], by: 'Sam' };

function reasonOf(run: () => unknown): unknown {
  try {
    run();
  } catch (error) {
    return error instanceof HttpsError ? (error.details as { reason?: unknown }).reason : error;
  }
  return undefined;
}

function input(more: Record<string, unknown> = {}): AddFrameEventInput {
  return parseInput(addFrameEventInput, { ...BODY, ...more });
}

describe('what a frame may send', () => {
  it('a title, a day, who it is for and who is adding it; the rest absent', () => {
    expect(input({ title: '  Dentist ', by: ' Sam ' })).toEqual({
      ...BODY,
      start: null,
      end: null,
      note: null,
      repeat: null,
      requestId: null,
    });
  });

  it('times as HH:mm, read as minutes; an end before the start is past midnight', () => {
    expect(input({ start: '07:30', end: '08:15' })).toMatchObject({ start: 450, end: 495 });
    expect(input({ start: '22:00', end: '01:00' })).toMatchObject({ start: 1320, end: 60 });
    expect(input({ start: '23:59' })).toMatchObject({ start: 1439, end: null });
    expect(input({ start: null, end: null })).toMatchObject({ start: null, end: null });
  });

  it('a request id a retry repeats, which names the event per frame', () => {
    expect(input({ requestId: 'sheet_0001-AB' }).requestId).toBe('sheet_0001-AB');
    expect(input({ requestId: 'x'.repeat(64) }).requestId).toHaveLength(64);
    expect(frameEventId('frame1', 'sheet_0001-AB')).toBe('frame-frame1-sheet_0001-AB');
  });

  it('a note trimmed, and an empty one is none; a weekly repeat', () => {
    expect(input({ note: '  Bring the card  ' }).note).toBe('Bring the card');
    expect(input({ note: '   ' }).note).toBeNull();
    expect(input({ note: 'x'.repeat(500) }).note).toHaveLength(500);
    expect(input({ repeat: 'weekly' }).repeat).toBe('weekly');
  });

  it.each([
    ['no title', { title: '   ' }],
    ['a title past 120', { title: 'x'.repeat(121) }],
    ['a day that is not one', { date: '2026-02-30' }],
    ['a month that is not one', { date: '2026-13-01' }],
    ['a day in words', { date: '3 Nov' }],
    ['a time past midnight', { start: '24:00' }],
    ['a time without its zero', { start: '7:30' }],
    ['an end with no start', { end: '09:00' }],
    ['more than twenty people', { who: Array.from({ length: 21 }, () => 'Sam') }],
    ['a blank name among them', { who: [' '] }],
    ['nobody adding it', { by: ' ' }],
    ['a name past sixty', { by: 'x'.repeat(61) }],
    ['a note past 500', { note: 'x'.repeat(501) }],
    ['a repeat other than weekly', { repeat: 'daily' }],
    ['a request id too short', { requestId: 'abc1234' }],
    ['a request id too long', { requestId: 'x'.repeat(65) }],
    ['a request id with a slash', { requestId: 'sheet/0001' }],
  ])('and refuses %s', (_, more) => {
    expect(reasonOf(() => input(more))).toBe('badRequest');
  });
});

describe('how far ahead a frame may add', () => {
  it('from today to the same day a year on, nothing before', () => {
    expect(inEventReach('2026-10-29', '2026-10-29')).toBe(true);
    expect(inEventReach('2027-10-29', '2026-10-29')).toBe(true);
    expect(inEventReach('2027-10-30', '2026-10-29')).toBe(false);
    expect(inEventReach('2026-10-28', '2026-10-29')).toBe(false);
  });

  it('a year on from a leap day is the last of February', () => {
    expect(inEventReach('2029-02-28', '2028-02-29')).toBe(true);
    expect(inEventReach('2029-03-01', '2028-02-29')).toBe(false);
  });
});

describe('the switch', () => {
  const panels = {
    calendar: true,
    todos: false,
    meals: false,
    lunch: false,
    addEvents: true,
    share: false,
    helperMemberId: null,
  };

  it('is on only while the frame shows the calendar too', () => {
    expect(addsEvents(panels)).toBe(true);
    expect(addsEvents({ ...panels, calendar: false })).toBe(false);
    expect(addsEvents({ ...panels, addEvents: false })).toBe(false);
  });

  it('is off on a frame stored before it, and on a claim from an older app', () => {
    const stored = frameDocument.parse({
      name: 'Kitchen',
      panels: { calendar: true, todos: true, meals: true, helperMemberId: null },
    });
    expect(stored.panels.addEvents).toBe(false);
    expect(
      frameDocument.parse({ name: 'Kitchen', panels: { ...panels, addEvents: 'yes' } }).panels
        .addEvents,
    ).toBe(false);
    const claim = {
      householdId: 'h1',
      code: 'ABC234',
      name: 'Kitchen',
      panels: { calendar: true, todos: true, meals: true, helperMemberId: null },
    };
    expect(parseInput(claimFramePairingInput, claim).panels.addEvents).toBe(false);
    expect(
      parseInput(claimFramePairingInput, { ...claim, panels: { ...claim.panels, addEvents: true } })
        .panels.addEvents,
    ).toBe(true);
  });

  it('sixty an hour per frame', () => {
    expect(FRAME_ADD_EVENT_PER_CREDENTIAL).toEqual({
      name: 'addFrameEvent:credential',
      limit: 60,
      windowSeconds: 3600,
    });
  });

  it('refuses with its own reasons', () => {
    expect(refuseFrame('addingOff').code).toBe('failed-precondition');
    expect(refuseFrame('notAllowedToAdd').code).toBe('permission-denied');
    expect(refuseFrame('eventOutOfReach').code).toBe('out-of-range');
    expect(refuseFrame('eventOutOfReach').details).toEqual({ reason: 'eventOutOfReach' });
  });
});

const HOUSEHOLD: StoredHousehold = {
  timeZone: 'Africa/Johannesburg',
  members: {
    'uid-sam': 'admin',
    'uid-pat': 'parent',
    'uid-old': 'member',
    'uid-thandi': 'helper',
    'uid-nomsa': 'carer',
    'uid-zola': 'carer',
    'uid-legacy': 'helper',
  },
  access: {
    'uid-thandi': ROLE_DEFAULTS.helper,
    'uid-nomsa': { ...ROLE_DEFAULTS.carer, calendar: 'edit' },
    'uid-zola': uniformGrant('edit'),
  },
  kids: { 'tablet-mia': 'm-mia', 'tablet-leo': 'm-leo' },
  shiftOnly: { 'm-zola': true },
};

function member(
  id: string,
  displayName: string,
  role: string,
  claimedBy: string | null,
): MemberRecord {
  return { id, displayName, role, claimedBy };
}

const MEMBERS: MemberRecord[] = [
  member('m-sam', 'Sam Parker', 'admin', 'uid-sam'),
  member('m-pat', 'Pat', 'parent', 'uid-pat'),
  member('m-old', 'Jo', 'member', 'uid-old'),
  member('m-thandi', 'Thandi', 'helper', 'uid-thandi'),
  member('m-nomsa', 'Nomsa', 'carer', 'uid-nomsa'),
  member('m-zola', 'Zola', 'carer', 'uid-zola'),
  member('m-legacy', 'Grace', 'helper', 'uid-legacy'),
  { ...member('m-mia', 'Mia', 'kid', null), access: { ...ROLE_DEFAULTS.kid, calendar: 'edit' } },
  { ...member('m-leo', 'Leo', 'kid', null), access: ROLE_DEFAULTS.kid },
  member('m-gran', 'Gran', 'parent', null),
];

const NAMES = Object.fromEntries(MEMBERS.map((each) => [each.id, each.displayName]));

describe('who may add an event', () => {
  it('whoever the rules let edit the calendar, and nobody who cannot sign in as themselves', () => {
    expect(calendarEditors(HOUSEHOLD, MEMBERS)).toEqual([
      'm-sam',
      'm-pat',
      'm-old',
      'm-nomsa',
      'm-legacy',
      'm-mia',
    ]);
  });

  it('is the one of them with that first name, in any case', () => {
    const editors = calendarEditors(HOUSEHOLD, MEMBERS);
    expect(adderNamed(editors, NAMES, ' sam ')).toBe('m-sam');
    expect(adderNamed(editors, NAMES, 'MIA')).toBe('m-mia');
  });

  it('and refuses somebody who may not, or nobody at all', () => {
    const editors = calendarEditors(HOUSEHOLD, MEMBERS);
    for (const by of ['Thandi', 'Leo', 'Gran', 'Zola', 'Nobody']) {
      expect(reasonOf(() => adderNamed(editors, NAMES, by))).toBe('notAllowedToAdd');
    }
  });

  it('and asks who when two of them share the name', () => {
    const names = { ...NAMES, 'm-pat': 'Sam Jones' };
    expect(reasonOf(() => adderNamed(['m-sam', 'm-pat'], names, 'Sam'))).toBe('whoNeeded');
    expect(adderNamed(['m-sam'], names, 'Sam')).toBe('m-sam');
  });
});

describe('who an event is for', () => {
  it('each name once, in order, among everybody; nobody is everyone', () => {
    expect(peopleNamed([], NAMES)).toEqual([]);
    expect(peopleNamed(['Leo', 'thandi', 'Leo'], NAMES)).toEqual(['m-leo', 'm-thandi']);
  });

  it('an unknown name is a bad request, a shared one asks who', () => {
    expect(reasonOf(() => peopleNamed(['Leo', 'Nobody'], NAMES))).toBe('badRequest');
    const names = { ...NAMES, 'm-pat': 'Leo Jones' };
    expect(reasonOf(() => peopleNamed(['Leo'], names))).toBe('whoNeeded');
  });
});

const calendarRules = readFileSync(
  resolve(import.meta.dirname, '../../../../rules/firestore/household/calendar.rules'),
  'utf8',
);

function keysAnEventMayHave(): string[] {
  const create = calendarRules.slice(calendarRules.indexOf('allow create'));
  const list = /hasOnly\(\s*\[([^\]]*)\]/.exec(create)?.[1] ?? '';
  return [...list.matchAll(/'(\w+)'/g)].map((match) => match[1] ?? '');
}

describe('the event written', () => {
  it('timed: the app’s document, key for key', () => {
    expect(
      frameEventDocument(input({ start: '09:00', end: '10:30', note: ' Card ' }), 'm-sam', [
        'm-mia',
      ]),
    ).toEqual({
      title: 'Dentist',
      note: 'Card',
      date: '2026-11-03',
      startMinute: 540,
      endMinute: 630,
      recurrence: null,
      memberIds: ['m-mia'],
      createdBy: 'm-sam',
    });
  });

  it('all-day: both times null, whatever end was sent; a timed one may have no end', () => {
    const allDay = {
      title: 'Dentist',
      note: null,
      date: '2026-11-03',
      startMinute: null,
      endMinute: null,
      recurrence: null,
      memberIds: [],
      createdBy: 'm-sam',
    };
    expect(frameEventDocument(input(), 'm-sam', [])).toEqual(allDay);
    expect(frameEventDocument({ ...input(), end: 600 }, 'm-sam', [])).toEqual(allDay);
    expect(frameEventDocument(input({ start: '09:00' }), 'm-sam', [])).toMatchObject({
      startMinute: 540,
      endMinute: null,
    });
  });

  it('weekly: on the day’s own weekday, for ever, as the app’s editor writes it', () => {
    expect(frameEventDocument(input({ repeat: 'weekly' }), 'm-sam', []).recurrence).toEqual(
      weeklyOn([2]),
    );
    expect(
      frameEventDocument(input({ date: '2026-11-08', repeat: 'weekly' }), 'm-sam', []).recurrence,
    ).toEqual(weeklyOn([7]));
  });

  it('every key the calendar rules let a client create, createdAt aside, and no other', () => {
    const allowed = keysAnEventMayHave();
    expect(allowed).toContain('createdAt');
    for (const more of [{}, { start: '09:00', end: '10:00', note: 'n', repeat: 'weekly' }]) {
      const written = frameEventDocument(input(more), 'm-sam', ['m-mia']);
      expect([...Object.keys(written), 'createdAt'].sort()).toEqual([...allowed].sort());
    }
  });
});

describe('the day says who may add', () => {
  const panels = {
    calendar: true,
    todos: false,
    meals: false,
    lunch: false,
    addEvents: true,
    share: false,
    helperMemberId: null,
  };
  const sources = {
    householdName: 'The Parkers',
    frameName: 'Kitchen',
    panels,
    screensaver: null,
    today: '2026-10-29',
    localMinute: 9 * 60,
    names: { 'm-sam': 'Sam Parker', 'm-mia': 'Mia', 'm-pat': 'Pat', 'm-thandi': 'Thandi' },
    colors: {},
    adders: ['m-sam', 'm-pat', 'm-mia'],
  };

  it('by first name, in the order the household’s members are', () => {
    const day = assembleFrameDay(sources);
    expect(day.addEvents).toEqual({ by: ['Mia', 'Pat', 'Sam'] });
    expect(day.household.members.map((each) => each.name)).toEqual(['Mia', 'Pat', 'Sam', 'Thandi']);
    expect(day.calendar?.days).toHaveLength(3);
  });

  it('and nothing while adding is off or the calendar is', () => {
    expect(
      assembleFrameDay({ ...sources, panels: { ...panels, addEvents: false } }),
    ).not.toHaveProperty('addEvents');
    expect(
      assembleFrameDay({ ...sources, panels: { ...panels, calendar: false } }),
    ).not.toHaveProperty('addEvents');
  });
});
