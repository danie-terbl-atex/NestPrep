import { describe, expect, it } from 'vitest';

import type { StoredTask } from '../../../src/chore_points/point_documents';
import { refuseFrame } from '../../../src/frames/frame_errors';
import { answerFor } from '../../../src/frames/poll_frame_pairing';
import {
  type FrameDaySources,
  type HomeCareJobRecord,
  type HomeCareRoutineRecord,
  assembleFrameDay,
  NOTE_MAX,
  clockTime,
  firstName,
  frameNote,
  mondayOf,
} from '../../../src/frames/frame_day';
import { frameDocument } from '../../../src/frames/frame_documents';
import {
  FRAME_DEVICE_OPTIONS,
  FRAME_UNLINK_PER_CREDENTIAL,
  lastSeenIsStale,
  refreshAfterSeconds,
} from '../../../src/frames/frame_policy';
import {
  claimFramePairingInput,
  getFrameDayInput,
  startFramePairingInput,
  unlinkFrameInput,
} from '../../../src/frames/frame_schemas';
import { parseInput } from '../../../src/household/parse_input';
import { taskRecordOf } from '../../../src/notifications/digest_reads';
import { HttpsError } from 'firebase-functions/v2/https';
import { Timestamp } from 'firebase-admin/firestore';
import { everyDay, weeklyOn } from '../../recurrence_shape';

/** A frame's day, from what is stored (photo-frames ADR-0001). */

const TUESDAY = '2026-09-29';
const SECRET = 'a'.repeat(43);
const NONE = {
  calendar: false,
  todos: false,
  meals: false,
  lunch: false,
  addEvents: false,
  share: false,
  helperMemberId: null,
};

function task(title: string, assigneeIds: string[], recurrence = weeklyOn([2])): StoredTask {
  return {
    title,
    dueDate: '2026-09-01',
    recurrence,
    assigneeIds,
    routineId: null,
    points: 0,
    needsApproval: false,
  };
}

function job(
  id: string,
  title: string,
  roomId: string,
  status: string,
  dueDate: string,
  more: Partial<HomeCareJobRecord> = {},
): HomeCareJobRecord {
  return { id, title, roomId, status, dueDate, note: null, steps: [], doneStepIds: [], ...more };
}

function routine(
  id: string,
  name: string,
  roomId: string,
  firstDate: string,
  recurrence: HomeCareRoutineRecord['recurrence'],
  items: HomeCareRoutineRecord['items'],
): HomeCareRoutineRecord {
  return { id, name, roomId, firstDate, recurrence, items };
}

function sources(overrides: Partial<FrameDaySources>): FrameDaySources {
  return {
    householdName: 'The Parkers',
    frameName: 'Kitchen',
    panels: NONE,
    screensaver: null,
    today: TUESDAY,
    localMinute: 9 * 60,
    names: { 'm-sam': 'Sam Parker', 'm-mia': 'Mia', 'm-thandi': '  Thandi Mokoena ' },
    colors: { 'm-sam': 'teal', 'm-mia': 'coral', 'm-thandi': 'chartreuse' },
    ...overrides,
  };
}

describe('a frame with every panel off', () => {
  it('says only who it is, what day it is and when to ask again', () => {
    expect(assembleFrameDay(sources({}))).toEqual({
      status: 'linked',
      household: {
        name: 'The Parkers',
        members: [
          { name: 'Mia', color: '#FFC2B3' },
          { name: 'Sam', color: '#8ED3DA' },
          { name: 'Thandi', color: null },
        ],
      },
      frame: { name: 'Kitchen' },
      today: TUESDAY,
      refreshAfterSeconds: 60,
    });
  });
});

const ONCE = { note: null, repeats: false };
const REPEATS = { note: null, repeats: true };

