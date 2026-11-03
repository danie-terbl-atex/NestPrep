import { randomBytes } from 'node:crypto';

import { type DocumentReference, Timestamp } from 'firebase-admin/firestore';
import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import { addDays, wallClockOf, weekdayOf } from '../../src/calendar_sync/zoned_time';
import { secretHash } from '../../src/frames/frame_documents';
import { awaitFrameShare } from '../../src/frames/frame_shares';
import { combinationOf } from '../../src/lunch_photos/combination';
import {
  FRAME_ADD_EVENT_PER_CREDENTIAL,
  FRAME_PHOTO_PER_CREDENTIAL,
} from '../../src/frames/frame_policy';
import { ROLE_DEFAULTS } from '../../src/household/access';
import { RATE_LIMITS, rateLimitId } from '../../src/shared/rate_limit';
import { weekKeyOf } from '../../src/product_analytics/iso_week';
import {
  type Household,
  addProfile,
  exists,
  expectRefusal,
  household,
  joinAs,
  pairKidDevice,
  samsHousehold,
} from './account_data_fixture';
import { weeklyOn } from '../recurrence_shape';
import { eventually } from './product_analytics_fixture';
import {
  adminDb,
  adminStorage,
  callAs,
  clearFirestore,
  closeAdmin,
  httpFunctionUrl,
  signUp,
} from './emulator_harness';

/**
 * Photo frames end to end, over HTTP the way a frame and the app call them
 * (photo-frames ADR-0001, `BE-14`): the frame asks for a code with no token
 * at all, a parent claims it, the frame learns it is linked and reads its
 * day — only the panels switched on — and deleting the frame unlinks it.
 */

beforeEach(clearFirestore);
afterAll(closeAdmin);

interface Pairing {
  code: string;
  expiresAt: number;
  pollSeconds: number;
}

interface Day {
  status: string;
  household?: { name: string; members: { name: string; color: string | null }[] };
  frame?: { name: string };
  today?: string;
  refreshAfterSeconds?: number;
  calendar?: { days: { date: string; events: Record<string, unknown>[] }[] };
  addEvents?: { by: string[] };
  todos?: { items: Record<string, unknown>[] };
  helper?: { name: string; items: Record<string, unknown>[] };
  meals?: { slots: Record<string, unknown>[] };
  lunch?: { boxes: { name: string; photo?: string }[] };
  groceries?: { shop: string; by: string[]; toBuy: Record<string, unknown>[] };
}

const PANELS = { calendar: true, todos: true, meals: false, helperMemberId: null };

const newSecret = (): string => randomBytes(32).toString('base64url');

async function start(secret: string): Promise<Pairing> {
  return callAs<Pairing>(null, 'startFramePairing', { secret, model: 'Frameo 10' });
}

async function poll(code: string, secret: string): Promise<Record<string, unknown>> {
  return callAs(null, 'pollFramePairing', { code, secret });
}

async function claim(
  h: Household,
  code: string,
  panels: Record<string, unknown> = PANELS,
  name = ' Kitchen ',
): Promise<{ frameId: string }> {
  return callAs(h.sam, 'claimFramePairing', { householdId: h.householdId, code, name, panels });
}

async function dayOf(secret: string): Promise<Day> {
  return callAs<Day>(null, 'getFrameDay', { secret });
}

async function unlink(secret: string): Promise<Record<string, unknown>> {
  return callAs(null, 'unlinkFrame', { secret });
}

/** A frame linked to Sam's household with [panels]. */
async function linkedFrame(
  h: Household,
  panels: Record<string, unknown> = PANELS,
): Promise<{ secret: string; frameId: string }> {
  const secret = newSecret();
  const { code } = await start(secret);
  const { frameId } = await claim(h, code, panels);
  return { secret, frameId };
}

const today = (): string => wallClockOf(new Date(), 'Africa/Johannesburg').date;

/** Today's things in every area a frame can show. */
async function givenToday(h: Household, thandi: string): Promise<void> {
  const home = household(h.householdId);
  const date = today();
  await home
    .collection('events')
    .doc('swim')
    .set({
      title: 'Swimming',
      note: 'Bring the blue towel',
      date,
      startMinute: 900,
      endMinute: 960,
      recurrence: null,
      memberIds: [h.samMemberId],
      createdBy: h.samMemberId,
    });
  await home
    .collection('events')
    .doc('later')
    .set({
      title: 'Dentist',
      date: addDays(date, 2),
      startMinute: null,
      endMinute: null,
      recurrence: null,
      memberIds: [],
      createdBy: h.samMemberId,
    });
  await home
    .collection('tasks')
    .doc('laundry')
    .set({
      title: 'Laundry',
      dueDate: date,
      recurrence: null,
      assigneeIds: [thandi],
      routineId: null,
      createdBy: h.samMemberId,
    });
  await home
    .collection('tasks')
    .doc('bins')
    .set({
      title: 'Bins',
      dueDate: date,
      recurrence: null,
      assigneeIds: [h.samMemberId],
      routineId: null,
      createdBy: h.samMemberId,
    });
  await home.collection('taskCompletions').doc(`bins_${date}`).set({
    taskId: 'bins',
    occurrenceDate: date,
    completedBy: h.samMemberId,
    completedFor: h.samMemberId,
  });
  await home
    .collection('meals')
    .doc('curry')
    .set({ name: 'Chicken curry', nameKey: 'chicken curry' });
  await home
    .collection('mealPlans')
    .doc(addDays(date, 1 - weekdayOf(date)))
    .set({ slots: { [`${String(weekdayOf(date))}_dinner`]: 'curry' } });
  await home.collection('homeCareRooms').doc('kitchen').set({ name: 'Kitchen', kind: 'kitchen' });
  await home.collection('homeCareJobs').doc('oven').set({
    title: 'Clean the oven',
    roomId: 'kitchen',
    helperId: thandi,
    dueDate: date,
    status: 'assigned',
    note: 'Gloves under the sink',
  });
}

