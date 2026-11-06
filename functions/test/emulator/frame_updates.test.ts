import { randomBytes } from 'node:crypto';

import { type DocumentReference, Timestamp } from 'firebase-admin/firestore';
import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import { wallClockOf } from '../../src/calendar_sync/zoned_time';
import { secretHash } from '../../src/frames/frame_documents';
import {
  FRAME_APK_CONTENT_TYPE,
  FRAME_NEW_DEVICE_OVERALL,
  FRAME_NEW_DEVICE_PER_ADDRESS,
  FRAME_UPDATE_APK_PER_DEVICE,
  FRAME_UPDATE_CHECK_PER_DEVICE,
  FRAME_UPDATE_REPORT_PER_DEVICE,
  bucketOf,
} from '../../src/frames/frame_update_policy';
import { RATE_LIMITS, type RateLimitRule, rateLimitId } from '../../src/shared/rate_limit';
import { type Household, expectRefusal, household, samsHousehold } from './account_data_fixture';
import {
  CallFailed,
  adminDb,
  adminStorage,
  callAs,
  clearFirestore,
  closeAdmin,
  httpFunctionUrl,
} from './emulator_harness';

beforeEach(clearFirestore);
afterAll(closeAdmin);

interface Offer {
  versionCode: number;
  versionName: string;
  size: number;
  sha256: string;
}

interface Checked {
  checkAfterSeconds: number;
  window: { start: number; end: number };
  home: Offer | null;
  agent: Offer | null;
}

const HOUR = 60 * 60 * 1000;
const PANELS = { calendar: true, todos: true, meals: false, helperMemberId: null };
const APK = randomBytes(1000);
const SHA = 'c'.repeat(64);

const newSecret = (): string => randomBytes(32).toString('base64url');

function secretIn(wanted: (bucket: number) => boolean): string {
  for (;;) {
    const secret = newSecret();
    if (wanted(bucketOf(secretHash(secret)))) return secret;
  }
}

const standardSecret = (): string => secretIn((bucket) => bucket >= 10);

function checkBody(device: string, more: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    device,
    model: 'WF-1009',
    sdk: 23,
    apps: {
      home: { versionCode: 3, versionName: '1.0.3' },
      agent: { versionCode: 1, versionName: '1.0' },
    },
    bad: { home: [], agent: [] },
    state: 'idle',
    ...more,
  };
}

const check = (device: string, more: Record<string, unknown> = {}): Promise<Checked> =>
  callAs<Checked>(null, 'checkFrameUpdate', checkBody(device, more));

const deviceDoc = (secret: string): DocumentReference =>
  adminDb().collection('frameDevices').doc(secretHash(secret));

async function deviceOf(secret: string): Promise<Record<string, unknown>> {
  return (await deviceDoc(secret).get()).data() ?? {};
}

async function givenRelease(
  app: 'home' | 'agent',
  versionCode: number,
  more: Record<string, unknown> = {},
): Promise<void> {
  await adminDb()
    .collection('frameReleases')
    .doc(`${app}-${String(versionCode)}`)
    .set({
      app,
      packageName: app === 'home' ? 'io.nullstate.nestprep.home' : 'io.nullstate.nestprep.agent',
      versionCode,
      versionName: `1.0.${String(versionCode)}`,
      minSdk: 23,
      size: APK.length,
      sha256: SHA,
      signer: 'd'.repeat(64),
      storagePath: `frameReleases/${app}/${String(versionCode)}.apk`,
      notes: '',
      stage: 'all',
      paused: false,
      pausedReason: null,
      attempts: 0,
      successes: 0,
      rollbacks: 0,
      createdAt: Timestamp.now(),
      createdBy: 'staff@nestprep.test',
      updatedAt: Timestamp.now(),
      ...more,
    });
}

async function releaseOf(id: string): Promise<Record<string, unknown>> {
  return (await adminDb().collection('frameReleases').doc(id).get()).data() ?? {};
}