describe('the calendar panel', () => {
  const day = assembleFrameDay(
    sources({
      panels: { ...NONE, calendar: true },
      events: {
        own: [
          {
            id: 'swim',
            event: {
              title: 'Swimming',
              date: '2026-09-01',
              startMinute: 900,
              endMinute: 960,
              recurrence: weeklyOn([2, 3]),
            },
            memberIds: ['m-mia', 'm-gone'],
            note: '  Bring the blue towel \n',
          },
          {
            id: 'bins',
            event: {
              title: 'Bins out',
              date: TUESDAY,
              startMinute: null,
              endMinute: null,
              recurrence: null,
            },
            memberIds: [],
            note: '   ',
          },
          {
            id: 'piano',
            event: {
              title: 'Piano',
              date: '2026-09-01',
              startMinute: 420,
              endMinute: 450,
              recurrence: everyDay(),
            },
            memberIds: ['m-sam'],
          },
        ],
        skips: [{ eventId: 'piano', occurrenceDate: '2026-09-30' }],
        synced: [
          {
            title: 'Camp',
            date: '2026-09-30',
            endDate: '2026-10-01',
            startMinute: 600,
            endMinute: 720,
            memberId: 'm-mia',
          },
        ],
      },
    }),
  );

  it('covers today and the next two days', () => {
    expect(day.calendar?.days.map((found) => found.date)).toEqual([
      TUESDAY,
      '2026-09-30',
      '2026-10-01',
    ]);
  });

  it('all day first, then by start, with local times and first names only', () => {
    expect(day.calendar?.days[0]?.events).toEqual([
      { title: 'Bins out', ...ONCE, allDay: true, start: null, end: null, who: [] },
      { title: 'Piano', ...REPEATS, allDay: false, start: '07:00', end: '07:30', who: ['Sam'] },
      {
        title: 'Swimming',
        note: 'Bring the blue towel',
        repeats: true,
        allDay: false,
        start: '15:00',
        end: '16:00',
        who: ['Mia'],
      },
    ]);
  });

  it('honours a skipped occurrence, and an import across days is all day after its first', () => {
    expect(day.calendar?.days[1]?.events.map((event) => event.title)).toEqual(['Camp', 'Swimming']);
    expect(day.calendar?.days[1]?.events[0]).toEqual({
      title: 'Camp',
      allDay: false,
      start: '10:00',
      end: null,
      who: ['Mia'],
      ...ONCE,
    });
    expect(day.calendar?.days[2]?.events).toEqual([
      { title: 'Camp', ...ONCE, allDay: true, start: null, end: null, who: ['Mia'] },
      { title: 'Piano', ...REPEATS, allDay: false, start: '07:00', end: '07:30', who: ['Sam'] },
    ]);
  });
});