describe('a frame pairs, is claimed, and reads its day', () => {
  it('start → waiting → claim → linked once → the day → unlinked when deleted', async () => {
    const h = await samsHousehold();
    const thandi = await addProfile(h.householdId, 'Thandi Mokoena', 'helper');
    await givenToday(h, thandi);

    const secret = newSecret();
    const before = Date.now();
    const pairing = await start(secret);
    expect(pairing.code).toMatch(/^[2-9A-HJKMNP-Z]{6}$/);
    expect(pairing.pollSeconds).toBe(4);
    expect(pairing.expiresAt).toBeGreaterThanOrEqual(before + 10 * 60 * 1000 - 1000);
    const stored = await adminDb().doc(`framePairings/${pairing.code}`).get();
    expect(stored.get('secretHash')).toBe(secretHash(secret));
    expect(JSON.stringify(stored.data())).not.toContain(secret);

    expect(await poll(pairing.code, secret)).toEqual({ status: 'waiting' });

    const { frameId } = await claim(h, pairing.code.toLowerCase(), {
      calendar: true,
      todos: false,
      meals: true,
      helperMemberId: thandi,
    });
    const frame = await household(h.householdId).collection('frames').doc(frameId).get();
    expect(frame.data()).toMatchObject({
      name: 'Kitchen',
      model: 'Frameo 10',
      linkedBy: h.samMemberId,
      lastSeenAt: null,
    });
    expect(await exists(`frameCredentials/${secretHash(secret)}`)).toBe(true);

    expect(await poll(pairing.code, secret)).toEqual({
      status: 'linked',
      householdName: 'The Parkers',
    });
    expect(await exists(`framePairings/${pairing.code}`)).toBe(false);
    expect(await poll(pairing.code, secret)).toEqual({ status: 'expired' });

    const day = await dayOf(secret);
    expect(day).toMatchObject({
      status: 'linked',
      household: { name: 'The Parkers' },
      frame: { name: 'Kitchen' },
      today: today(),
    });
    expect(day.refreshAfterSeconds).toBeGreaterThanOrEqual(60);
    expect(day.refreshAfterSeconds).toBeLessThanOrEqual(1800);
    expect(day.todos).toBeUndefined();
    expect(day.calendar?.days.map((found) => found.date)).toEqual([
      today(),
      addDays(today(), 1),
      addDays(today(), 2),
    ]);
    expect(day.household?.members).toEqual([
      { name: 'Sam', color: '#C9BFFF' },
      { name: 'Thandi', color: '#86D9B8' },
    ]);
    expect(day.calendar?.days[0]?.events).toEqual([
      {
        title: 'Swimming',
        allDay: false,
        start: '15:00',
        end: '16:00',
        who: ['Sam'],
        note: 'Bring the blue towel',
        repeats: false,
      },
    ]);
    expect(day.calendar?.days[2]?.events).toEqual([
      {
        title: 'Dentist',
        allDay: true,
        start: null,
        end: null,
        who: [],
        note: null,
        repeats: false,
      },
    ]);
    expect(day.helper).toEqual({
      name: 'Thandi',
      items: [
        { title: 'Laundry', done: false, kind: 'task', id: 'laundry', date: today() },
        {
          title: 'Clean the oven',
          done: false,
          kind: 'job',
          id: 'oven',
          date: today(),
          note: 'Gloves under the sink',
          steps: [],
          detail: 'Kitchen',
        },
      ],
    });
    expect(day.meals).toEqual({ slots: [{ slot: 'dinner', title: 'Chicken curry' }] });
    const said = JSON.stringify(day);
    for (const hidden of [h.householdId, frameId, thandi, h.samMemberId, h.sam.uid, 'violet']) {
      expect(said).not.toContain(hidden);
    }
    const seen = await household(h.householdId).collection('frames').doc(frameId).get();
    expect(seen.get('lastSeenAt')).toBeInstanceOf(Timestamp);

    await household(h.householdId).collection('frames').doc(frameId).delete();
    expect(await dayOf(secret)).toEqual({ status: 'unlinked' });
    expect(await exists(`frameCredentials/${secretHash(secret)}`)).toBe(false);
  });

  it('shows to-dos when switched on, done ones last, and nothing else', async () => {
    const h = await samsHousehold();
    const thandi = await addProfile(h.householdId, 'Thandi', 'helper');
    await givenToday(h, thandi);
    const { secret } = await linkedFrame(h, {
      calendar: false,
      todos: true,
      meals: false,
      helperMemberId: null,
    });
    const day = await dayOf(secret);
    expect(day.todos).toEqual({
      items: [
        {
          title: 'Laundry',
          done: false,
          kind: 'task',
          id: 'laundry',
          date: today(),
          who: ['Thandi'],
        },
        { title: 'Bins', done: true, kind: 'task', id: 'bins', date: today(), who: ['Sam'] },
      ],
    });
    expect(day.calendar).toBeUndefined();
    expect(day.helper).toBeUndefined();
    expect(day.meals).toBeUndefined();
    expect(day.lunch).toBeUndefined();
  });

  it('shows each child’s lunch box today by first name, names only', async () => {
    const h = await samsHousehold();
    const mia = await addProfile(h.householdId, 'Mia Parker', 'kid');
    const date = today();
    const weekday = weekdayOf(date);
    const week = weekKeyOf(new Date(`${date}T12:00:00Z`), 'UTC');
    await household(h.householdId)
      .collection('lunchPlans')
      .doc(`${mia}_${week}`)
      .set({
        childId: mia,
        week,
        weekStart: addDays(date, 1 - weekday),
        slots: {
          [`${String(weekday)}_treat`]: { itemId: 'i3', name: 'Rusk', allergens: ['gluten'] },
          [`${String(weekday)}_main`]: {
            itemId: 'i1',
            name: 'Cheese sandwich',
            allergens: ['milk', 'gluten'],
          },
        },
        feedback: {},
      });
    const { secret } = await linkedFrame(h, { ...PANELS, calendar: false, lunch: true });
    const day = await dayOf(secret);
    expect(day.lunch).toEqual({
      boxes:
        weekday > 5
          ? []
          : [
              {
                name: 'Mia',
                items: [
                  { slot: 'main', title: 'Cheese sandwich' },
                  { slot: 'treat', title: 'Rusk' },
                ],
              },
            ],
    });
    expect(JSON.stringify(day)).not.toContain('milk');
  });

  it('a secret nobody linked reads unlinked', async () => {
    expect(await dayOf(newSecret())).toEqual({ status: 'unlinked' });
  });

  it('a frame that pairs again moves, and the frame it was is gone', async () => {
    const h = await samsHousehold();
    const { secret, frameId } = await linkedFrame(h);
    const { code } = await start(secret);
    const second = await claim(h, code);
    expect(await exists(`households/${h.householdId}/frames/${frameId}`)).toBe(false);
    const credential = await adminDb()
      .doc(`frameCredentials/${secretHash(secret)}`)
      .get();
    expect(credential.get('frameId')).toBe(second.frameId);
  });

  it('closing the household removes its frames, their credentials and their codes', async () => {
    const h = await samsHousehold();
    const { secret } = await linkedFrame(h);
    const { code } = await start(newSecret());
    await claim(h, code);
    await callAs(h.sam, 'closeHousehold', { householdId: h.householdId, confirmation: 'CLOSE' });
    expect(await exists(`frameCredentials/${secretHash(secret)}`)).toBe(false);
    expect(await exists(`framePairings/${code}`)).toBe(false);
    expect(await dayOf(secret)).toEqual({ status: 'unlinked' });
  });
});

interface Month {
  status: string;
  today?: string;
  month?: string;
  days?: { date: string; events: { title: string; who: string[] }[] }[];
}

async function monthOf(secret: string, month: string): Promise<Month> {
  return callAs<Month>(null, 'getFrameMonth', { secret, month });
}

async function tick(secret: string, body: Record<string, unknown>): Promise<unknown> {
  return callAs(null, 'tickFrameItem', { secret, ...body });
}