/** Both names the default bucket can have, as `document_share_fixture.ts` explains. */
async function putApk(
  app: string,
  versionCode: number,
  contentType = FRAME_APK_CONTENT_TYPE,
): Promise<void> {
  for (const bucket of ['nestprep-643b7.appspot.com', 'nestprep-643b7.firebasestorage.app']) {
    await adminStorage()
      .bucket(bucket)
      .file(`frameReleases/${app}/${String(versionCode)}.apk`)
      .save(APK, { contentType, resumable: false });
  }
}

async function exhaust(rule: RateLimitRule, subject: string): Promise<void> {
  await adminDb()
    .collection(RATE_LIMITS)
    .doc(rateLimitId(rule, subject))
    .set({ windowStart: Timestamp.now(), count: rule.limit });
}

async function linkFrame(h: Household): Promise<{ secret: string; frameId: string }> {
  const secret = newSecret();
  const { code } = await callAs<{ code: string }>(null, 'startFramePairing', { secret });
  const { frameId } = await callAs<{ frameId: string }>(h.sam, 'claimFramePairing', {
    householdId: h.householdId,
    code,
    name: 'Kitchen',
    panels: PANELS,
  });
  return { secret, frameId };
}

describe('checkFrameUpdate', () => {
  it('registers a device on its first check, unlinked, with nothing to offer', async () => {
    const secret = newSecret();
    const before = Date.now();
    const answer = await check(secret);
    const after = Date.now();

    expect(answer.checkAfterSeconds).toBe(3600);
    expect(answer.home).toBeNull();
    expect(answer.agent).toBeNull();
    expect(answer.window.start).toBeGreaterThanOrEqual(before);
    expect(answer.window.start).toBeLessThanOrEqual(after);
    expect(answer.window.end - answer.window.start).toBe(6 * HOUR);

    const stored = await deviceOf(secret);
    expect(stored).toMatchObject({
      model: 'WF-1009',
      sdk: 23,
      apps: {
        home: { versionCode: 3, versionName: '1.0.3' },
        agent: { versionCode: 1, versionName: '1.0' },
      },
      bad: { home: [], agent: [] },
      state: 'idle',
      frame: null,
      frameName: null,
      householdName: null,
      ring: 'standard',
      installNowUntil: null,
      rollbacks: 0,
      events: [],
    });
    for (const field of ['createdAt', 'updatedAt', 'lastCheckAt']) {
      expect(stored[field], field).toBeInstanceOf(Timestamp);
    }
    expect(JSON.stringify(stored)).not.toContain(secret);
  });

  it('offers the newest release of each app it may see, never a draft', async () => {
    const secret = standardSecret();
    await givenRelease('home', 4);
    await givenRelease('home', 5, { stage: 'draft' });
    await givenRelease('agent', 2);
    await givenRelease('agent', 3, { paused: true });

    const answer = await check(secret);
    expect(answer.home).toEqual({ versionCode: 4, versionName: '1.0.4', size: 1000, sha256: SHA });
    expect(answer.agent).toEqual({ versionCode: 2, versionName: '1.0.2', size: 1000, sha256: SHA });

    const later = await check(secret, {
      bad: { home: [4], agent: [] },
      apps: { home: null, agent: { versionCode: 2, versionName: '1.0.2' } },
    });
    expect(later.home).toBeNull();
    expect(later.agent).toBeNull();
    expect(await deviceOf(secret)).toMatchObject({
      apps: { home: null, agent: { versionCode: 2 } },
      bad: { home: [4], agent: [] },
    });
  });

  it('links a device through a frame secret, and installs in the household’s small hours', async () => {
    const h = await samsHousehold();
    const frame = await linkFrame(h);
    await household(h.householdId).update({ timeZone: 'Europe/London' });
    const secret = newSecret();

    const answer = await check(secret, { frame: frame.secret });
    const start = wallClockOf(new Date(answer.window.start), 'Europe/London');
    const end = wallClockOf(new Date(answer.window.end), 'Europe/London');
    expect(start.minute).toBe(60);
    expect(end.minute).toBe(300);
    expect(answer.window.end).toBeGreaterThan(Date.now());
    expect(answer.window.end - answer.window.start).toBeLessThanOrEqual(5 * HOUR);
    expect(await deviceOf(secret)).toMatchObject({
      frame: { householdId: h.householdId, frameId: frame.frameId },
      frameName: 'Kitchen',
      householdName: 'The Parkers',
    });

    const unlinked = await check(secret);
    expect(unlinked.window.end - unlinked.window.start).toBe(6 * HOUR);
    expect(await deviceOf(secret)).toMatchObject({
      frame: null,
      frameName: null,
      householdName: null,
    });
  });

  it('treats a frame secret that opens nothing as no frame', async () => {
    const h = await samsHousehold();
    const frame = await linkFrame(h);
    const secret = newSecret();
    await check(secret, { frame: frame.secret });
    await household(h.householdId).collection('frames').doc(frame.frameId).delete();

    for (const stranger of [frame.secret, newSecret(), 'not-a-secret']) {
      const answer = await check(secret, { frame: stranger });
      expect(answer.window.end - answer.window.start).toBe(6 * HOUR);
      expect(await deviceOf(secret)).toMatchObject({ frame: null, frameName: null });
    }
  });

  it('offers an internal release only on the internal ring, which a check never changes', async () => {
    const secret = standardSecret();
    await givenRelease('home', 4, { stage: 'internal' });
    expect((await check(secret)).home).toBeNull();

    await deviceDoc(secret).update({ ring: 'internal' });
    expect((await check(secret)).home).toMatchObject({ versionCode: 4 });
    expect(await deviceOf(secret)).toMatchObject({ ring: 'internal' });
  });

  it('offers a some release to one device in ten', async () => {
    await givenRelease('home', 4, { stage: 'some' });
    expect((await check(secretIn((bucket) => bucket < 10))).home).toMatchObject({
      versionCode: 4,
    });
    expect((await check(standardSecret())).home).toBeNull();
  });

  it('opens the window now while staff say install now, and checks back in fifteen minutes', async () => {
    const h = await samsHousehold();
    const frame = await linkFrame(h);
    const secret = newSecret();
    await check(secret, { frame: frame.secret });
    const until = Timestamp.fromMillis(Date.now() + HOUR);
    await deviceDoc(secret).update({ installNowUntil: until });

    const before = Date.now();
    const answer = await check(secret, { frame: frame.secret });
    expect(answer.checkAfterSeconds).toBe(900);
    expect(answer.window.start).toBeGreaterThanOrEqual(before);
    expect(answer.window.end).toBe(until.toMillis());
    expect(await deviceOf(secret)).toMatchObject({ installNowUntil: until });

    await deviceDoc(secret).update({ installNowUntil: Timestamp.fromMillis(Date.now() - 1000) });
    const lapsed = await check(secret, { frame: frame.secret });
    expect(lapsed.checkAfterSeconds).toBe(3600);
  });

  it('stops a device past sixty checks an hour, and an address past twenty new devices', async () => {
    const secret = newSecret();
    await check(secret);
    await exhaust(FRAME_UPDATE_CHECK_PER_DEVICE, secretHash(secret));
    await expectRefusal(check(secret), 'tooManyAttempts');

    const address = '203.0.113.9';
    await exhaust(FRAME_NEW_DEVICE_PER_ADDRESS, address);
    const fresh = newSecret();
    const response = await fetch(httpFunctionUrl('checkFrameUpdate'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-Forwarded-For': address },
      body: JSON.stringify({ data: checkBody(fresh) }),
    });
    const body = (await response.json()) as { error?: { details?: { reason?: string } } };
    expect(body.error?.details?.reason).toBe('tooManyAttempts');
    expect((await deviceDoc(fresh).get()).exists).toBe(false);
    const shared = await adminDb()
      .collection(RATE_LIMITS)
      .doc(rateLimitId(FRAME_NEW_DEVICE_OVERALL, 'all'))
      .get();
    expect(shared.data()?.['count']).toBe(1);
  });

  it('offers no release filed under another id, and a fault build only on the internal ring', async () => {
    const secret = standardSecret();
    await givenRelease('home', 4);
    await adminDb()
      .collection('frameReleases')
      .doc('home-9')
      .set({ ...(await releaseOf('home-4')), versionCode: 8, versionName: '1.0.8' });
    await givenRelease('agent', 2, { fault: 'crashOnStart', stagedAt: Timestamp.now() });
    const answer = await check(secret);
    expect(answer.home).toMatchObject({ versionCode: 4 });
    expect(answer.agent).toBeNull();

    await deviceDoc(secret).update({ ring: 'internal' });
    expect((await check(secret)).agent).toMatchObject({ versionCode: 2 });
  });

  it('counts a new device against its own address before the shared ceiling', async () => {
    const address = '198.51.100.7';
    await exhaust(FRAME_NEW_DEVICE_OVERALL, 'all');
    const response = await fetch(httpFunctionUrl('checkFrameUpdate'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-Forwarded-For': address },
      body: JSON.stringify({ data: checkBody(newSecret()) }),
    });
    const body = (await response.json()) as { error?: { details?: { reason?: string } } };
    expect(body.error?.details?.reason).toBe('tooManyAttempts');
    const own = await adminDb()
      .collection(RATE_LIMITS)
      .doc(rateLimitId(FRAME_NEW_DEVICE_PER_ADDRESS, address))
      .get();
    expect(own.data()).toMatchObject({ count: 1 });
  });

  it('refuses a body that is not a check', async () => {
    await expectRefusal(check(newSecret(), { sdk: 12 }), 'badRequest');
  });
});