describe('the to-dos panel and the helper panel', () => {
  const feed: StoredTask = {
    ...task('Feed the dog', ['m-mia'], everyDay()),
    dueDate: '2026-09-28',
    points: 3,
    needsApproval: true,
  };
  const chores = {
    tasks: [
      { id: 'dishes', task: task('Dishes', ['m-mia']) },
      { id: 'laundry', task: task('Laundry', ['m-thandi']) },
      { id: 'beds', task: task('Beds', ['m-thandi', 'm-mia']) },
      { id: 'friday', task: task('Friday only', ['m-thandi'], weeklyOn([5])) },
      { id: 'feed', task: feed, note: '  Two scoops  ' },
    ],
    routines: {},
    doneTaskIds: new Set(['beds']),
    completed: new Set([
      'laundry_2026-09-22',
      'beds_2026-09-22',
      'beds_2026-09-29',
      'friday_2026-09-25',
    ]),
  };
  const homeCare = {
    jobs: [
      job('oven', 'Deep clean the oven', 'kitchen', 'approved', TUESDAY, {
        steps: [{ id: 's1', text: 'Racks' }],
        doneStepIds: ['s1'],
      }),
      job('windows', 'Windows', 'gone', 'inProgress', TUESDAY),
      job('fridge', 'Clean the fridge', 'kitchen', 'assigned', '2026-09-27', {
        note: 'Throw out old milk',
        steps: [
          { id: 'a', text: 'Empty it' },
          { id: 'b', text: 'Wipe shelves' },
        ],
        doneStepIds: ['a'],
      }),
      job('old', 'Handed in late', 'kitchen', 'approved', '2026-09-26'),
    ],
    routines: [
      routine('bathroom-daily', 'Bathroom', 'bathroom', '2026-09-01', everyDay(), [
        { id: 'basin', text: 'Basin' },
        { id: 'floor', text: 'Floor' },
      ]),
      routine('lounge-daily', 'Lounge', 'lounge', '2026-09-01', everyDay(), [
        { id: 'dust', text: 'Dust' },
      ]),
      routine('garage-saturday', 'Garage', 'garage', '2026-09-05', weeklyOn([6]), [
        { id: 'sweep', text: 'Sweep' },
      ]),
    ],
    ticks: { 'bathroom-daily': ['basin'], 'lounge-daily': ['dust'] },
    rooms: { kitchen: 'Kitchen', bathroom: 'Main bathroom', lounge: 'Lounge' },
  };
  const day = assembleFrameDay(
    sources({
      panels: { ...NONE, todos: true, helperMemberId: 'm-thandi' },
      chores,
      homeCare,
    }),
  );

  it('lists last week’s missed chores oldest first, then today’s, then what is done', () => {
    expect(day.todos?.items).toEqual([
      {
        title: 'Dishes',
        done: false,
        kind: 'task',
        id: 'dishes',
        date: '2026-09-22',
        who: ['Mia'],
      },
      {
        title: 'Feed the dog',
        done: false,
        kind: 'task',
        id: 'feed',
        date: '2026-09-28',
        note: 'Two scoops',
        stars: 3,
        needsCheck: true,
        who: ['Mia'],
      },
      { title: 'Dishes', done: false, kind: 'task', id: 'dishes', date: TUESDAY, who: ['Mia'] },
      {
        title: 'Feed the dog',
        done: false,
        kind: 'task',
        id: 'feed',
        date: TUESDAY,
        note: 'Two scoops',
        stars: 3,
        needsCheck: true,
        who: ['Mia'],
      },
      {
        title: 'Laundry',
        done: false,
        kind: 'task',
        id: 'laundry',
        date: TUESDAY,
        who: ['Thandi'],
      },
      {
        title: 'Beds',
        done: true,
        kind: 'task',
        id: 'beds',
        date: TUESDAY,
        who: ['Thandi', 'Mia'],
      },
    ]);
  });

  it('never reaches back past the app’s overdue week', () => {
    const late = assembleFrameDay(
      sources({
        panels: { ...NONE, todos: true },
        chores: {
          ...chores,
          tasks: [
            { id: 'once', task: { ...task('Once', []), recurrence: null, dueDate: '2026-09-21' } },
          ],
        },
      }),
    );
    expect(late.todos?.items).toEqual([]);
  });

  it('gives the helper their own chores, jobs past due and today’s routines, with their steps', () => {
    expect(day.helper).toEqual({
      name: 'Thandi',
      items: [
        {
          title: 'Clean the fridge',
          done: false,
          kind: 'job',
          id: 'fridge',
          date: '2026-09-27',
          note: 'Throw out old milk',
          steps: [
            { id: 'a', text: 'Empty it', done: true },
            { id: 'b', text: 'Wipe shelves', done: false },
          ],
          detail: 'Kitchen',
        },
        { title: 'Laundry', done: false, kind: 'task', id: 'laundry', date: TUESDAY },
        { title: 'Windows', done: false, kind: 'job', id: 'windows', date: TUESDAY, steps: [] },
        {
          title: 'Bathroom',
          done: false,
          kind: 'routine',
          id: 'bathroom-daily',
          date: TUESDAY,
          steps: [
            { id: 'basin', text: 'Basin', done: true },
            { id: 'floor', text: 'Floor', done: false },
          ],
          detail: 'Main bathroom',
        },
        { title: 'Beds', done: true, kind: 'task', id: 'beds', date: TUESDAY },
        {
          title: 'Deep clean the oven',
          done: true,
          kind: 'job',
          id: 'oven',
          date: TUESDAY,
          steps: [{ id: 's1', text: 'Racks', done: true }],
          detail: 'Kitchen',
        },
        {
          title: 'Lounge',
          done: true,
          kind: 'routine',
          id: 'lounge-daily',
          date: TUESDAY,
          steps: [{ id: 'dust', text: 'Dust', done: true }],
          detail: 'Lounge',
        },
      ],
    });
  });

  it('leaves the helper panel off when that person is no longer in the household', () => {
    const gone = assembleFrameDay(
      sources({ panels: { ...NONE, helperMemberId: 'm-gone' }, chores, homeCare }),
    );
    expect(gone.helper).toBeUndefined();
  });
});