describe('a frame ticks off what it shows (photo-frames ADR-0007)', () => {
  async function given(h: Household): Promise<{ mia: string; thandi: string }> {
    const mia = await addProfile(h.householdId, 'Mia Parker', 'kid');
    const thandi = await addProfile(h.householdId, 'Thandi', 'helper');
    const home = household(h.householdId);
    const chore = (
      title: string,
      dueDate: string,
      assigneeIds: string[],
      points = 0,
    ): Record<string, unknown> => ({
      title,
      note: '  Two scoops  ',
      dueDate,
      recurrence: null,
      assigneeIds,
      routineId: null,
      points,
      needsApproval: false,
      createdBy: h.samMemberId,
    });
    await home
      .collection('tasks')
      .doc('feed')
      .set(chore('Feed the dog', addDays(today(), -1), [mia], 5));
    await home
      .collection('tasks')
      .doc('bins')
      .set(chore('Bins', today(), []));
    await home
      .collection('tasks')
      .doc('old')
      .set(chore('Long ago', addDays(today(), -8), [mia]));
    await home
      .collection('homeCareRoutines')
      .doc('bathroom')
      .set({
        name: 'Bathroom',
        roomId: 'bath',
        cadence: 'daily',
        helperId: thandi,
        firstDate: addDays(today(), -30),
        recurrence: { frequency: 'daily', interval: 1, weekdays: [], until: null },
        items: [
          { id: 'basin', text: 'Basin' },
          { id: 'floor', text: 'Floor' },
        ],
        createdBy: h.samMemberId,
      });
    return { mia, thandi };
  }

  it('shows yesterday’s missed chore and ticks it for its kid, who earns its stars', async () => {
    const h = await samsHousehold();
    const { mia } = await given(h);
    const { secret } = await linkedFrame(h, { ...PANELS, calendar: false });
    const yesterday = addDays(today(), -1);

    const day = await dayOf(secret);
    expect(day.todos?.items).toEqual([
      {
        title: 'Feed the dog',
        done: false,
        kind: 'task',
        id: 'feed',
        date: yesterday,
        note: 'Two scoops',
        stars: 5,
        who: ['Mia'],
      },
      {
        title: 'Bins',
        done: false,
        kind: 'task',
        id: 'bins',
        date: today(),
        note: 'Two scoops',
        who: [],
      },
    ]);

    expect(
      await tick(secret, { kind: 'task', id: 'feed', date: yesterday, done: true, by: 'Sam' }),
    ).toEqual({
      status: 'linked',
      done: true,
    });
    const completion = await household(h.householdId)
      .collection('taskCompletions')
      .doc(`feed_${yesterday}`)
      .get();
    expect(completion.data()).toMatchObject({
      taskId: 'feed',
      occurrenceDate: yesterday,
      completedBy: mia,
      completedFor: mia,
    });
    expect(completion.get('completedAt')).toBeInstanceOf(Timestamp);
    const claim = await eventually(
      async () =>
        (
          await household(h.householdId).collection('pointClaims').doc(`feed_${yesterday}`).get()
        ).data(),
      (value) => value?.['status'] === 'awarded',
    );
    expect(claim).toMatchObject({ memberId: mia, points: 5 });
    expect((await dayOf(secret)).todos?.items.map((item) => item['id'])).toEqual(['bins']);

    await tick(secret, { kind: 'task', id: 'feed', date: yesterday, done: false });
    expect(await exists(`households/${h.householdId}/taskCompletions/feed_${yesterday}`)).toBe(
      false,
    );
  });

  it('asks who did a chore that is anybody’s, and credits that first name', async () => {
    const h = await samsHousehold();
    await given(h);
    const { secret } = await linkedFrame(h, { ...PANELS, calendar: false });
    await expectRefusal(
      tick(secret, { kind: 'task', id: 'bins', date: today(), done: true }),
      'whoNeeded',
    );
    await expectRefusal(
      tick(secret, { kind: 'task', id: 'bins', date: today(), done: true, by: 'Nobody' }),
      'whoNeeded',
    );
    await tick(secret, { kind: 'task', id: 'bins', date: today(), done: true, by: 'sam' });
    const done = await household(h.householdId)
      .collection('taskCompletions')
      .doc(`bins_${today()}`)
      .get();
    expect(done.get('completedFor')).toBe(h.samMemberId);
    expect(done.get('completedBy')).toBe(h.samMemberId);

    await tick(secret, { kind: 'task', id: 'bins', date: today(), done: true, by: 'Mia' });
    const again = await household(h.householdId)
      .collection('taskCompletions')
      .doc(`bins_${today()}`)
      .get();
    expect(again.get('completedFor')).toBe(h.samMemberId);
  });

  it('refuses what it does not show, a day past the week, and a stranger’s secret', async () => {
    const h = await samsHousehold();
    await given(h);
    const { secret } = await linkedFrame(h, { ...PANELS, todos: false });
    await expectRefusal(
      tick(secret, { kind: 'task', id: 'bins', date: today(), done: true, by: 'Sam' }),
      'itemNotFound',
    );
    await expectRefusal(
      tick(secret, { kind: 'routine', id: 'bathroom', date: today(), done: true }),
      'itemNotFound',
    );
    const shown = await linkedFrame(h, { ...PANELS, calendar: false });
    await expectRefusal(
      tick(shown.secret, { kind: 'task', id: 'old', date: addDays(today(), -8), done: true }),
      'itemOutOfReach',
    );
    await expectRefusal(
      tick(shown.secret, {
        kind: 'task',
        id: 'bins',
        date: addDays(today(), 1),
        done: true,
        by: 'Sam',
      }),
      'itemOutOfReach',
    );
    await expectRefusal(
      tick(shown.secret, { kind: 'task', id: 'feed', date: today(), done: true }),
      'itemNotFound',
    );
    expect(
      await tick(newSecret(), { kind: 'task', id: 'bins', date: today(), done: true }),
    ).toEqual({
      status: 'unlinked',
    });
  });

  it('ticks the helper’s routine a step at a time, or all at once, as the helper', async () => {
    const h = await samsHousehold();
    const { thandi } = await given(h);
    const { secret } = await linkedFrame(h, {
      ...PANELS,
      calendar: false,
      todos: false,
      helperMemberId: thandi,
    });
    const routine = (await dayOf(secret)).helper?.items.find((item) => item['kind'] === 'routine');
    expect(routine).toMatchObject({
      id: 'bathroom',
      done: false,
      steps: [
        { id: 'basin', text: 'Basin', done: false },
        { id: 'floor', text: 'Floor', done: false },
      ],
    });

    const ref = household(h.householdId)
      .collection('homeCareRoutineTicks')
      .doc(`bathroom_${today()}`);
    expect(
      await tick(secret, {
        kind: 'routine',
        id: 'bathroom',
        date: today(),
        done: true,
        step: 'floor',
      }),
    ).toEqual({
      status: 'linked',
      done: false,
    });
    expect((await ref.get()).data()).toMatchObject({
      routineId: 'bathroom',
      occurrenceDate: today(),
      helperId: thandi,
      doneItemIds: ['floor'],
      updatedBy: thandi,
    });
    expect(
      await tick(secret, { kind: 'routine', id: 'bathroom', date: today(), done: true }),
    ).toEqual({
      status: 'linked',
      done: true,
    });
    expect((await ref.get()).get('doneItemIds')).toEqual(['basin', 'floor']);
    await expectRefusal(
      tick(secret, { kind: 'routine', id: 'bathroom', date: today(), done: true, step: 'mirror' }),
      'itemNotFound',
    );
  });
});

async function addEvent(secret: string, body: Record<string, unknown>): Promise<unknown> {
  return callAs(null, 'addFrameEvent', { secret, title: 'Dentist', who: [], by: 'Sam', ...body });
}

const EVENT_KEYS = [
  'createdAt',
  'createdBy',
  'date',
  'endMinute',
  'memberIds',
  'note',
  'recurrence',
  'startMinute',
  'title',
];

