import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import {
  type FrameDaySources,
  type HomeCareJobRecord,
  assembleFrameDay,
  frameShiftSince,
} from '../../../src/frames/frame_day';
import { FRAME_REFUSALS } from '../../../src/frames/frame_errors';
import {
  MARK_LIMIT,
  MARK_POINT_LIMIT,
  frameJobPhotoShape,
  frameJobShape,
  frameMarks,
  handInFields,
  hasFramePhoto,
} from '../../../src/frames/frame_jobs';
import {
  FRAME_JOB_PHOTO_PER_CREDENTIAL,
  FRAME_SHIFT_PER_CREDENTIAL,
} from '../../../src/frames/frame_policy';
import { setFrameShiftInput } from '../../../src/frames/frame_schemas';
import { parseInput } from '../../../src/household/parse_input';

/** A job's photo, its hand-in and the helper's clock on a frame (photo-frames ADR-0020). */

const TUESDAY = '2026-09-29';
const SECRET = 'a'.repeat(43);
const JOB_ID = 'oven-door-0001';

function job(more: Partial<HomeCareJobRecord> = {}): HomeCareJobRecord {
  return {
    id: JOB_ID,
    title: 'Oven door',
    roomId: 'kitchen',
    status: 'assigned',
    dueDate: TUESDAY,
    note: null,
    steps: [{ id: 's1', text: 'Spray' }],
    doneStepIds: [],
    ...more,
  };
}

function dayWith(
  jobs: HomeCareJobRecord[],
  more: Partial<NonNullable<FrameDaySources['homeCare']>> = {},
  timeZone: string | null = 'Africa/Johannesburg',
): NonNullable<ReturnType<typeof assembleFrameDay>['helper']> {
  const day = assembleFrameDay({
    householdName: 'The Parkers',
    frameName: 'Kitchen',
    panels: {
      calendar: false,
      todos: false,
      meals: false,
      lunch: false,
      addEvents: false,
      share: false,
      people: false,
      helperMemberId: 'm-thandi',
    },
    screensaver: null,
    today: TUESDAY,
    localMinute: 9 * 60,
    names: { 'm-thandi': 'Thandi Mokoena' },
    colors: {},
    timeZone,
    homeCare: { jobs, routines: [], ticks: {}, rooms: {}, ...more },
  });
  if (day.helper === undefined) throw new Error('no helper panel');
  return day.helper;
}

describe('a job’s photo on the wall', () => {
  it('is named by the job’s own id, with the parent’s circles', () => {
    const [item] = dayWith([job({ hasPhoto: true, marks: [[0.1, 0.2, 0.3, 0.4]] })]).items;
    expect(item).toMatchObject({ kind: 'job', photo: JOB_ID, marks: [[0.1, 0.2, 0.3, 0.4]] });
  });

  it('is left off, circles and all, when the job has none the frame can ask for', () => {
    const [item] = dayWith([job({ hasPhoto: false, marks: [[0.1, 0.2, 0.3, 0.4]] })]).items;
    expect(item).not.toHaveProperty('photo');
    expect(item).not.toHaveProperty('marks');
    const [bare] = dayWith([job({ hasPhoto: true, marks: [] })]).items;
    expect(bare).toHaveProperty('photo', JOB_ID);
    expect(bare).not.toHaveProperty('marks');
  });

  it('can be asked for only by an id the photo endpoint takes, with a before photo', () => {
    const before = { photoId: 'before', width: 1600, height: 1200 };
    expect(hasFramePhoto(JOB_ID, before)).toBe(true);
    expect(hasFramePhoto('oven', before)).toBe(false);
    expect(hasFramePhoto(JOB_ID, { photoId: 'after-1', width: 1, height: 1 })).toBe(false);
    expect(hasFramePhoto(JOB_ID, null)).toBe(false);
    expect(hasFramePhoto(JOB_ID, undefined)).toBe(false);
  });

  it('keeps circles inside the photo, to three places, whole points only', () => {
    expect(frameMarks([{ points: [0.12345, -1, 2, 0.5, 0.9] }])).toEqual([[0.123, 0, 1, 0.5]]);
  });

  it('drops what is not a stroke, and caps strokes and points as the rules do', () => {
    expect(frameMarks(undefined)).toEqual([]);
    expect(frameMarks('circle')).toEqual([]);
    expect(
      frameMarks([{ points: [0.1, 0.2] }, { points: 'x' }, 7, { points: [0, 0, NaN, 1] }]),
    ).toEqual([]);
    const long = { points: Array.from({ length: 1000 }, () => 0.5) };
    const many = frameMarks(Array.from({ length: 30 }, () => long));
    expect(many).toHaveLength(MARK_LIMIT);
    expect(many[0]).toHaveLength(MARK_POINT_LIMIT * 2);
  });

  it('is found only for a stored job that names its helper, due date and before photo', () => {
    const stored = {
      helperId: 'm-thandi',
      dueDate: TUESDAY,
      beforePhoto: { photoId: 'before', width: 1600, height: 1200 },
    };
    expect(frameJobPhotoShape.safeParse(stored).success).toBe(true);
    expect(frameJobPhotoShape.safeParse({ ...stored, beforePhoto: null }).success).toBe(false);
    expect(frameJobPhotoShape.safeParse({ dueDate: TUESDAY }).success).toBe(false);
  });

  it('is limited per frame by the hour', () => {
    expect(FRAME_JOB_PHOTO_PER_CREDENTIAL).toEqual({
      name: 'getFrameJobPhoto:credential',
      limit: 120,
      windowSeconds: 3600,
    });
  });
});