describe('a chore’s picture', () => {
  const stored = (title: string, picture: unknown): Record<string, unknown> => ({
    title,
    dueDate: TUESDAY,
    recurrence: null,
    assigneeIds: ['m-thandi'],
    routineId: null,
    picture,
  });
  const records = [
    taskRecordOf('bins', stored('Bins', 'take-out-bin')),
    taskRecordOf('beds', { ...stored('Beds', null), picture: undefined }),
    taskRecordOf('dog', stored('Dog', 'Feed Dog')),
    taskRecordOf('cat', stored('Cat', 7)),
    taskRecordOf('long', stored('Long', 'x'.repeat(49))),
  ].flatMap((record) => record ?? []);
  const day = assembleFrameDay(
    sources({
      panels: { ...NONE, todos: true, helperMemberId: 'm-thandi' },
      chores: { tasks: records, routines: {}, doneTaskIds: new Set(), completed: new Set() },
    }),
  );
  const pictures = (
    items: readonly { id: string; picture?: string }[] | undefined,
  ): Record<string, string | undefined> =>
    Object.fromEntries(
      (items ?? []).map((item) => [item.id, 'picture' in item ? item.picture : 'none']),
    );

  it('passes a sticker id through on the to-dos and the helper’s chores', () => {
    expect(day.todos?.items.find((item) => item.id === 'bins')?.picture).toBe('take-out-bin');
    expect(day.helper?.items.find((item) => item.id === 'bins')?.picture).toBe('take-out-bin');
  });

  it('leaves the key off for none, and reads a malformed one as none, still showing the chore', () => {
    const expected = {
      bins: 'take-out-bin',
      beds: 'none',
      dog: 'none',
      cat: 'none',
      long: 'none',
    };
    expect(pictures(day.todos?.items)).toEqual(expected);
    expect(pictures(day.helper?.items)).toEqual(expected);
  });
});

describe('the meals panel', () => {
  it('today’s filled slots in order, from the week that starts on Monday', () => {
    const day = assembleFrameDay(
      sources({
        panels: { ...NONE, meals: true },
        meals: {
          slots: { '2_dinner': 'curry', '2_breakfast': 'oats', '2_lunch': '', '3_dinner': 'pasta' },
          mealNames: { curry: 'Chicken curry', oats: 'Oats' },
        },
      }),
    );
    expect(day.meals).toEqual({
      slots: [
        { slot: 'breakfast', title: 'Oats' },
        { slot: 'dinner', title: 'Chicken curry' },
      ],
    });
    expect(mondayOf(TUESDAY)).toBe('2026-09-28');
    expect(mondayOf('2026-10-04')).toBe('2026-09-28');
    expect(mondayOf('2026-09-28')).toBe('2026-09-28');
  });
});

describe('an event’s note and whether it repeats', () => {
  it('a note is trimmed, capped at five hundred characters, and null when blank', () => {
    expect(frameNote('  Gate code 4521 \n')).toBe('Gate code 4521');
    expect(frameNote(' \t ')).toBeNull();
    expect(frameNote(null)).toBeNull();
    expect(frameNote('x'.repeat(NOTE_MAX + 20))).toHaveLength(NOTE_MAX);
    expect(Array.from(frameNote('🎒'.repeat(NOTE_MAX + 1)) ?? '')).toHaveLength(NOTE_MAX);
  });

  it('an import has no note and never repeats', () => {
    const day = assembleFrameDay(
      sources({
        panels: { ...NONE, calendar: true },
        events: {
          own: [],
          skips: [],
          synced: [
            {
              title: 'Dentist',
              date: TUESDAY,
              endDate: TUESDAY,
              startMinute: 600,
              endMinute: 630,
              memberId: 'm-sam',
            },
          ],
        },
      }),
    );
    expect(day.calendar?.days[0]?.events[0]).toMatchObject({ note: null, repeats: false });
  });
});