describe('a frame adds an event (photo-frames ADR-0008)', () => {
  const ADDING = { ...PANELS, todos: false, addEvents: true };

  /** Sam and Mia's tablet may add; Thandi, a helper who only sees the calendar, may not. */
  async function given(h: Household): Promise<{ mia: string; thandi: string }> {
    const mia = await addProfile(h.householdId, 'Mia Parker', 'kid');
    await household(h.householdId)
      .collection('members')
      .doc(mia)
      .update({ access: { ...ROLE_DEFAULTS.kid, calendar: 'edit' } });
    await pairKidDevice(h.sam, h.householdId, mia);
    const thandi = await addProfile(h.householdId, 'Thandi', 'helper');
    await joinAs(h.sam, h.householdId, thandi);
    await addProfile(h.householdId, 'Leo', 'kid');
    return { mia, thandi };
  }

  async function events(h: Household): Promise<Record<string, unknown>[]> {
    const docs = await household(h.householdId).collection('events').get();
    return docs.docs.map((doc) => doc.data());
  }

  it('says who may add while it may, and writes the app’s own document for them', async () => {
    const h = await samsHousehold();
    const { mia, thandi } = await given(h);
    const { secret } = await linkedFrame(h, ADDING);
    const tomorrow = addDays(today(), 1);

    const day = await dayOf(secret);
    expect(day.addEvents).toEqual({ by: ['Mia', 'Sam'] });
    expect(day.calendar?.days).toHaveLength(3);

    expect(
      await addEvent(secret, {
        title: '  Dentist ',
        date: tomorrow,
        start: '09:00',
        end: '10:30',
        who: ['mia', 'Thandi'],
        by: ' sam ',
        note: ' Bring the card ',
      }),
    ).toEqual({ status: 'linked', added: true });
    const [timed] = await events(h);
    expect(Object.keys(timed ?? {}).sort()).toEqual(EVENT_KEYS);
    expect(timed).toMatchObject({
      title: 'Dentist',
      note: 'Bring the card',
      date: tomorrow,
      startMinute: 540,
      endMinute: 630,
      recurrence: null,
      memberIds: [mia, thandi],
      createdBy: h.samMemberId,
    });
    expect(timed?.['createdAt']).toBeInstanceOf(Timestamp);
    expect((await dayOf(secret)).calendar?.days[1]?.events).toEqual([
      {
        title: 'Dentist',
        allDay: false,
        start: '09:00',
        end: '10:30',
        who: ['Mia', 'Thandi'],
        note: 'Bring the card',
        repeats: false,
      },
    ]);
  });

  it('all day for everyone, weekly on the day’s weekday, credited to a kid’s tablet', async () => {
    const h = await samsHousehold();
    const { mia } = await given(h);
    const { secret } = await linkedFrame(h, ADDING);
    const farthest = addDays(today(), 365);

    await addEvent(secret, { title: 'Holiday', date: farthest, end: null, by: 'Mia' });
    await addEvent(secret, { title: 'Swimming', date: today(), start: '16:00', repeat: 'weekly' });
    const written = await events(h);
    expect(written.find((event) => event['title'] === 'Holiday')).toMatchObject({
      note: null,
      date: farthest,
      startMinute: null,
      endMinute: null,
      recurrence: null,
      memberIds: [],
      createdBy: mia,
    });
    const swimming = written.find((event) => event['title'] === 'Swimming');
    expect(Object.keys(swimming ?? {}).sort()).toEqual(EVENT_KEYS);
    expect(swimming).toMatchObject({
      startMinute: 960,
      endMinute: null,
      recurrence: weeklyOn([weekdayOf(today())]),
      createdBy: h.samMemberId,
    });
    expect((await dayOf(secret)).calendar?.days[0]?.events).toEqual([
      {
        title: 'Swimming',
        allDay: false,
        start: '16:00',
        end: null,
        who: [],
        note: null,
        repeats: true,
      },
    ]);
  });

  it('refuses while adding is off, and the day does not offer it', async () => {
    const h = await samsHousehold();
    await given(h);
    const older = await linkedFrame(h);
    const noCalendar = await linkedFrame(h, { ...ADDING, calendar: false, todos: true });
    expect((await dayOf(older.secret)).addEvents).toBeUndefined();
    expect((await dayOf(noCalendar.secret)).addEvents).toBeUndefined();
    await expectRefusal(addEvent(older.secret, { date: today() }), 'addingOff');
    await expectRefusal(addEvent(noCalendar.secret, { date: today() }), 'addingOff');
    expect(await events(h)).toEqual([]);
  });

  it('refuses a day out of reach, somebody who may not add, and a name it cannot tell', async () => {
    const h = await samsHousehold();
    await given(h);
    const { secret } = await linkedFrame(h, ADDING);
    await expectRefusal(addEvent(secret, { date: addDays(today(), -1) }), 'eventOutOfReach');
    await expectRefusal(addEvent(secret, { date: addDays(today(), 367) }), 'eventOutOfReach');
    for (const by of ['Thandi', 'Leo', 'Nobody']) {
      await expectRefusal(addEvent(secret, { date: today(), by }), 'notAllowedToAdd');
    }
    await expectRefusal(addEvent(secret, { date: today(), who: ['Nobody'] }), 'badRequest');
    await expectRefusal(addEvent(secret, { date: today(), end: '10:00' }), 'badRequest');

    const samJones = await addProfile(h.householdId, 'Sam Jones', 'parent');
    await joinAs(h.sam, h.householdId, samJones);
    await addProfile(h.householdId, 'Leo Jones', 'kid');
    expect((await dayOf(secret)).addEvents).toEqual({ by: ['Mia', 'Sam', 'Sam'] });
    await expectRefusal(addEvent(secret, { date: today() }), 'whoNeeded');
    await expectRefusal(addEvent(secret, { date: today(), by: 'Mia', who: ['Leo'] }), 'whoNeeded');
    expect(await events(h)).toEqual([]);
  });

  it('writes one event however often a frame retries the same request', async () => {
    const h = await samsHousehold();
    await given(h);
    const { secret, frameId } = await linkedFrame(h, ADDING);
    const body = { date: today(), start: '09:00', requestId: 'sheet-0001_retry' };

    expect(await addEvent(secret, body)).toEqual({ status: 'linked', added: true });
    expect(await addEvent(secret, { ...body, title: 'Changed' })).toEqual({
      status: 'linked',
      added: true,
    });
    const docs = await household(h.householdId).collection('events').get();
    expect(docs.docs.map((doc) => doc.id)).toEqual([`frame-${frameId}-sheet-0001_retry`]);
    expect(docs.docs[0]?.get('title')).toBe('Dentist');

    await addEvent(secret, { ...body, requestId: 'sheet-0002_other' });
    await addEvent(secret, { date: today() });
    await addEvent(secret, { date: today() });
    expect(await events(h)).toHaveLength(4);
    await expectRefusal(addEvent(secret, { ...body, requestId: 'short' }), 'badRequest');
    await expectRefusal(addEvent(secret, { ...body, requestId: 'a/b/c/d/e/f' }), 'badRequest');
    expect(await events(h)).toHaveLength(4);
  });

  it('says unlinked to a stranger, and stops a frame past sixty an hour', async () => {
    const h = await samsHousehold();
    await given(h);
    expect(await addEvent(newSecret(), { date: today() })).toEqual({ status: 'unlinked' });

    const { secret } = await linkedFrame(h, ADDING);
    await adminDb()
      .collection(RATE_LIMITS)
      .doc(rateLimitId(FRAME_ADD_EVENT_PER_CREDENTIAL, secretHash(secret)))
      .set({ windowStart: Timestamp.now(), count: FRAME_ADD_EVENT_PER_CREDENTIAL.limit });
    await expectRefusal(addEvent(secret, { date: today() }), 'tooManyAttempts');
    expect(await events(h)).toEqual([]);
  });
});

describe('a frame reads a month of its calendar', () => {
  it('whole weeks around the month, with the day’s own events', async () => {
    const h = await samsHousehold();
    const thandi = await addProfile(h.householdId, 'Thandi Mokoena', 'helper');
    await givenToday(h, thandi);
    const { secret } = await linkedFrame(h);
    const date = today();

    const month = await monthOf(secret, date.slice(0, 7));
    expect(month).toMatchObject({ status: 'linked', today: date, month: date.slice(0, 7) });
    const days = month.days ?? [];
    expect(days.length % 7).toBe(0);
    expect(weekdayOf(days[0]?.date ?? '')).toBe(1);
    const swim = days.find((day) => day.date === date)?.events.find((e) => e.title === 'Swimming');
    expect(swim?.who).toEqual(['Sam']);
    expect(JSON.stringify(month)).not.toContain(h.samMemberId);
  });

  it('no days without the calendar panel, a far month refused, unlinked when deleted', async () => {
    const h = await samsHousehold();
    const off = await linkedFrame(h, { ...PANELS, calendar: false });
    const month = today().slice(0, 7);
    expect((await monthOf(off.secret, month)).days).toEqual([]);

    const { secret, frameId } = await linkedFrame(h);
    const far = `${String(Number(month.slice(0, 4)) + 2)}${month.slice(4)}`;
    await expectRefusal(monthOf(secret, far), 'monthOutOfRange');
    await expectRefusal(monthOf(secret, '2026-13'), 'badRequest');

    await household(h.householdId).collection('frames').doc(frameId).delete();
    expect(await monthOf(secret, month)).toEqual({ status: 'unlinked' });
    expect(await exists(`frameCredentials/${secretHash(secret)}`)).toBe(false);
    expect(await monthOf(newSecret(), month)).toEqual({ status: 'unlinked' });
  });
});

describe('a frame unlinks itself with its own secret', () => {
  it('removes its credential and its record, and the next read is unlinked', async () => {
    const h = await samsHousehold();
    const { secret, frameId } = await linkedFrame(h);
    expect(await unlink(secret)).toEqual({ status: 'unlinked' });
    expect(await exists(`frameCredentials/${secretHash(secret)}`)).toBe(false);
    expect(await exists(`households/${h.householdId}/frames/${frameId}`)).toBe(false);
    expect(await dayOf(secret)).toEqual({ status: 'unlinked' });
    expect(await unlink(secret)).toEqual({ status: 'unlinked' });
  });

  it('says the same for a secret nobody linked, and touches no other frame', async () => {
    const h = await samsHousehold();
    const other = await linkedFrame(h);
    expect(await unlink(newSecret())).toEqual({ status: 'unlinked' });
    expect(await exists(`households/${h.householdId}/frames/${other.frameId}`)).toBe(true);
    expect((await dayOf(other.secret)).status).toBe('linked');
  });

  it('refuses a body that is not a frame’s', async () => {
    await expectRefusal(callAs(null, 'unlinkFrame', { secret: 'short' }), 'badRequest');
  });
});

