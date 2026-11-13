import { randomBytes } from 'node:crypto';

import { Timestamp } from 'firebase-admin/firestore';
import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import { addDays, wallClockOf } from '../../src/calendar_sync/zoned_time';
import { secretHash } from '../../src/frames/frame_documents';
import { FRAME_SHIFT_PER_CREDENTIAL } from '../../src/frames/frame_policy';
import { RATE_LIMITS, rateLimitId } from '../../src/shared/rate_limit';
import {
  type Household,
  addProfile,
  expectRefusal,
  household,
  samsHousehold,
} from './account_data_fixture';
import {
  adminDb,
  adminStorage,
  callAs,
  clearFirestore,
  closeAdmin,
  httpFunctionUrl,
} from './emulator_harness';

/**
 * The helper's day on a frame, over HTTP the way a frame calls it
 * (photo-frames ADR-0020, `BE-14`): a job's photo and circles, handing a job
 * in from the wall without an after photo, and clocking the helper in and out.
 */

beforeEach(clearFirestore);
afterAll(closeAdmin);

interface Shift {
  on: boolean;
  since?: string;
  sinceDate?: string;
}

interface Day {
  status: string;
  helper?: { name: string; items: Record<string, unknown>[]; shift?: Shift };
}

const JPEG = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46]);
const OVEN = 'oven-door-0001';
const today = (): string => wallClockOf(new Date(), 'Africa/Johannesburg').date;
const newSecret = (): string => randomBytes(32).toString('base64url');

async function frameFor(h: Household, helperMemberId: string | null): Promise<string> {
  const secret = newSecret();
  const { code } = await callAs<{ code: string }>(null, 'startFramePairing', {
    secret,
    model: 'Frameo 10',
  });
  await callAs(h.sam, 'claimFramePairing', {
    householdId: h.householdId,
    code,
    name: 'Kitchen',
    panels: { calendar: false, todos: false, meals: false, helperMemberId },
  });
  return secret;
}

function jobData(helperId: string, more: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    title: 'Oven door',
    roomId: 'kitchen',
    helperId,
    dueDate: today(),
    note: 'The corner by the hinge',
    productIds: [],
    steps: [
      { id: 's1', text: 'Spray' },
      { id: 's2', text: 'Wipe' },
    ],
    doneStepIds: ['s1'],
    beforePhoto: { photoId: 'before', width: 1600, height: 1200 },
    marks: [{ points: [0.1, 0.2, 0.30049, 0.4] }],
    afterPhoto: null,
    status: 'inProgress',
    reviewNote: null,
    revision: 1,
    createdBy: 'm-sam',
    createdAt: new Date(),
    updatedAt: new Date(),
    ...more,
  };
}

async function putBefore(householdId: string, jobId: string): Promise<void> {
  for (const bucket of ['nestprep-643b7.appspot.com', 'nestprep-643b7.firebasestorage.app']) {
    await adminStorage()
      .bucket(bucket)
      .file(`households/${householdId}/homeCareJobs/${jobId}/before`)
      .save(JPEG, { contentType: 'image/jpeg', resumable: false });
  }
}