describe('the household’s members', () => {
  it('the same first names who[] prints, by name, with the palette colour as hex', () => {
    const day = assembleFrameDay(
      sources({
        names: { 'm-zoe': 'Zoë  Parker', 'm-blank': '   ', 'm-ali': 'Ali', 'm-sam': 'Sam Parker' },
        colors: { 'm-zoe': 'plum', 'm-ali': 'constructor' },
      }),
    );
    expect(day.household.members).toEqual([
      { name: 'Ali', color: null },
      { name: 'Sam', color: null },
      { name: 'Zoë', color: '#E2BFF2' },
    ]);
  });

  it('marks a kid with kid: true and leaves the key off everyone else', () => {
    const day = assembleFrameDay(sources({ kids: ['m-mia', 'm-gone'] }));
    expect(day.household.members).toEqual([
      { name: 'Mia', color: '#FFC2B3', kid: true },
      { name: 'Sam', color: '#8ED3DA' },
      { name: 'Thandi', color: null },
    ]);
  });
});

describe('the lunch panel', () => {
  const lunch = [
    {
      childId: 'm-sam',
      picks: [
        { slot: 'treat' as const, name: 'Rusk' },
        { slot: 'main' as const, name: 'Cheese sandwich' },
        { slot: 'fruit' as const, name: 'Apple' },
      ],
    },
    { childId: 'm-mia', picks: [{ slot: 'snack' as const, name: 'Popcorn' }] },
    { childId: 'm-gone', picks: [{ slot: 'main' as const, name: 'Wrap' }] },
  ];

  it('each child’s box by first name, slots from main to treat, names only', () => {
    const day = assembleFrameDay(sources({ panels: { ...NONE, lunch: true }, lunch }));
    expect(day.lunch).toEqual({
      boxes: [
        { name: 'Mia', items: [{ slot: 'snack', title: 'Popcorn' }] },
        {
          name: 'Sam',
          items: [
            { slot: 'main', title: 'Cheese sandwich' },
            { slot: 'fruit', title: 'Apple' },
            { slot: 'treat', title: 'Rusk' },
          ],
        },
      ],
    });
  });

  it('a box the household has a ready picture of names it, and only that box', () => {
    const day = assembleFrameDay(
      sources({
        panels: { ...NONE, lunch: true },
        lunch,
        lunchPhotos: { 'm-sam': { id: 'a1b2c3d4e5f60718293a4b5c6d7e8f9012345678' } },
      }),
    );
    expect(day.lunch?.boxes.map((box) => box.photo)).toEqual([
      undefined,
      'a1b2c3d4e5f60718293a4b5c6d7e8f9012345678',
    ]);
    expect(day.lunch?.boxes[0]).not.toHaveProperty('photo');
  });

  it('is empty on a weekend, and absent when switched off', () => {
    const saturday = assembleFrameDay(
      sources({ panels: { ...NONE, lunch: true }, today: '2026-10-03', lunch }),
    );
    expect(saturday.lunch).toEqual({ boxes: [] });
    expect(assembleFrameDay(sources({ lunch })).lunch).toBeUndefined();
  });

  it('a frame stored before the switch existed has it off', () => {
    const stored = frameDocument.parse({
      name: 'Kitchen',
      panels: { calendar: true, todos: true, meals: true, helperMemberId: null },
      lastSeenAt: null,
    });
    expect(stored.panels.lunch).toBe(false);
  });
});

describe('the small pieces', () => {
  it('asks again every minute from six to ten, every half hour overnight, and at midnight', () => {
    expect(refreshAfterSeconds(6 * 60 - 1)).toBe(1800);
    expect(refreshAfterSeconds(6 * 60)).toBe(60);
    expect(refreshAfterSeconds(22 * 60 - 1)).toBe(60);
    expect(refreshAfterSeconds(22 * 60)).toBe(1800);
    expect(refreshAfterSeconds(23 * 60 + 45)).toBe(15 * 60);
    expect(refreshAfterSeconds(23 * 60 + 59)).toBe(60);
  });

  it('marks a frame seen at most once a quarter hour', () => {
    const now = new Date('2026-09-29T09:00:00Z');
    expect(lastSeenIsStale(null, now)).toBe(true);
    expect(lastSeenIsStale(new Date('2026-09-29T08:46:00Z'), now)).toBe(false);
    expect(lastSeenIsStale(new Date('2026-09-29T08:45:00Z'), now)).toBe(true);
  });

  it('writes times as HH:mm and names as the first word', () => {
    expect(clockTime(0)).toBe('00:00');
    expect(clockTime(13 * 60 + 5)).toBe('13:05');
    expect(clockTime(null)).toBeNull();
    expect(firstName(' Sam  Parker ')).toBe('Sam');
  });

  it('never enforces App Check on the device callables', () => {
    expect(FRAME_DEVICE_OPTIONS.enforceAppCheck).toBe(false);
  });

  it('lets one frame retry an unlink, not loop it', () => {
    expect(FRAME_UNLINK_PER_CREDENTIAL).toEqual({
      name: 'unlinkFrame:credential',
      limit: 10,
      windowSeconds: 3600,
    });
  });

  it('carries its reason in the details, like every refusal', () => {
    const error = refuseFrame('tooManyFrames');
    expect(error.code).toBe('resource-exhausted');
    expect(error.details).toEqual({ reason: 'tooManyFrames' });
  });
});