describe('a poll never says why a code will not do', () => {
  it('a wrong secret and an unknown code both read expired', async () => {
    const secret = newSecret();
    const { code } = await start(secret);
    expect(await poll(code, newSecret())).toEqual({ status: 'expired' });
    expect(await poll('ZZZZZZ', secret)).toEqual({ status: 'expired' });
    expect(await poll(code, secret)).toEqual({ status: 'waiting' });
  });

  it('a code past its ten minutes reads expired, and cannot be claimed', async () => {
    const h = await samsHousehold();
    const secret = newSecret();
    const { code } = await start(secret);
    await adminDb()
      .doc(`framePairings/${code}`)
      .update({ expiresAt: Timestamp.fromMillis(Date.now() - 1000) });
    expect(await poll(code, secret)).toEqual({ status: 'expired' });
    await expectRefusal(claim(h, code), 'frameCodeExpired');
  });

  it('refuses a body that is not a frame’s', async () => {
    await expectRefusal(callAs(null, 'startFramePairing', { secret: 'short' }), 'badRequest');
  });
});

describe('claimFramePairing refuses', () => {
  it('a code nobody is showing, and one already claimed', async () => {
    const h = await samsHousehold();
    await expectRefusal(claim(h, 'ZZZZZZ'), 'frameCodeNotFound');
    await expectRefusal(claim(h, 'not-a-code'), 'frameCodeNotFound');
    const { code } = await start(newSecret());
    await claim(h, code);
    await expectRefusal(claim(h, code), 'frameCodeExpired');
  });

  it('a helper who is not in the household', async () => {
    const h = await samsHousehold();
    const secret = newSecret();
    const { code } = await start(secret);
    await expectRefusal(
      claim(h, code, { ...PANELS, helperMemberId: 'm-nobody' }),
      'helperNotFound',
    );
    expect(await poll(code, secret)).toEqual({ status: 'waiting' });
  });

  it('a sixth frame', async () => {
    const h = await samsHousehold();
    for (let index = 0; index < 5; index += 1) await linkedFrame(h);
    const { code } = await start(newSecret());
    await expectRefusal(claim(h, code), 'tooManyFrames');
  });

  it('anybody who is not family, a stranger, a kid device and nobody at all', async () => {
    const h = await samsHousehold();
    const { code } = await start(newSecret());
    const thandi = await joinAs(
      h.sam,
      h.householdId,
      await addProfile(h.householdId, 'Thandi', 'helper'),
    );
    const tablet = await pairKidDevice(
      h.sam,
      h.householdId,
      await addProfile(h.householdId, 'Mia', 'kid'),
    );
    const body = { householdId: h.householdId, code, name: 'Mine', panels: PANELS };
    await expectRefusal(callAs(thandi, 'claimFramePairing', body), 'notFamily');
    await expectRefusal(callAs(await signUp(), 'claimFramePairing', body), 'notAMember');
    await expectRefusal(callAs(tablet, 'claimFramePairing', body), 'kidAccount');
    await expectRefusal(callAs(null, 'claimFramePairing', body), 'notSignedIn');
    expect((await adminDb().doc(`framePairings/${code}`).get()).get('status')).toBe('waiting');
  });

  it('while photo frames are switched off', async () => {
    const h = await samsHousehold();
    const { code } = await start(newSecret());
    await adminDb().doc('appConfig/flags').set({ photoFrames: false });
    await expectRefusal(claim(h, code), 'framesOff');
  });
});

interface Photos {
  status: string;
  photos?: { id: string; bytes: number }[];
}

const SCREENSAVER = { idleMinutes: 5, secondsPerPhoto: 20 };
const BEACH = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46]);

async function photosOf(secret: string): Promise<Photos> {
  return callAs<Photos>(null, 'getFramePhotos', { secret });
}

function photoOf(body: unknown, method = 'POST'): Promise<Response> {
  return fetch(httpFunctionUrl('getFramePhoto'), {
    method,
    headers: { 'Content-Type': 'application/json' },
    ...(method === 'POST' ? { body: JSON.stringify(body) } : {}),
  });
}

async function setScreensaver(
  h: Household,
  frameId: string,
  screensaver: Record<string, unknown> = SCREENSAVER,
): Promise<void> {
  await household(h.householdId).collection('frames').doc(frameId).update({ screensaver });
}

/** Both names the default bucket can have, as `document_share_fixture.ts` explains. */
async function putPhoto(
  householdId: string,
  id: string,
  bytes: Buffer = BEACH,
  contentType = 'image/jpeg',
): Promise<void> {
  for (const bucket of ['nestprep-643b7.appspot.com', 'nestprep-643b7.firebasestorage.app']) {
    await adminStorage()
      .bucket(bucket)
      .file(`households/${householdId}/framePhotos/${id}`)
      .save(bytes, { contentType, resumable: false });
  }
}

describe('a frame’s screensaver', () => {
  it('is on the day only while it is on', async () => {
    const h = await samsHousehold();
    const { secret, frameId } = await linkedFrame(h);
    expect(await dayOf(secret)).not.toHaveProperty('screensaver');
    await setScreensaver(h, frameId);
    expect(await dayOf(secret)).toMatchObject({ screensaver: SCREENSAVER });
    await setScreensaver(h, frameId, { idleMinutes: 0, secondsPerPhoto: 20 });
    expect(await dayOf(secret)).not.toHaveProperty('screensaver');
    await setScreensaver(h, frameId, { idleMinutes: 7, secondsPerPhoto: 20 });
    const day = await dayOf(secret);
    expect(day.status).toBe('linked');
    expect(day).not.toHaveProperty('screensaver');
  });

  it('lists the album newest first, only what the app could have put there', async () => {
    const h = await samsHousehold();
    const { secret, frameId } = await linkedFrame(h);
    await putPhoto(h.householdId, 'beach-0001');
    await putPhoto(h.householdId, 'party-0002', Buffer.alloc(32, 1));
    await putPhoto(h.householdId, 'a-png-0003', BEACH, 'image/png');
    await putPhoto(h.householdId, 'short', BEACH);

    expect(await photosOf(secret)).toEqual({ status: 'linked', photos: [] });
    await setScreensaver(h, frameId);
    expect(await photosOf(secret)).toEqual({
      status: 'linked',
      photos: [
        { id: 'party-0002', bytes: 32 },
        { id: 'beach-0001', bytes: BEACH.length },
      ],
    });

    await household(h.householdId).collection('frames').doc(frameId).delete();
    expect(await photosOf(secret)).toEqual({ status: 'unlinked' });
    expect(await photosOf(newSecret())).toEqual({ status: 'unlinked' });
    await expectRefusal(callAs(null, 'getFramePhotos', { secret: 'short' }), 'badRequest');
  });

  it('streams one photo’s bytes to its own frame, and says why it will not', async () => {
    const h = await samsHousehold();
    const other = await samsHousehold();
    const { secret, frameId } = await linkedFrame(h);
    await putPhoto(h.householdId, 'beach-0001');
    await putPhoto(other.householdId, 'theirs-0001');

    const off = await photoOf({ secret, id: 'beach-0001' });
    expect(off.status).toBe(404);
    expect(await off.json()).toEqual({ status: 'missing' });

    await setScreensaver(h, frameId);
    const found = await photoOf({ secret, id: 'beach-0001' });
    expect(found.status).toBe(200);
    expect(found.headers.get('content-type')).toBe('image/jpeg');
    expect(found.headers.get('content-length')).toBe(String(BEACH.length));
    expect(found.headers.get('cache-control')).toBe('no-store');
    expect(found.headers.get('x-content-type-options')).toBe('nosniff');
    expect(Buffer.from(await found.arrayBuffer())).toEqual(BEACH);

    for (const id of ['nobody-0001', 'theirs-0001']) {
      const missing = await photoOf({ secret, id });
      expect(missing.status, id).toBe(404);
      expect(await missing.json()).toEqual({ status: 'missing' });
    }

    const bad = await photoOf({ secret, id: '../theirs' });
    expect(bad.status).toBe(400);
    expect(await bad.json()).toEqual({ status: 'invalid' });
    expect((await photoOf({ data: { secret, id: 'beach-0001' } })).status).toBe(400);
    expect((await photoOf(null, 'GET')).status).toBe(405);

    const stranger = await photoOf({ secret: newSecret(), id: 'beach-0001' });
    expect(stranger.status).toBe(410);
    expect(await stranger.json()).toEqual({ status: 'unlinked' });
    await household(h.householdId).collection('frames').doc(frameId).delete();
    expect((await photoOf({ secret, id: 'beach-0001' })).status).toBe(410);

    const busy = await linkedFrame(h);
    await adminDb()
      .collection(RATE_LIMITS)
      .doc(rateLimitId(FRAME_PHOTO_PER_CREDENTIAL, secretHash(busy.secret)))
      .set({
        windowStart: Timestamp.now(),
        count: FRAME_PHOTO_PER_CREDENTIAL.limit,
      });
    const throttled = await photoOf({ secret: busy.secret, id: 'beach-0001' });
    expect(throttled.status).toBe(429);
    expect(await throttled.json()).toEqual({ status: 'tooManyAttempts' });
  });
});