function photoOf(body: unknown): Promise<Response> {
  return fetch(httpFunctionUrl('getFrameJobPhoto'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
}

const dayOf = (secret: string): Promise<Day> => callAs<Day>(null, 'getFrameDay', { secret });

const tick = (secret: string, more: Record<string, unknown>): Promise<Record<string, unknown>> =>
  callAs(null, 'tickFrameItem', { secret, kind: 'job', id: OVEN, date: today(), ...more });

const clock = (secret: string, on: boolean): Promise<{ status: string; shift?: Shift }> =>
  callAs(null, 'setFrameShift', { secret, on });

async function withThandi(): Promise<{ h: Household; thandi: string; secret: string }> {
  const h = await samsHousehold();
  const thandi = await addProfile(h.householdId, 'Thandi Mokoena', 'helper');
  const secret = await frameFor(h, thandi);
  return { h, thandi, secret };
}

describe('a job’s photo on the helper’s day', () => {
  it('names the photo and its circles on the job, and streams it to that frame only', async () => {
    const { h, thandi, secret } = await withThandi();
    const home = household(h.householdId);
    const lindiwe = await addProfile(h.householdId, 'Lindiwe', 'helper');
    await home.collection('homeCareJobs').doc(OVEN).set(jobData(thandi));
    await home.collection('homeCareJobs').doc('lindiwes-00001').set(jobData(lindiwe));
    await home
      .collection('homeCareJobs')
      .doc('long-ago-00001')
      .set(jobData(thandi, { dueDate: addDays(today(), -30) }));
    for (const id of [OVEN, 'lindiwes-00001', 'long-ago-00001']) await putBefore(h.householdId, id);

    const day = await dayOf(secret);
    expect(day.helper?.items).toEqual([
      {
        title: 'Oven door',
        done: false,
        kind: 'job',
        id: OVEN,
        date: today(),
        note: 'The corner by the hinge',
        steps: [
          { id: 's1', text: 'Spray', done: true },
          { id: 's2', text: 'Wipe', done: false },
        ],
        photo: OVEN,
        marks: [[0.1, 0.2, 0.3, 0.4]],
      },
    ]);

    const found = await photoOf({ secret, id: OVEN });
    expect(found.status).toBe(200);
    expect(found.headers.get('content-type')).toBe('image/jpeg');
    expect(found.headers.get('cache-control')).toBe('no-store');
    expect(Buffer.from(await found.arrayBuffer())).toEqual(JPEG);

    for (const id of ['lindiwes-00001', 'long-ago-00001', 'nobody-000001']) {
      const missing = await photoOf({ secret, id });
      expect(missing.status, id).toBe(404);
      expect(await missing.json()).toEqual({ status: 'missing' });
    }
    expect((await photoOf({ secret, id: '../other' })).status).toBe(400);
    expect((await photoOf({ secret: newSecret(), id: OVEN })).status).toBe(410);

    const noHelper = await frameFor(h, null);
    expect((await photoOf({ secret: noHelper, id: OVEN })).status).toBe(404);
    const other = await samsHousehold();
    const theirs = await frameFor(other, await addProfile(other.householdId, 'Thandi', 'helper'));
    expect((await photoOf({ secret: theirs, id: OVEN })).status).toBe(404);
  });

  it('says missing when the job has a photo field but no stored picture', async () => {
    const { h, thandi, secret } = await withThandi();
    await household(h.householdId).collection('homeCareJobs').doc(OVEN).set(jobData(thandi));
    expect((await photoOf({ secret, id: OVEN })).status).toBe(404);
  });
});

describe('a frame hands a job in (home-care ADR-0008)', () => {
  it('writes the app’s own hand-in and its history, once, with no after photo', async () => {
    const { h, thandi, secret } = await withThandi();
    const job = household(h.householdId).collection('homeCareJobs').doc(OVEN);
    await job.set(
      jobData(thandi, {
        status: 'sentBack',
        revision: 3,
        afterPhoto: { photoId: 'after-2', width: 1, height: 1 },
        reviewNote: 'Again please',
      }),
    );

    expect(await tick(secret, { done: true })).toEqual({ status: 'linked', done: true });
    const stored = (await job.get()).data();
    expect(stored).toMatchObject({
      status: 'submitted',
      revision: 4,
      doneStepIds: ['s1', 's2'],
      afterPhoto: null,
      reviewNote: 'Again please',
      title: 'Oven door',
    });
    expect(stored?.['updatedAt']).toBeInstanceOf(Timestamp);
    const event = (await job.collection('events').doc('4').get()).data();
    expect(event).toMatchObject({ status: 'submitted', by: thandi, note: null });
    expect(event?.['at']).toBeInstanceOf(Timestamp);
    expect(Object.keys(event ?? {}).sort()).toEqual(['at', 'by', 'note', 'status']);

    expect(await tick(secret, { done: true })).toEqual({ status: 'linked', done: true });
    expect((await job.get()).data()).toMatchObject({ revision: 4 });
    expect((await job.collection('events').get()).size).toBe(1);

    const [item] = (await dayOf(secret)).helper?.items ?? [];
    expect(item).toMatchObject({ id: OVEN, done: true, needsCheck: true });
  });

  it('refuses a way back, a single step, another helper’s job and a wrong date', async () => {
    const { h, thandi, secret } = await withThandi();
    const home = household(h.householdId);
    const lindiwe = await addProfile(h.householdId, 'Lindiwe', 'helper');
    await home.collection('homeCareJobs').doc(OVEN).set(jobData(thandi));
    await home.collection('homeCareJobs').doc('lindiwes-00001').set(jobData(lindiwe));

    expect(await tick(secret, { done: false })).toEqual({ status: 'linked', done: false });
    await expectRefusal(tick(secret, { done: true, step: 's2' }), 'itemNotFound');
    await expectRefusal(tick(secret, { done: true, id: 'lindiwes-00001' }), 'itemNotFound');
    await expectRefusal(tick(secret, { done: true, id: 'nobody-000001' }), 'itemNotFound');
    await expectRefusal(tick(secret, { done: true, date: addDays(today(), -1) }), 'itemNotFound');
    await expectRefusal(
      tick(secret, { done: true, date: addDays(today(), -30) }),
      'itemOutOfReach',
    );
    expect((await home.collection('homeCareJobs').doc(OVEN).get()).data()).toMatchObject({
      status: 'inProgress',
      revision: 1,
    });

    await tick(secret, { done: true });
    await expectRefusal(tick(secret, { done: false }), 'itemNotFound');
    await home.collection('homeCareJobs').doc(OVEN).update({ status: 'approved' });
    await expectRefusal(tick(secret, { done: false }), 'itemNotFound');

    const noHelper = await frameFor(h, null);
    await expectRefusal(tick(noHelper, { done: true }), 'itemNotFound');
    expect(await tick(newSecret(), { done: true })).toEqual({ status: 'unlinked' });
  });
});

describe('a helper clocks in and out at the wall (home-care ADR-0007)', () => {
  it('starts one shift however often it is asked, says since when, and ends it', async () => {
    const { h, thandi, secret } = await withThandi();
    const shifts = household(h.householdId).collection('homeCareShifts');
    expect((await dayOf(secret)).helper?.shift).toEqual({ on: false });

    const started = await clock(secret, true);
    expect(started.status).toBe('linked');
    expect(started.shift).toMatchObject({ on: true, sinceDate: today() });
    expect(started.shift?.since).toMatch(/^\d\d:\d\d$/);
    const [again] = await Promise.all([clock(secret, true), clock(secret, true)]);
    expect(again.shift?.on).toBe(true);

    const open = await shifts.get();
    expect(open.size).toBe(1);
    const shift = open.docs[0]?.data();
    expect(shift).toMatchObject({
      helperId: thandi,
      status: 'open',
      startedBy: thandi,
      startedVia: 'frame',
      endedAt: null,
      endedBy: null,
      endedVia: null,
    });
    expect(shift?.['startedAt']).toBeInstanceOf(Timestamp);
    expect(Object.keys(shift ?? {}).sort()).toEqual([
      'endedAt',
      'endedBy',
      'endedVia',
      'helperId',
      'startedAt',
      'startedBy',
      'startedVia',
      'status',
    ]);
    expect((await dayOf(secret)).helper?.shift).toEqual(started.shift);

    expect(await clock(secret, false)).toEqual({ status: 'linked', shift: { on: false } });
    expect(await clock(secret, false)).toEqual({ status: 'linked', shift: { on: false } });
    const ended = (await shifts.get()).docs[0]?.data();
    expect(ended).toMatchObject({ status: 'ended', endedBy: thandi, endedVia: 'frame' });
    expect(ended?.['endedAt']).toBeInstanceOf(Timestamp);
    expect((await dayOf(secret)).helper?.shift).toEqual({ on: false });

    await clock(secret, true);
    expect((await shifts.get()).size).toBe(2);
  });

  it('ends a shift she started on her phone, and leaves another helper’s alone', async () => {
    const { h, thandi, secret } = await withThandi();
    const shifts = household(h.householdId).collection('homeCareShifts');
    const lindiwe = await addProfile(h.householdId, 'Lindiwe', 'helper');
    const opened = (helperId: string): Record<string, unknown> => ({
      helperId,
      status: 'open',
      startedAt: Timestamp.fromDate(new Date('2026-09-29T05:32:00Z')),
      startedBy: helperId,
      startedVia: 'app',
      endedAt: null,
      endedBy: null,
      endedVia: null,
    });
    await shifts.doc('hers').set(opened(thandi));
    await shifts.doc('lindiwes').set(opened(lindiwe));

    expect((await dayOf(secret)).helper?.shift).toEqual({
      on: true,
      since: '07:32',
      sinceDate: '2026-09-29',
    });
    expect((await clock(secret, true)).shift).toEqual({
      on: true,
      since: '07:32',
      sinceDate: '2026-09-29',
    });
    expect((await shifts.get()).size).toBe(2);

    await shifts.doc('hers-too').set(opened(thandi));
    await clock(secret, false);
    expect((await shifts.doc('hers-too').get()).data()).toMatchObject({ status: 'ended' });
    expect((await shifts.doc('hers').get()).data()).toMatchObject({
      status: 'ended',
      startedVia: 'app',
      endedVia: 'frame',
    });
    expect((await shifts.doc('lindiwes').get()).data()).toMatchObject({ status: 'open' });
  });

  it('refuses with no helper on the frame, a helper who has gone, or switched off', async () => {
    const { h, thandi, secret } = await withThandi();
    const home = household(h.householdId);
    await expectRefusal(clock(await frameFor(h, null), true), 'helperNotFound');
    expect(await clock(newSecret(), true)).toEqual({ status: 'unlinked' });
    await expectRefusal(callAs(null, 'setFrameShift', { secret }), 'badRequest');

    await adminDb().doc('appConfig/flags').set({ homeCareShifts: false });
    await expectRefusal(clock(secret, true), 'shiftsOff');
    expect((await dayOf(secret)).helper).not.toHaveProperty('shift');
    await adminDb().doc('appConfig/flags').set({ homeCareShifts: true });

    await home.collection('members').doc(thandi).delete();
    await expectRefusal(clock(secret, true), 'helperNotFound');
    expect((await home.collection('homeCareShifts').get()).size).toBe(0);
  });

  it('is limited per frame', async () => {
    const { secret } = await withThandi();
    await adminDb()
      .collection(RATE_LIMITS)
      .doc(rateLimitId(FRAME_SHIFT_PER_CREDENTIAL, secretHash(secret)))
      .set({ windowStart: Timestamp.now(), count: FRAME_SHIFT_PER_CREDENTIAL.limit });
    await expectRefusal(clock(secret, true), 'tooManyAttempts');
  });
});