describe('a poll never says why a code will not do', () => {
  const later = Date.parse('2026-09-29T09:10:00Z');
  const pairing = {
    secretHash: 'right',
    model: null,
    status: 'waiting' as const,
    expiresAt: Timestamp.fromMillis(later),
  };

  it('waiting, and expired for a wrong secret, a missing code or a late poll', () => {
    expect(answerFor(pairing, 'right', later - 1)).toEqual({ status: 'waiting' });
    expect(answerFor(pairing, 'wrong', later - 1)).toEqual({ status: 'expired' });
    expect(answerFor(null, 'right', later - 1)).toEqual({ status: 'expired' });
    expect(answerFor(pairing, 'right', later)).toEqual({ status: 'expired' });
  });

  it('linked, even late, for the secret that asked', () => {
    const linked = { ...pairing, status: 'linked' as const, householdName: 'The Parkers' };
    expect(answerFor(linked, 'right', later + 60_000)).toEqual({
      status: 'linked',
      householdName: 'The Parkers',
    });
    expect(answerFor(linked, 'wrong', later - 1)).toEqual({ status: 'expired' });
  });
});

describe('the frame callables’ edge', () => {
  it.each([
    ['a secret too short', { secret: 'a'.repeat(31) }],
    ['a secret too long', { secret: 'a'.repeat(129) }],
    ['a secret outside base64url', { secret: `${'a'.repeat(42)}=` }],
    ['a model past sixty characters', { secret: SECRET, model: 'm'.repeat(61) }],
  ])('startFramePairing refuses %s', (_, body) => {
    expect(() => parseInput(startFramePairingInput, body)).toThrow(HttpsError);
  });

  it('getFrameDay and unlinkFrame take the secret alone', () => {
    expect(parseInput(getFrameDayInput, { secret: SECRET })).toEqual({ secret: SECRET });
    expect(parseInput(unlinkFrameInput, { secret: SECRET })).toEqual({ secret: SECRET });
    expect(() => parseInput(unlinkFrameInput, { secret: 'short' })).toThrow(HttpsError);
  });

  const claim = {
    householdId: 'h1',
    code: 'abc234',
    name: '  Kitchen ',
    panels: { calendar: true, todos: false, meals: true, helperMemberId: null },
  };

  it('claimFramePairing trims the name and reads the code in upper case', () => {
    const parsed = parseInput(claimFramePairingInput, claim);
    expect(parsed.name).toBe('Kitchen');
    expect(parsed.code).toBe('ABC234');
  });

  it('claimFramePairing takes the lunch switch, and an older app’s claim has it off', () => {
    expect(parseInput(claimFramePairingInput, claim).panels.lunch).toBe(false);
    const withLunch = { ...claim, panels: { ...claim.panels, lunch: true } };
    expect(parseInput(claimFramePairingInput, withLunch).panels.lunch).toBe(true);
  });

  it.each([
    ['a blank name', { ...claim, name: '   ' }],
    ['a name past forty', { ...claim, name: 'x'.repeat(41) }],
    ['a panel missing', { ...claim, panels: { calendar: true, todos: false, meals: true } }],
    ['a panel that is not a switch', { ...claim, panels: { ...claim.panels, todos: 'yes' } }],
    ['a lunch switch that is not one', { ...claim, panels: { ...claim.panels, lunch: 'yes' } }],
  ])('claimFramePairing refuses %s', (_, body) => {
    expect(() => parseInput(claimFramePairingInput, body)).toThrow(HttpsError);
  });
});