describe('handing a job in from the wall', () => {
  it('ticks every step, clears the after photo and moves one revision on', () => {
    const stored = frameJobShape.parse({
      helperId: 'm-thandi',
      status: 'sentBack',
      dueDate: TUESDAY,
      steps: [
        { id: 's1', text: 'Spray' },
        { id: 's2', text: 'Wipe' },
      ],
      revision: 3,
    });
    expect(handInFields(stored)).toEqual({
      doneStepIds: ['s1', 's2'],
      afterPhoto: null,
      status: 'submitted',
      revision: 4,
    });
  });

  it('reads nothing as a job that has no helper, status, date or revision', () => {
    expect(frameJobShape.safeParse({ helperId: 'm-thandi', status: 'assigned' }).success).toBe(
      false,
    );
    expect(
      frameJobShape.safeParse({
        helperId: 'm-thandi',
        status: 'assigned',
        dueDate: TUESDAY,
        revision: -1,
      }).success,
    ).toBe(false);
  });

  it('a job handed in waits for a parent; an approved one does not', () => {
    const { items } = dayWith([
      job({ status: 'submitted' }),
      job({ id: 'windows-00001', status: 'approved' }),
      job({ id: 'fridge-000001', status: 'inProgress' }),
    ]);
    const byId = Object.fromEntries(items.map((item) => [item.id, item]));
    expect(byId[JOB_ID]).toMatchObject({ done: true, needsCheck: true });
    expect(byId['windows-00001']).toMatchObject({ done: true });
    expect(byId['windows-00001']).not.toHaveProperty('needsCheck');
    expect(byId['fridge-000001']).toMatchObject({ done: false });
    expect(byId['fridge-000001']).not.toHaveProperty('needsCheck');
  });
});

describe('the helper’s clock on the wall', () => {
  it('says nothing while shifts are off', () => {
    expect(dayWith([])).not.toHaveProperty('shift');
  });

  it('says she is clocked out', () => {
    expect(dayWith([], { shiftStartedAt: null }).shift).toEqual({ on: false });
  });

  it('says since when, on the household’s clock', () => {
    const startedAt = new Date('2026-09-29T05:32:10Z');
    expect(dayWith([], { shiftStartedAt: startedAt }).shift).toEqual({
      on: true,
      since: '07:32',
      sinceDate: TUESDAY,
    });
    expect(dayWith([], { shiftStartedAt: startedAt }, null).shift).toEqual({
      on: true,
      since: '05:32',
      sinceDate: TUESDAY,
    });
  });

  it('a shift from last night still says the day it started', () => {
    expect(dayWith([], { shiftStartedAt: new Date('2026-09-28T21:05:00Z') }).shift).toEqual({
      on: true,
      since: '23:05',
      sinceDate: '2026-09-28',
    });
  });

  it('a start just made is said from the frame’s own wall clock', () => {
    expect(frameShiftSince({ date: TUESDAY, minute: 7 * 60 + 5 })).toEqual({
      on: true,
      since: '07:05',
      sinceDate: TUESDAY,
    });
  });

  it('setFrameShift takes the secret and which way, and nothing else', () => {
    expect(parseInput(setFrameShiftInput, { secret: SECRET, on: false })).toEqual({
      secret: SECRET,
      on: false,
    });
    for (const bad of [{ secret: SECRET }, { secret: SECRET, on: 'yes' }, { on: true }]) {
      expect(() => parseInput(setFrameShiftInput, bad)).toThrow(HttpsError);
    }
  });

  it('is limited per frame by the hour, and refused in words while switched off', () => {
    expect(FRAME_SHIFT_PER_CREDENTIAL).toEqual({
      name: 'setFrameShift:credential',
      limit: 30,
      windowSeconds: 3600,
    });
    expect(FRAME_REFUSALS.shiftsOff[0]).toBe('failed-precondition');
  });
});