function lunchPhotoOf(body: unknown): Promise<Response> {
  return fetch(httpFunctionUrl('getFrameLunchPhoto'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
}

describe('a frame’s lunch-box pictures (photo-frames ADR-0009)', () => {
  const MAIN = { itemId: 'i1', name: 'Cheese sandwich', allergens: ['milk'] };
  const FRUIT = { itemId: 'i2', name: 'Apple', allergens: [] };

  /** Mia's box today, and the picture the app made of it, as `lunchPhoto` leaves them. */
  async function givenAPicturedBox(h: Household): Promise<string> {
    const mia = await addProfile(h.householdId, 'Mia Parker', 'kid');
    const date = today();
    const weekday = weekdayOf(date);
    const week = weekKeyOf(new Date(`${date}T12:00:00Z`), 'UTC');
    await household(h.householdId)
      .collection('lunchPlans')
      .doc(`${mia}_${week}`)
      .set({
        childId: mia,
        week,
        weekStart: addDays(date, 1 - weekday),
        slots: { [`${String(weekday)}_main`]: MAIN, [`${String(weekday)}_fruit`]: FRUIT },
        feedback: {},
      });
    const key = combinationOf({ main: MAIN, fruit: FRUIT })?.key ?? '';
    const path = `households/${h.householdId}/lunchPhotos/${key}.jpg`;
    await household(h.householdId)
      .collection('lunchPhotos')
      .doc(key)
      .set({ status: 'ready', path, promptVersion: 'v1' });
    for (const bucket of ['nestprep-643b7.appspot.com', 'nestprep-643b7.firebasestorage.app']) {
      await adminStorage()
        .bucket(bucket)
        .file(path)
        .save(BEACH, { contentType: 'image/jpeg', resumable: false });
    }
    return key;
  }

  async function setPremium(h: Household, premium: boolean): Promise<void> {
    const until = Date.now() + (premium ? 86_400_000 : -86_400_000);
    await household(h.householdId)
      .collection('entitlement')
      .doc('current')
      .set({ premiumUntil: new Date(until) });
  }

  it('names a premium box’s ready picture and streams it, and nothing else', async () => {
    const h = await samsHousehold();
    const key = await givenAPicturedBox(h);
    const { secret, frameId } = await linkedFrame(h, { ...PANELS, calendar: false, lunch: true });
    const schoolDay = weekdayOf(today()) <= 5;

    await setPremium(h, false);
    expect((await dayOf(secret)).lunch?.boxes[0]).not.toHaveProperty('photo');
    expect((await lunchPhotoOf({ secret, id: key })).status).toBe(404);

    await setPremium(h, true);
    const day = await dayOf(secret);
    expect(day.lunch?.boxes[0]?.photo).toBe(schoolDay ? key : undefined);
    const found = await lunchPhotoOf({ secret, id: key });
    expect(found.status).toBe(schoolDay ? 200 : 404);
    if (schoolDay) {
      expect(found.headers.get('content-type')).toBe('image/jpeg');
      expect(found.headers.get('cache-control')).toBe('no-store');
      expect(Buffer.from(await found.arrayBuffer())).toEqual(BEACH);
    }

    const stranger = await lunchPhotoOf({ secret, id: 'f'.repeat(40) });
    expect(stranger.status).toBe(404);
    expect(await stranger.json()).toEqual({ status: 'missing' });

    const other = await samsHousehold();
    const elsewhere = await linkedFrame(other, { ...PANELS, lunch: true });
    await setPremium(other, true);
    expect((await lunchPhotoOf({ secret: elsewhere.secret, id: key })).status).toBe(404);

    await household(h.householdId)
      .collection('frames')
      .doc(frameId)
      .update({ 'panels.lunch': false });
    expect((await lunchPhotoOf({ secret, id: key })).status).toBe(404);
    expect((await lunchPhotoOf({ secret: newSecret(), id: key })).status).toBe(410);
    expect((await lunchPhotoOf({ secret, id: '../x' })).status).toBe(400);
  });

  it('a box nobody has pictured yet has no picture, and the frame does not make one', async () => {
    const h = await samsHousehold();
    const key = await givenAPicturedBox(h);
    await household(h.householdId).collection('lunchPhotos').doc(key).delete();
    await setPremium(h, true);
    const { secret } = await linkedFrame(h, { ...PANELS, calendar: false, lunch: true });
    expect((await dayOf(secret)).lunch?.boxes[0]).not.toHaveProperty('photo');
    expect((await household(h.householdId).collection('lunchPhotos').get()).empty).toBe(true);
  });
});

interface Shared {
  status: string;
  share?: { id: string; url: string; title: string | null; by: string } | null;
}

const RECIPE = 'https://www.bbcgoodfood.com/recipes/chicken-curry?serves=4#method';

async function shareTo(
  h: Household,
  frameId: string,
  more: Record<string, unknown> = {},
): Promise<{ shared: boolean }> {
  return callAs(h.sam, 'shareToFrame', {
    householdId: h.householdId,
    frameId,
    url: RECIPE,
    title: ' Chicken curry ',
    ...more,
  });
}

async function waitShare(secret: string, after?: string): Promise<Shared> {
  return callAs<Shared>(
    null,
    'waitFrameShare',
    after === undefined ? { secret } : { secret, after },
  );
}

const frameOf = (h: Household, frameId: string): DocumentReference =>
  household(h.householdId).collection('frames').doc(frameId);

describe('a page shared from a phone opens on the frame', () => {
  it('shareToFrame stores it and waitFrameShare answers with it at once', async () => {
    const h = await samsHousehold();
    await household(h.householdId)
      .collection('members')
      .doc(h.samMemberId)
      .update({ displayName: 'Sam Parker' });
    const { secret, frameId } = await linkedFrame(h, { ...PANELS, share: true });

    expect(await shareTo(h, frameId)).toEqual({ shared: true });
    const stored = (await frameOf(h, frameId).get()).get('share') as Record<string, unknown>;
    expect(stored).toMatchObject({ url: RECIPE, title: 'Chicken curry', by: 'Sam' });
    expect(stored['id']).toMatch(/^[A-Za-z0-9]{20}$/);
    expect(stored['at']).toBeInstanceOf(Timestamp);

    expect(await waitShare(secret)).toEqual({
      status: 'linked',
      share: { id: stored['id'], url: RECIPE, title: 'Chicken curry', by: 'Sam' },
    });
  });

  it('waits on the one it opened and answers the next share the moment it lands', async () => {
    const h = await samsHousehold();
    const { secret, frameId } = await linkedFrame(h, { ...PANELS, share: true });
    await shareTo(h, frameId, { title: null });
    const first = (await waitShare(secret)).share;
    expect(first).toMatchObject({ url: RECIPE, title: null });
    const after = first?.id ?? '';

    const waiting = waitShare(secret, after);
    await new Promise((resolve) => setTimeout(resolve, 1500));
    await shareTo(h, frameId, { url: 'https://example.com/next', title: 'Next' });
    const next = await waiting;
    expect(next.status).toBe('linked');
    expect(next.share).toMatchObject({ url: 'https://example.com/next', title: 'Next', by: 'Sam' });
    expect(next.share?.id).not.toBe(after);
  });

  it('answers none at the deadline while the share is the one it opened, or stale', async () => {
    const h = await samsHousehold();
    const { frameId } = await linkedFrame(h, { ...PANELS, share: true });
    await shareTo(h, frameId);
    const ref = frameOf(h, frameId);
    const opened = ((await ref.get()).get('share') as { id: string }).id;

    const started = Date.now();
    expect(await awaitFrameShare(ref, opened, 1500)).toBeNull();
    expect(Date.now() - started).toBeGreaterThanOrEqual(1400);

    await ref.update({ 'share.at': Timestamp.fromMillis(Date.now() - 11 * 60 * 1000) });
    expect(await awaitFrameShare(ref, null, 1500)).toBeNull();
    expect(await awaitFrameShare(ref, null, 1500)).toBeNull();
  });

  it('answers none when sharing is switched off or the frame is deleted meanwhile', async () => {
    const h = await samsHousehold();
    const { frameId } = await linkedFrame(h, { ...PANELS, share: true });
    const ref = frameOf(h, frameId);

    const switchedOff = awaitFrameShare(ref, null, 20_000);
    await new Promise((resolve) => setTimeout(resolve, 500));
    await ref.update({ 'panels.share': false });
    expect(await switchedOff).toBeNull();

    await ref.update({ 'panels.share': true });
    const deleted = awaitFrameShare(ref, null, 20_000);
    await new Promise((resolve) => setTimeout(resolve, 500));
    await ref.delete();
    expect(await deleted).toBeNull();
  });

  it('refuses while sharing is off, and says unlinked to a stranger', async () => {
    const h = await samsHousehold();
    const { secret, frameId } = await linkedFrame(h);
    await expectRefusal(shareTo(h, frameId), 'sharingOff');
    await expectRefusal(waitShare(secret), 'sharingOff');
    expect(await waitShare(newSecret())).toEqual({ status: 'unlinked' });
    await expectRefusal(waitShare(secret, 'short'), 'badRequest');
  });

  it('refuses a frame that is not there and a link that is not a public page', async () => {
    const h = await samsHousehold();
    const { frameId } = await linkedFrame(h, { ...PANELS, share: true });
    await expectRefusal(shareTo(h, 'no-such-frame'), 'frameNotFound');
    for (const url of [
      'http://192.168.1.1/',
      'http://router.lan/',
      'http://nas.local/',
      'https://example.com:8443/',
      'file:///sdcard/x.html',
      'not a link',
    ]) {
      await expectRefusal(shareTo(h, frameId, { url }), 'badLink');
    }
    await expectRefusal(
      shareTo(h, frameId, { url: `https://e.com/${'a'.repeat(2040)}` }),
      'badRequest',
    );
    expect((await frameOf(h, frameId).get()).get('share')).toBeUndefined();
  });

  it('refuses anybody who is not family, a stranger, a kid device and nobody at all', async () => {
    const h = await samsHousehold();
    const { frameId } = await linkedFrame(h, { ...PANELS, share: true });
    const thandi = await joinAs(
      h.sam,
      h.householdId,
      await addProfile(h.householdId, 'Thandi', 'helper'),
    );
    const tablet = await pairKidDevice(
      h.sam,
      h.householdId,
      await addProfile(h.householdId, 'Mia', 'kid'),
    );
    const body = { householdId: h.householdId, frameId, url: RECIPE };
    await expectRefusal(callAs(thandi, 'shareToFrame', body), 'notFamily');
    await expectRefusal(callAs(await signUp(), 'shareToFrame', body), 'notAMember');
    await expectRefusal(callAs(tablet, 'shareToFrame', body), 'kidAccount');
    await expectRefusal(callAs(null, 'shareToFrame', body), 'notSignedIn');
    expect((await frameOf(h, frameId).get()).get('share')).toBeUndefined();
  });

  it('refuses while photo frames are switched off', async () => {
    const h = await samsHousehold();
    const { frameId } = await linkedFrame(h, { ...PANELS, share: true });
    await adminDb().doc('appConfig/flags').set({ photoFrames: false });
    await expectRefusal(shareTo(h, frameId), 'framesOff');
  });

  it('the day tells the frame to wait for shares only while sharing is on', async () => {
    const h = await samsHousehold();
    const { secret, frameId } = await linkedFrame(h, { ...PANELS, share: true });
    expect(await dayOf(secret)).toMatchObject({ status: 'linked', sharing: true });
    await frameOf(h, frameId).update({ 'panels.share': false });
    expect(await dayOf(secret)).not.toHaveProperty('sharing');
    const older = await linkedFrame(h);
    expect(await dayOf(older.secret)).not.toHaveProperty('sharing');
  });
});

describe('a recipe shared from the app cooks along on the frame (photo-frames ADR-0013)', () => {
  const HERO = 'recipes/bobotie/hero-0123abcd.jpg';
  const BOBOTIE = {
    status: 'published',
    name: 'Bobotie',
    summary: 'Spiced mince under a golden custard.',
    servings: 6,
    prepMinutes: 20,
    cookMinutes: 40,
    difficulty: 'easy',
    prepNote: null,
    ingredients: [
      { name: 'Beef mince', quantity: 1, unit: 'kg', note: null, group: null },
      { name: 'Salt', quantity: null, unit: null, note: 'to taste', group: null },
    ],
    steps: ['Brown the mince.', 'Bake for 35–40 minutes, until set.'],
    photo: { card: 'recipes/bobotie/card-0123abcd.jpg', hero: HERO },
  };
  const ACCEPTS = ['page', 'recipe'];

  async function givenBobotie(more: Record<string, unknown> = {}): Promise<void> {
    await adminDb()
      .collection('recipes')
      .doc('bobotie')
      .set({ ...BOBOTIE, ...more });
  }

  function shareRecipe(
    h: Household,
    frameId: string,
    recipe: Record<string, unknown> = { id: 'bobotie', people: 4, amounts: ['665 g', null] },
  ): Promise<{ shared: boolean }> {
    return callAs(h.sam, 'shareToFrame', { householdId: h.householdId, frameId, recipe });
  }

  function recipePhotoOf(body: unknown): Promise<Response> {
    return fetch(httpFunctionUrl('getFrameRecipePhoto'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
  }

  it('reaches a frame that asked for recipes, timers and all, with its photo', async () => {
    const h = await samsHousehold();
    await givenBobotie();
    const { secret, frameId } = await linkedFrame(h, { ...PANELS, share: true });
    await shareTo(h, frameId);
    const page = await callAs<Shared>(null, 'waitFrameShare', { secret, accepts: ACCEPTS });
    expect(page.share).toMatchObject({ kind: 'page' });
    expect((await frameOf(h, frameId).get()).get('accepts')).toEqual(ACCEPTS);

    expect(await shareRecipe(h, frameId)).toEqual({ shared: true });
    const answer = await callAs<{ status: string; share: Record<string, unknown> }>(
      null,
      'waitFrameShare',
      { secret, accepts: ACCEPTS, after: page.share?.id },
    );
    expect(answer.share).toMatchObject({
      kind: 'recipe',
      title: 'Bobotie',
      recipe: {
        recipeId: 'bobotie',
        people: 4,
        photo: true,
        ingredients: [
          { amount: '665 g', name: 'Beef mince' },
          { amount: null, name: 'Salt', note: 'to taste' },
        ],
        steps: [
          { text: 'Brown the mince.', timers: [] },
          { timers: [{ start: 9, end: 22, seconds: 2100, upToSeconds: 2400 }] },
        ],
      },
    });
    expect(answer.share).not.toHaveProperty('photoPath');
    expect(answer.share).not.toHaveProperty('url');

    for (const bucket of ['nestprep-643b7.appspot.com', 'nestprep-643b7.firebasestorage.app']) {
      await adminStorage()
        .bucket(bucket)
        .file(HERO)
        .save(BEACH, { contentType: 'image/jpeg', resumable: false });
    }
    const photo = await recipePhotoOf({ secret, id: answer.share.id });
    expect(photo.status).toBe(200);
    expect(photo.headers.get('content-type')).toBe('image/jpeg');
    expect((await recipePhotoOf({ secret, id: 'AbCdEfGhIj0123456789' })).status).toBe(404);
  });

  it('never reaches a frame on an older build, and is refused for it', async () => {
    const h = await samsHousehold();
    await givenBobotie();
    const { secret, frameId } = await linkedFrame(h, { ...PANELS, share: true });
    await expectRefusal(shareRecipe(h, frameId), 'frameCantOpen');
    await frameOf(h, frameId).update({ accepts: ACCEPTS });
    await shareRecipe(h, frameId);
    await frameOf(h, frameId).update({ accepts: ['page'] });
    expect(await callAs<Shared>(null, 'waitFrameShare', { secret })).toEqual({
      status: 'linked',
      share: null,
    });
    expect((await frameOf(h, frameId).get()).get('share.kind')).toBe('recipe');
  }, 70_000);

  it('refuses a recipe that is gone or amounts that do not line up', async () => {
    const h = await samsHousehold();
    const { frameId } = await linkedFrame(h, { ...PANELS, share: true });
    await frameOf(h, frameId).update({ accepts: ACCEPTS });
    await expectRefusal(shareRecipe(h, frameId), 'recipeNotFound');
    await givenBobotie({ status: 'draft' });
    await expectRefusal(shareRecipe(h, frameId), 'recipeNotFound');
    await givenBobotie();
    await expectRefusal(
      shareRecipe(h, frameId, { id: 'bobotie', people: 4, amounts: ['665 g'] }),
      'badRecipe',
    );
    await expectRefusal(
      shareRecipe(h, frameId, { id: 'bobotie', people: 4, amounts: ['665 g', '1 tsp'] }),
      'badRecipe',
    );
    await frameOf(h, frameId).update({ 'panels.share': false });
    await expectRefusal(shareRecipe(h, frameId), 'sharingOff');
    expect((await frameOf(h, frameId).get()).get('share')).toBeUndefined();
  });

  it('serves no photo for a page share', async () => {
    const h = await samsHousehold();
    const { secret, frameId } = await linkedFrame(h, { ...PANELS, share: true });
    await shareTo(h, frameId);
    const page = await waitShare(secret);
    expect((await recipePhotoOf({ secret, id: page.share?.id })).status).toBe(404);
  });
});

describe('a frame adds groceries (photo-frames ADR-0012)', () => {
  const GROCERY_KEYS = [
    'addedAt',
    'addedBy',
    'boughtAt',
    'boughtBy',
    'name',
    'quantity',
    'sourceKey',
    'sourceNote',
    'sourceWeek',
  ];

  interface Product {
    retailer: string;
    productId: string;
    articleCode: string;
    unitOfMeasure: string;
    name: string;
    brand: string | null;
    priceCents: number;
    imageId: string | null;
    imageUrl: string | null;
    bestMatch: boolean;
  }

  /** Sam, and Thandi, a helper who may edit the list; Leo's grant only views it. */
  async function given(h: Household): Promise<{ secret: string; frameId: string }> {
    const thandi = await addProfile(h.householdId, 'Thandi', 'helper');
    await joinAs(h.sam, h.householdId, thandi);
    await addProfile(h.householdId, 'Leo', 'kid');
    const linked = await linkedFrame(h, { ...PANELS, todos: false });
    await household(h.householdId)
      .collection('frames')
      .doc(linked.frameId)
      .update({ groceries: { shop: 'checkers', area: 'capeTown' } });
    return linked;
  }

  function pickOf(product: Product | undefined): Record<string, unknown> {
    if (product === undefined) throw new Error('no product');
    return {
      retailer: product.retailer,
      productId: product.productId,
      articleCode: product.articleCode,
      unitOfMeasure: product.unitOfMeasure,
      name: product.name,
      brand: product.brand,
      priceCents: product.priceCents,
      imageId: product.imageId,
    };
  }

  async function search(secret: string, query: string): Promise<{ products?: Product[] }> {
    return callAs(null, 'searchFrameProducts', { secret, query });
  }

  async function add(secret: string, body: Record<string, unknown>): Promise<unknown> {
    return callAs(null, 'addFrameGroceryItem', { secret, name: 'Milk', by: 'Sam', ...body });
  }

  async function items(h: Household): Promise<Record<string, unknown>[]> {
    const docs = await household(h.householdId).collection('groceryItems').get();
    return docs.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  it('is nowhere on a frame without the switch', async () => {
    const h = await samsHousehold();
    const { secret } = await linkedFrame(h);
    expect(await dayOf(secret)).not.toHaveProperty('groceries');
    await expectRefusal(search(secret, 'milk'), 'groceriesOff');
    await expectRefusal(add(secret, {}), 'groceriesOff');
  });

  it('searches the frame’s shop, then writes the app’s own item with the pick', async () => {
    const h = await samsHousehold();
    const { secret, frameId } = await given(h);
    expect((await dayOf(secret)).groceries).toEqual({
      shop: 'checkers',
      by: ['Sam', 'Thandi'],
      toBuy: [],
    });

    const { products = [] } = await search(secret, ' milk ');
    expect(products.map((product) => product.name)).toEqual(['Milk 500 g', 'Milk family pack']);
    expect(products[0]).toMatchObject({
      retailer: 'checkers',
      unitOfMeasure: 'EA',
      bestMatch: true,
    });
    const pick = pickOf(products[0]);

    expect(
      await add(secret, {
        name: ' Milk ',
        quantity: '2',
        by: 'thandi',
        product: pick,
        requestId: 'sheet-0001',
      }),
    ).toEqual({ status: 'linked', added: true });
    const [milk] = await items(h);
    expect(milk?.['id']).toBe(`frame-${frameId}-sheet-0001`);
    const { productMatch, ...written } = milk ?? {};
    delete written['id'];
    expect(Object.keys(written).sort()).toEqual(GROCERY_KEYS);
    expect(written).toMatchObject({ name: 'Milk', quantity: '2', boughtBy: null, sourceKey: null });
    expect(written['addedAt']).toBeInstanceOf(Timestamp);
    const thandi = (
      await household(h.householdId)
        .collection('members')
        .where('displayName', '==', 'Thandi')
        .get()
    ).docs[0]?.id;
    expect(written['addedBy']).toBe(thandi);
    expect(productMatch).toMatchObject({ ...pick, currency: 'ZAR', pickedBy: thandi });
    expect((productMatch as Record<string, unknown>)['pickedAt']).toBeInstanceOf(Timestamp);

    expect((await dayOf(secret)).groceries?.toBuy).toEqual([
      {
        id: `frame-${frameId}-sheet-0001`,
        name: 'Milk',
        quantity: '2',
        product: { name: 'Milk 500 g', brand: 'Emulator' },
      },
    ]);
  });

  it('answers a retry as added, and what is already to buy as on the list, picking for it', async () => {
    const h = await samsHousehold();
    const { secret } = await given(h);
    await household(h.householdId).collection('groceryItems').doc('bread').set({
      name: 'Brown bread',
      quantity: null,
      addedBy: h.samMemberId,
      addedAt: Timestamp.now(),
      boughtAt: null,
      boughtBy: null,
      sourceKey: null,
      sourceWeek: null,
      sourceNote: null,
    });
    expect(await add(secret, { requestId: 'sheet-0002' })).toEqual({
      status: 'linked',
      added: true,
    });
    expect(await add(secret, { requestId: 'sheet-0002' })).toEqual({
      status: 'linked',
      added: true,
    });
    expect(await add(secret, { name: 'milk ' })).toEqual({
      status: 'linked',
      added: false,
      alreadyOnList: true,
    });

    const { products = [] } = await search(secret, 'brown bread');
    const pick = pickOf(products[0]);
    expect(await add(secret, { name: 'brown  bread', product: pick })).toEqual({
      status: 'linked',
      added: false,
      alreadyOnList: true,
    });
    const written = await items(h);
    expect(written).toHaveLength(2);
    expect(written.find((item) => item['id'] === 'bread')?.['productMatch']).toMatchObject({
      productId: pick.productId,
      pickedBy: h.samMemberId,
    });
  });

  it('refuses who may not add, a shop that is down, and a pick of the wrong shape', async () => {
    const h = await samsHousehold();
    const { secret } = await given(h);
    await expectRefusal(add(secret, { by: 'Leo' }), 'notAllowedToAddGroceries');
    await expectRefusal(add(secret, { by: 'Nobody' }), 'notAllowedToAddGroceries');
    await expectRefusal(search(secret, 'down the road'), 'shopUnavailable');
    await expectRefusal(
      add(secret, {
        product: {
          retailer: 'checkers',
          productId: 'not-an-id',
          articleCode: '1EA',
          unitOfMeasure: 'EA',
          name: 'Milk',
          priceCents: 100,
        },
      }),
      'badRequest',
    );
    expect(await items(h)).toEqual([]);
  });
});