function apkOf(
  body: unknown,
  { method = 'POST', range }: { method?: string; range?: string } = {},
): Promise<Response> {
  return fetch(httpFunctionUrl('getFrameUpdateApk'), {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(range === undefined ? {} : { Range: range }),
    },
    ...(method === 'POST' ? { body: JSON.stringify(body) } : {}),
  });
}

describe('getFrameUpdateApk', () => {
  async function given(): Promise<string> {
    const secret = standardSecret();
    await check(secret);
    await givenRelease('home', 4);
    await putApk('home', 4);
    return secret;
  }

  it('streams the whole APK', async () => {
    const secret = await given();
    const response = await apkOf({ device: secret, app: 'home', versionCode: 4 });
    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toBe(FRAME_APK_CONTENT_TYPE);
    expect(response.headers.get('content-length')).toBe('1000');
    expect(response.headers.get('cache-control')).toBe('no-store');
    expect(Buffer.from(await response.arrayBuffer()).equals(APK)).toBe(true);
  });

  it('records the fetch on the device, ten releases at most, and nothing for a refusal', async () => {
    const secret = await given();
    await apkOf({ device: secret, app: 'home', versionCode: 5 });
    expect((await deviceOf(secret))['fetched']).toBeUndefined();

    await fetchApk(secret);
    const fetched = (await deviceOf(secret))['fetched'] as Record<string, Timestamp>;
    expect(Object.keys(fetched)).toEqual(['home-4']);

    const older = Object.fromEntries(
      Array.from({ length: 12 }, (_, index) => [
        `agent-${String(index + 1)}`,
        Timestamp.fromMillis(Date.parse('2026-10-01T00:00:00Z') + index),
      ]),
    );
    await deviceDoc(secret).update({ fetched: older });
    await fetchApk(secret);
    const capped = (await deviceOf(secret))['fetched'] as Record<string, Timestamp>;
    expect(Object.keys(capped)).toHaveLength(10);
    expect(capped).toHaveProperty('home-4');
    expect(capped).toHaveProperty('agent-12');
    expect(capped).not.toHaveProperty('agent-3');
  });

  it('serves no release filed under another id', async () => {
    const secret = await given();
    await adminDb()
      .collection('frameReleases')
      .doc('home-5')
      .set({ ...(await releaseOf('home-4')), versionCode: 4 });
    expect((await apkOf({ device: secret, app: 'home', versionCode: 5 })).status).toBe(404);
  });

  it('serves a fault build to the internal ring only', async () => {
    const secret = await given();
    await adminDb().collection('frameReleases').doc('home-4').update({ fault: 'hang' });
    expect((await apkOf({ device: secret, app: 'home', versionCode: 4 })).status).toBe(404);
    await deviceDoc(secret).update({ ring: 'internal' });
    expect((await apkOf({ device: secret, app: 'home', versionCode: 4 })).status).toBe(200);
  });

  it('resumes from a byte offset', async () => {
    const secret = await given();
    const response = await apkOf(
      { device: secret, app: 'home', versionCode: 4 },
      { range: 'bytes=600-' },
    );
    expect(response.status).toBe(206);
    expect(response.headers.get('content-range')).toBe('bytes 600-999/1000');
    expect(response.headers.get('content-length')).toBe('400');
    expect(Buffer.from(await response.arrayBuffer()).equals(APK.subarray(600))).toBe(true);
  });

  it('sends the whole APK for any other range', async () => {
    const secret = await given();
    for (const range of ['bytes=0-10', 'bytes=1000-', 'bytes=-5']) {
      const response = await apkOf({ device: secret, app: 'home', versionCode: 4 }, { range });
      expect(response.status, range).toBe(200);
      expect((await response.arrayBuffer()).byteLength, range).toBe(1000);
    }
  });

  it('serves a paused release, so a download in flight survives the pause', async () => {
    const secret = await given();
    await adminDb().collection('frameReleases').doc('home-4').update({ paused: true });
    expect((await apkOf({ device: secret, app: 'home', versionCode: 4 })).status).toBe(200);
  });

  it('says unknownDevice to a device that never checked', async () => {
    await given();
    const response = await apkOf({ device: newSecret(), app: 'home', versionCode: 4 });
    expect(response.status).toBe(410);
    expect(await response.json()).toEqual({ status: 'unknownDevice' });
  });

  it('says missing for a draft, a stage the device cannot see, no release or no object', async () => {
    const secret = await given();
    await givenRelease('home', 5, { stage: 'draft' });
    await givenRelease('home', 6, { stage: 'internal' });
    await givenRelease('home', 7, { stage: 'some' });
    await givenRelease('home', 8);
    for (const versionCode of [5, 6, 7]) await putApk('home', versionCode);
    await putApk('agent', 4);
    for (const [app, versionCode] of [
      ['home', 5],
      ['home', 6],
      ['home', 7],
      ['home', 8],
      ['home', 9],
      ['agent', 4],
    ] as const) {
      const response = await apkOf({ device: secret, app, versionCode });
      expect(response.status, `${app}-${String(versionCode)}`).toBe(404);
      expect(await response.json()).toEqual({ status: 'missing' });
    }

    await deviceDoc(secret).update({ ring: 'internal' });
    expect((await apkOf({ device: secret, app: 'home', versionCode: 6 })).status).toBe(200);
    expect((await apkOf({ device: secret, app: 'home', versionCode: 5 })).status).toBe(404);
  });

  it('says missing for an object not stored as an APK', async () => {
    const secret = await given();
    await putApk('home', 4, 'application/octet-stream');
    expect((await apkOf({ device: secret, app: 'home', versionCode: 4 })).status).toBe(404);
  });

  it('answers only a POST of a well-formed body, and stops a device past thirty an hour', async () => {
    const secret = await given();
    const get = await apkOf(null, { method: 'GET' });
    expect(get.status).toBe(405);
    expect(get.headers.get('allow')).toBe('POST');

    const invalid = await apkOf({ device: secret, app: 'phone', versionCode: 4 });
    expect(invalid.status).toBe(400);
    expect(await invalid.json()).toEqual({ status: 'invalid' });

    await exhaust(FRAME_UPDATE_APK_PER_DEVICE, secretHash(secret));
    const throttled = await apkOf({ device: secret, app: 'home', versionCode: 4 });
    expect(throttled.status).toBe(429);
    expect(await throttled.json()).toEqual({ status: 'tooManyAttempts' });
  });
});

const APPS = {
  home: { versionCode: 4, versionName: '1.0.4' },
  agent: { versionCode: 1, versionName: '1.0' },
};

let nextEvent = 0;

function event(kind: string, more: Record<string, unknown> = {}): Record<string, unknown> {
  nextEvent += 1;
  return {
    id: `event-${String(nextEvent).padStart(6, '0')}`,
    kind,
    app: 'home',
    versionCode: 4,
    fromVersionCode: 3,
    detail: null,
    at: 1_793_000_000_000 + nextEvent,
    ...more,
  };
}

const report = (
  device: string,
  events: Record<string, unknown>[],
  state = 'probation',
): Promise<{ status: string }> =>
  callAs(null, 'reportFrameUpdate', { device, apps: APPS, state, events });

async function fetchApk(secret: string, versionCode = 4): Promise<void> {
  const response = await apkOf({ device: secret, app: 'home', versionCode });
  expect(response.status).toBe(200);
  await response.arrayBuffer();
}

describe('reportFrameUpdate', () => {
  async function installing(stage = 'all', more: Record<string, unknown> = {}): Promise<string> {
    const secret = newSecret();
    await check(secret);
    await deviceDoc(secret).update({ ring: 'internal' });
    await givenRelease('home', 4, { stage, ...more });
    await putApk('home', 4);
    await fetchApk(secret);
    return secret;
  }

  it('says unknownDevice to a device that never checked, and writes nothing', async () => {
    const secret = newSecret();
    expect(await report(secret, [event('installed')])).toEqual({ status: 'unknownDevice' });
    expect((await deviceDoc(secret).get()).exists).toBe(false);
  });

  it('counts an install it downloaded and a healthy start, and keeps the events newest first', async () => {
    const secret = await installing();
    const installed = event('installed');
    const healthy = event('healthy', { detail: 'passed probation' });

    expect(await report(secret, [installed, healthy], 'idle')).toEqual({ status: 'ok' });
    expect(await releaseOf('home-4')).toMatchObject({
      attempts: 1,
      successes: 1,
      rollbacks: 0,
      paused: false,
    });
    const stored = await deviceOf(secret);
    expect(stored).toMatchObject({
      apps: APPS,
      state: 'idle',
      rollbacks: 0,
      counted: { 'home-4': ['healthy', 'installed'] },
    });
    const events = stored['events'] as Record<string, unknown>[];
    expect(events.map((each) => each['id'])).toEqual([healthy['id'], installed['id']]);
    expect(events[0]).toMatchObject({
      kind: 'healthy',
      app: 'home',
      versionCode: 4,
      fromVersionCode: 3,
      detail: 'passed probation',
    });
    expect((events[0]?.['at'] as Timestamp).toMillis()).toBe(healthy['at']);
  });

  it('changes nothing for a resent event, and counts each kind once per device', async () => {
    const secret = await installing();
    const installed = event('installed');
    await report(secret, [installed]);
    await report(secret, [installed]);
    await report(secret, [installed, installed]);
    await report(secret, [event('installed'), event('healthy'), event('healthy')]);

    expect(await releaseOf('home-4')).toMatchObject({ attempts: 1, successes: 1 });
    expect((await deviceOf(secret))['events']).toHaveLength(4);
  });

  it('records but never counts what a device could not have done', async () => {
    const secret = newSecret();
    await check(secret);
    await givenRelease('home', 4);
    await givenRelease('home', 5, { stage: 'internal' });
    await givenRelease('home', 6, { stage: 'draft' });
    await givenRelease('home', 7, { fault: 'crashOnStart' });
    await adminDb()
      .collection('frameReleases')
      .doc('home-08')
      .set({ ...(await releaseOf('home-4')), versionCode: 8 });
    const forged = [
      event('installed'),
      ...[5, 6, 7, 8].flatMap((versionCode) => [
        event('installed', { versionCode }),
        event('healthy', { versionCode }),
        event('rolledBack', { versionCode }),
      ]),
    ];
    expect(await report(secret, forged)).toEqual({ status: 'ok' });

    for (const id of ['home-4', 'home-5', 'home-6', 'home-7', 'home-08']) {
      expect(await releaseOf(id), id).toMatchObject({
        attempts: 0,
        successes: 0,
        rollbacks: 0,
        paused: false,
      });
    }
    expect((await deviceOf(secret))['events']).toHaveLength(13);
  });

  it('leaves the release’s and the device’s updatedAt to staff', async () => {
    const secret = await installing();
    const staffAt = Timestamp.fromMillis(Date.parse('2026-11-01T10:00:00Z'));
    await adminDb().collection('frameReleases').doc('home-4').update({ updatedAt: staffAt });
    await deviceDoc(secret).update({ updatedAt: staffAt });

    await check(secret);
    await report(secret, [event('installed'), event('healthy')]);
    expect((await releaseOf('home-4'))['updatedAt']).toEqual(staffAt);
    expect(await deviceOf(secret)).toMatchObject({ updatedAt: staffAt });
    expect(((await deviceOf(secret))['lastCheckAt'] as Timestamp).toMillis()).toBeGreaterThan(
      staffAt.toMillis(),
    );
  });

  it.each(['internal', 'some'])(
    'halts an %s release on its first rollback, and says so in updatedAt',
    async (stage) => {
      const staffAt = Timestamp.fromMillis(Date.parse('2026-11-01T10:00:00Z'));
      const secret = await installing(stage, { attempts: 2, updatedAt: staffAt });
      await report(secret, [event('installed'), event('rolledBack', { detail: 'crashLoop' })]);

      const halted = await releaseOf('home-4');
      expect(halted).toMatchObject({
        attempts: 3,
        rollbacks: 1,
        paused: true,
        pausedReason: 'Halted: rolled back on 1 of 3 frames',
      });
      expect((halted['updatedAt'] as Timestamp).toMillis()).toBeGreaterThan(staffAt.toMillis());
      expect(await deviceOf(secret)).toMatchObject({ rollbacks: 1 });
    },
  );

  it('keeps a pause staff made, reason and all', async () => {
    const secret = await installing('some', { paused: true, pausedReason: 'Paused by sam@x' });
    await report(secret, [event('rolledBack')]);
    expect(await releaseOf('home-4')).toMatchObject({
      rollbacks: 1,
      paused: true,
      pausedReason: 'Paused by sam@x',
    });
  });

  it('halts a release to all once one install in twenty rolled back, one device each', async () => {
    const first = await installing('all', { attempts: 100, rollbacks: 3 });
    await report(first, [event('rolledBack')]);
    await report(first, [event('rolledBack')]);
    expect(await releaseOf('home-4')).toMatchObject({
      rollbacks: 4,
      paused: false,
      pausedReason: null,
    });

    const second = newSecret();
    await check(second);
    await deviceDoc(second).update({ ring: 'internal' });
    await report(second, [event('rolledBack')]);
    expect(await releaseOf('home-4')).toMatchObject({
      attempts: 100,
      rollbacks: 5,
      paused: true,
      pausedReason: 'Halted: rolled back on 5 of 100 frames',
    });
    expect(await deviceOf(first)).toMatchObject({ rollbacks: 2 });
  });

  it('counts on the device even when the release is gone', async () => {
    const secret = newSecret();
    await check(secret);
    expect(await report(secret, [event('rolledBack', { versionCode: 9 })])).toEqual({
      status: 'ok',
    });
    expect(await deviceOf(secret)).toMatchObject({ rollbacks: 1 });
    expect((await adminDb().collection('frameReleases').doc('home-9').get()).exists).toBe(false);
  });

  it('keeps the twenty newest events', async () => {
    const secret = newSecret();
    await check(secret);
    const first = Array.from({ length: 19 }, () => event('downloadFailed'));
    await report(secret, first.slice(0, 10));
    await report(secret, first.slice(10));
    const last = [event('verifyFailed'), event('installFailed'), event('downloadFailed')];
    await report(secret, last);

    const ids = ((await deviceOf(secret))['events'] as Record<string, unknown>[]).map(
      (each) => each['id'],
    );
    expect(ids).toHaveLength(20);
    expect(ids.slice(0, 3)).toEqual([last[2]?.['id'], last[1]?.['id'], last[0]?.['id']]);
    expect(ids).not.toContain(first[0]?.['id']);
    expect(ids).not.toContain(first[1]?.['id']);
  });

  it('stops a device past sixty reports an hour', async () => {
    const secret = newSecret();
    await check(secret);
    await exhaust(FRAME_UPDATE_REPORT_PER_DEVICE, secretHash(secret));
    await expectRefusal(report(secret, [event('installed')]), 'tooManyAttempts');
  });

  it('refuses a report with no events', async () => {
    const secret = newSecret();
    await check(secret);
    const error: unknown = await report(secret, []).catch((caught: unknown) => caught);
    expect(error).toBeInstanceOf(CallFailed);
  });
});
