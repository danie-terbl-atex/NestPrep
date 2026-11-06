import { Timestamp } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import {
  checkFrameUpdateInput,
  getFrameUpdateApkInput,
  reportFrameUpdateInput,
} from '../../../src/frames/frame_schemas';
import {
  CHECK_AFTER_SECONDS,
  INSTALL_NOW_CHECK_AFTER_SECONDS,
  type InstallWindow,
  type OfferableRelease,
  type OfferedDevice,
  type ReportedEvent,
  bucketOf,
  checkAfterSeconds,
  countReport,
  countableEvents,
  type CountableRelease,
  type CountingDevice,
  freshEvents,
  haltReason,
  haltsAfterRollback,
  installWindow,
  offerFor,
  releaseTallies,
  resumeOffset,
  visibleStages,
  withFetched,
} from '../../../src/frames/frame_update_policy';
import { frameDeviceDocument, parsedRelease } from '../../../src/frames/frame_update_documents';
import { isClientGone } from '../../../src/frames/frame_http';
import { parseInput } from '../../../src/household/parse_input';
import { validBodies } from '../input_boundary/valid_bodies';

const IN_SOME = `00000005${'a'.repeat(56)}`;
const IN_ALL = `00000032${'a'.repeat(56)}`;

function release(versionCode: number, overrides: Partial<OfferableRelease> = {}): OfferableRelease {
  return {
    app: 'home',
    versionCode,
    minSdk: 23,
    stage: 'all',
    paused: false,
    fault: null,
    ...overrides,
  };
}

function device(overrides: Partial<OfferedDevice> = {}): OfferedDevice {
  return { deviceId: IN_ALL, ring: 'standard', sdk: 23, installed: 3, bad: [], ...overrides };
}

const offered = (releases: OfferableRelease[], on: Partial<OfferedDevice> = {}): number | null =>
  offerFor('home', releases, device(on))?.versionCode ?? null;

describe('a device’s bucket', () => {
  it('is the first eight hex digits of its id, mod 100', () => {
    expect(bucketOf(IN_SOME)).toBe(5);
    expect(bucketOf(IN_ALL)).toBe(50);
    expect(bucketOf(`ffffffff${'0'.repeat(56)}`)).toBe(0xffffffff % 100);
  });

  it('puts one device in ten in the first stage past internal', () => {
    expect(visibleStages(IN_SOME, 'standard')).toEqual(['some', 'all']);
    expect(visibleStages(`00000009${'a'.repeat(56)}`, 'standard')).toEqual(['some', 'all']);
    expect(visibleStages(`0000000a${'a'.repeat(56)}`, 'standard')).toEqual(['all']);
    expect(visibleStages(IN_ALL, 'standard')).toEqual(['all']);
  });

  it('does not matter on the internal ring, which sees every stage but draft', () => {
    expect(visibleStages(IN_ALL, 'internal')).toEqual(['internal', 'some', 'all']);
    expect(visibleStages(IN_SOME, 'internal')).toEqual(['internal', 'some', 'all']);
  });
});

describe('the release a device is offered', () => {
  it.each([
    ['draft', 'internal', IN_SOME, null],
    ['internal', 'internal', IN_ALL, 4],
    ['internal', 'standard', IN_SOME, null],
    ['some', 'internal', IN_ALL, 4],
    ['some', 'standard', IN_SOME, 4],
    ['some', 'standard', IN_ALL, null],
    ['all', 'standard', IN_ALL, 4],
    ['all', 'internal', IN_ALL, 4],
  ] as const)('a %s release on the %s ring, bucket of %s: %s', (stage, ring, deviceId, wanted) => {
    expect(offered([release(4, { stage })], { ring, deviceId })).toBe(wanted);
  });

  it('is the highest eligible version', () => {
    expect(offered([release(4), release(6), release(5)])).toBe(6);
  });

  it('skips a paused release and lets an older eligible one through', () => {
    expect(offered([release(4), release(5, { paused: true })])).toBe(4);
    expect(offered([release(5, { paused: true })])).toBeNull();
  });

  it('skips a release the device’s Android is too old for', () => {
    expect(offered([release(4), release(5, { minSdk: 26 })])).toBe(4);
    expect(offered([release(5, { minSdk: 26 })], { sdk: 27 })).toBe(5);
  });

  it('skips a version the device marked bad', () => {
    expect(offered([release(4), release(5)], { bad: [5] })).toBe(4);
    expect(offered([release(4), release(5)], { bad: [4, 5] })).toBeNull();
  });

  it('is only ever newer than what is installed', () => {
    expect(offered([release(2), release(3)])).toBeNull();
    expect(offered([release(3), release(4)], { installed: 4 })).toBeNull();
  });

  it('is any version when nothing is installed', () => {
    expect(offered([release(1), release(2)], { installed: null })).toBe(2);
  });

  it('is of the app asked about', () => {
    expect(offered([release(9, { app: 'agent' }), release(4)])).toBe(4);
    expect(offerFor('agent', [release(9, { app: 'agent' }), release(10)], device())).toEqual(
      release(9, { app: 'agent' }),
    );
  });

  it('never reaches past the internal ring for a fault-injection build', () => {
    const faulty = release(4, { fault: 'crashOnStart' });
    expect(offered([faulty], { deviceId: IN_ALL })).toBeNull();
    expect(offered([faulty], { deviceId: IN_SOME })).toBeNull();
    expect(offered([faulty], { ring: 'internal' })).toBe(4);
    expect(offered([release(4, { fault: 'hang', stage: 'internal' })], { ring: 'internal' })).toBe(
      4,
    );
  });

  it('is null with no releases at all', () => {
    expect(offered([])).toBeNull();
  });
});

const at = (iso: string): Date => new Date(iso);
const ms = (iso: string): number => Date.parse(iso);

const linked = (now: string, timeZone: string | null = 'Africa/Johannesburg'): InstallWindow =>
  installWindow({ now: at(now), installNowUntil: null, linked: true, timeZone });

describe('when a linked frame may install', () => {
  it('is the next 01:00 to 05:00 in the household’s zone', () => {
    expect(linked('2026-11-06T10:00:00Z')).toEqual({
      start: ms('2026-11-06T23:00:00Z'),
      end: ms('2026-11-07T03:00:00Z'),
    });
  });

  it('is tonight’s, before 01:00', () => {
    expect(linked('2026-11-05T22:30:00Z')).toEqual({
      start: ms('2026-11-05T23:00:00Z'),
      end: ms('2026-11-06T03:00:00Z'),
    });
  });

  it('started at 01:00 when it is already inside', () => {
    expect(linked('2026-11-06T00:30:00Z')).toEqual({
      start: ms('2026-11-05T23:00:00Z'),
      end: ms('2026-11-06T03:00:00Z'),
    });
    expect(linked('2026-11-05T23:00:00Z').start).toBe(ms('2026-11-05T23:00:00Z'));
  });

  it('is tomorrow’s from 05:00 on', () => {
    expect(linked('2026-11-06T03:00:00Z')).toEqual({
      start: ms('2026-11-06T23:00:00Z'),
      end: ms('2026-11-07T03:00:00Z'),
    });
  });

  it('follows a zone with daylight saving across both changes', () => {
    expect(linked('2026-03-28T12:00:00Z', 'Europe/London')).toEqual({
      start: ms('2026-03-29T01:00:00Z'),
      end: ms('2026-03-29T04:00:00Z'),
    });
    expect(linked('2026-03-30T12:00:00Z', 'Europe/London')).toEqual({
      start: ms('2026-03-31T00:00:00Z'),
      end: ms('2026-03-31T04:00:00Z'),
    });
    expect(linked('2026-10-24T12:00:00Z', 'Europe/London')).toEqual({
      start: ms('2026-10-25T00:00:00Z'),
      end: ms('2026-10-25T05:00:00Z'),
    });
    expect(linked('2026-10-25T01:30:00Z', 'Europe/London')).toEqual({
      start: ms('2026-10-25T00:00:00Z'),
      end: ms('2026-10-25T05:00:00Z'),
    });
    expect(linked('2026-11-06T10:00:00Z', 'Europe/London')).toEqual({
      start: ms('2026-11-07T01:00:00Z'),
      end: ms('2026-11-07T05:00:00Z'),
    });
  });

  it('uses Johannesburg for a zone this runtime does not know, or none', () => {
    const johannesburg = linked('2026-11-06T10:00:00Z');
    expect(linked('2026-11-06T10:00:00Z', 'Mars/Olympus_Mons')).toEqual(johannesburg);
    expect(linked('2026-11-06T10:00:00Z', null)).toEqual(johannesburg);
  });
});

describe('when any other frame may install', () => {
  it('an unlinked one, for the next six hours', () => {
    const now = at('2026-11-06T10:00:00Z');
    expect(installWindow({ now, installNowUntil: null, linked: false, timeZone: null })).toEqual({
      start: now.getTime(),
      end: now.getTime() + 6 * 60 * 60 * 1000,
    });
  });

  it('one staff told to install now, until then, linked or not', () => {
    const now = at('2026-11-06T10:00:00Z');
    const until = at('2026-11-06T11:00:00Z');
    for (const isLinked of [true, false]) {
      expect(
        installWindow({ now, installNowUntil: until, linked: isLinked, timeZone: 'Europe/London' }),
      ).toEqual({ start: now.getTime(), end: until.getTime() });
    }
  });

  it('one whose install-now has run out, as if it had none', () => {
    const now = at('2026-11-06T10:00:00Z');
    const until = at('2026-11-06T09:00:00Z');
    expect(
      installWindow({ now, installNowUntil: until, linked: true, timeZone: 'Africa/Johannesburg' }),
    ).toEqual(linked('2026-11-06T10:00:00Z'));
  });
});

describe('how soon a device checks again', () => {
  const now = at('2026-11-06T10:00:00Z');
  it('is an hour, or fifteen minutes while staff say install now', () => {
    expect(checkAfterSeconds(now, null)).toBe(CHECK_AFTER_SECONDS);
    expect(CHECK_AFTER_SECONDS).toBe(3600);
    expect(checkAfterSeconds(at('2026-11-06T11:00:00Z'), at('2026-11-06T10:00:00Z'))).toBe(3600);
    expect(checkAfterSeconds(now, at('2026-11-06T11:00:00Z'))).toBe(
      INSTALL_NOW_CHECK_AFTER_SECONDS,
    );
    expect(INSTALL_NOW_CHECK_AFTER_SECONDS).toBe(900);
  });
});

describe('a rollback halts a rollout', () => {
  it('always while it is internal or some', () => {
    expect(haltsAfterRollback('internal', 50, 1)).toBe(true);
    expect(haltsAfterRollback('some', 50, 1)).toBe(true);
  });

  it('at one in twenty once it is all', () => {
    expect(haltsAfterRollback('all', 100, 4)).toBe(false);
    expect(haltsAfterRollback('all', 100, 5)).toBe(true);
    expect(haltsAfterRollback('all', 20, 1)).toBe(true);
    expect(haltsAfterRollback('all', 21, 1)).toBe(false);
    expect(haltsAfterRollback('all', 0, 1)).toBe(true);
  });

  it('never in draft', () => {
    expect(haltsAfterRollback('draft', 1, 1)).toBe(false);
  });

  it('and says how many of how many', () => {
    expect(haltReason(3, 1)).toBe('Halted: rolled back on 1 of 3 frames');
    expect(haltReason(0, 1)).toBe('Halted: rolled back on 1 of 1 frames');
  });
});

function event(id: string, overrides: Partial<ReportedEvent> = {}): ReportedEvent {
  return { id, kind: 'installed', app: 'home', versionCode: 4, at: 1000, ...overrides };
}

describe('what a report adds', () => {
  it('drops events already on the device, and a repeat within the report', () => {
    const fresh = freshEvents(
      ['old-00001'],
      [event('old-00001'), event('new-00001'), event('new-00001', { at: 2000 })],
    );
    expect(fresh.map((each) => each.id)).toEqual(['new-00001']);
  });

  it('puts the newest first', () => {
    const fresh = freshEvents(
      [],
      [event('a-000001', { at: 1 }), event('b-000001', { at: 3 }), event('c-000001', { at: 2 })],
    );
    expect(fresh.map((each) => each.id)).toEqual(['b-000001', 'c-000001', 'a-000001']);
  });

  it('counts installs, healthy starts and rollbacks per release, nothing else', () => {
    expect(
      releaseTallies([
        event('a-000001'),
        event('b-000001', { kind: 'healthy' }),
        event('c-000001', { kind: 'rolledBack' }),
        event('d-000001', { kind: 'installFailed' }),
        event('e-000001', { kind: 'downloadFailed', versionCode: 5 }),
        event('f-000001', { kind: 'installed', app: 'agent', versionCode: 2 }),
      ]),
    ).toEqual([
      { app: 'home', versionCode: 4, installed: 1, healthy: 1, rolledBack: 1 },
      { app: 'agent', versionCode: 2, installed: 1, healthy: 0, rolledBack: 0 },
    ]);
  });

  it('halts the release only when it carries a rollback', () => {
    const counts = {
      stage: 'internal',
      paused: false,
      attempts: 2,
      successes: 1,
      rollbacks: 0,
    } as const;
    const tally = { app: 'home', versionCode: 4, installed: 1, healthy: 1, rolledBack: 0 } as const;
    expect(countReport(counts, tally)).toEqual({
      attempts: 3,
      successes: 2,
      rollbacks: 0,
      haltedReason: null,
    });
    expect(countReport(counts, { ...tally, rolledBack: 1 })).toEqual({
      attempts: 3,
      successes: 2,
      rollbacks: 1,
      haltedReason: 'Halted: rolled back on 1 of 3 frames',
    });
    expect(
      countReport({ ...counts, stage: 'all', attempts: 40 }, { ...tally, rolledBack: 1 }),
    ).toMatchObject({ haltedReason: null });
    expect(countReport({ ...counts, paused: true }, { ...tally, rolledBack: 1 })).toMatchObject({
      rollbacks: 1,
      haltedReason: null,
    });
  });
});

describe('a resumed download', () => {
  it('starts at the offset of a single open range inside the file', () => {
    expect(resumeOffset('bytes=100-', 1000)).toBe(100);
    expect(resumeOffset('bytes=0-', 1000)).toBe(0);
    expect(resumeOffset('bytes=999-', 1000)).toBe(999);
  });

  it.each([
    ['no range', undefined],
    ['a closed range', 'bytes=100-200'],
    ['a suffix range', 'bytes=-100'],
    ['several ranges', 'bytes=0-1,5-'],
    ['another unit', 'items=100-'],
    ['an offset past the end', 'bytes=1000-'],
    ['garbage', 'bytes=abc-'],
  ])('is the whole file for %s', (_, range) => {
    expect(resumeOffset(range, 1000)).toBeNull();
  });
});

describe('what a frame’s update agent sends', () => {
  const check = validBodies.checkFrameUpdate.body;
  const report = validBodies.reportFrameUpdate.body;
  const apk = validBodies.getFrameUpdateApk.body;
  const firstEvent = report.events[0];

  it('may name its frame, and a frame secret that is not one reads as no frame', () => {
    expect(parseInput(checkFrameUpdateInput, check).frame).toBeNull();
    expect(parseInput(checkFrameUpdateInput, { ...check, frame: 'f'.repeat(43) }).frame).toBe(
      'f'.repeat(43),
    );
    expect(parseInput(checkFrameUpdateInput, { ...check, frame: null }).frame).toBeNull();
    expect(parseInput(checkFrameUpdateInput, { ...check, frame: 'short' }).frame).toBeNull();
  });

  it('may have no home app installed, but always has itself', () => {
    expect(() =>
      parseInput(checkFrameUpdateInput, { ...check, apps: { ...check.apps, home: null } }),
    ).not.toThrow();
    expect(() =>
      parseInput(checkFrameUpdateInput, { ...check, apps: { ...check.apps, agent: null } }),
    ).toThrow(HttpsError);
  });

  it.each([
    ['a device secret that is not one', { device: 'short' }],
    ['an Android older than 5', { sdk: 20 }],
    ['an Android past 99', { sdk: 100 }],
    ['a model longer than eighty', { model: 'm'.repeat(81) }],
    ['a state the agent does not have', { state: 'sleeping' }],
    ['more than twenty bad versions', { bad: { home: Array(21).fill(1), agent: [] } }],
    ['a bad version that is not whole', { bad: { home: [1.5], agent: [] } }],
    [
      'a version name longer than forty',
      { apps: { ...check.apps, agent: { versionCode: 1, versionName: 'v'.repeat(41) } } },
    ],
    [
      'a version code below one',
      { apps: { ...check.apps, agent: { versionCode: 0, versionName: '1' } } },
    ],
  ])('a check refuses %s', (_, change) => {
    expect(() => parseInput(checkFrameUpdateInput, { ...check, ...change })).toThrow(HttpsError);
  });

  it('reports events with no previous version or detail', () => {
    const parsed = parseInput(reportFrameUpdateInput, {
      ...report,
      events: [{ id: 'event-0002', kind: 'healthy', app: 'agent', versionCode: 2, at: 0 }],
    });
    expect(parsed.events[0]).toMatchObject({ fromVersionCode: null, detail: null });
  });

  it.each([
    ['no events', { events: [] }],
    ['more than twenty events', { events: Array(21).fill(firstEvent) }],
    ['an event id too short', { events: [{ ...firstEvent, id: 'abc' }] }],
    ['an event id with a slash', { events: [{ ...firstEvent, id: 'event/0001' }] }],
    ['an event kind the agent does not have', { events: [{ ...firstEvent, kind: 'exploded' }] }],
    ['an app that is not one of the two', { events: [{ ...firstEvent, app: 'phone' }] }],
    ['a time before 1970', { events: [{ ...firstEvent, at: -1 }] }],
    ['a detail longer than 200', { events: [{ ...firstEvent, detail: 'd'.repeat(201) }] }],
  ])('a report refuses %s', (_, change) => {
    expect(() => parseInput(reportFrameUpdateInput, { ...report, ...change })).toThrow(HttpsError);
  });

  it.each([
    ['an app that is not one of the two', { app: 'phone' }],
    ['a version code as text', { versionCode: '4' }],
    ['a device secret that is not one', { device: 'short' }],
  ])('an APK download refuses %s', (_, change) => {
    expect(getFrameUpdateApkInput.safeParse({ ...apk, ...change }).success).toBe(false);
  });
});

const HOME_4: CountableRelease = { id: 'home-4', ...release(4) };

function counting(overrides: Partial<CountingDevice> = {}): CountingDevice {
  return { deviceId: IN_ALL, ring: 'standard', fetched: ['home-4'], counted: {}, ...overrides };
}

const idsOf = (events: readonly ReportedEvent[]): string[] => events.map((each) => each.id);

describe('which reported events may move a release’s counters', () => {
  const releases = { 'home-4': HOME_4 };

  it('an install of an APK the device fetched, a healthy start and a rollback, once each', () => {
    const result = countableEvents(
      [
        event('a-000001'),
        event('b-000001', { kind: 'healthy' }),
        event('c-000001', { kind: 'rolledBack' }),
        event('d-000001'),
        event('e-000001', { kind: 'rolledBack' }),
      ],
      releases,
      counting(),
    );
    expect(idsOf(result.events)).toEqual(['a-000001', 'b-000001', 'c-000001']);
    expect(result.counted).toEqual({ 'home-4': ['installed', 'healthy', 'rolledBack'] });
  });

  it('not a kind this device has already counted on that release', () => {
    const result = countableEvents(
      [event('a-000001'), event('b-000001', { kind: 'healthy' })],
      releases,
      counting({ counted: { 'home-4': ['installed'] } }),
    );
    expect(idsOf(result.events)).toEqual(['b-000001']);
    expect(result.counted).toEqual({ 'home-4': ['installed', 'healthy'] });
  });

  it('not an install of an APK the device never fetched', () => {
    const result = countableEvents(
      [event('a-000001'), event('b-000001', { kind: 'rolledBack' })],
      releases,
      counting({ fetched: ['home-3'] }),
    );
    expect(idsOf(result.events)).toEqual(['b-000001']);
  });

  it('nothing on a release that is missing, a draft, out of sight or a fault build', () => {
    for (const [label, known, on] of [
      ['missing', {}, counting()],
      ['a draft', { 'home-4': { ...HOME_4, stage: 'draft' } }, counting({ ring: 'internal' })],
      ['internal only', { 'home-4': { ...HOME_4, stage: 'internal' } }, counting()],
      ['some, bucket 50', { 'home-4': { ...HOME_4, stage: 'some' } }, counting()],
      ['a fault build', { 'home-4': { ...HOME_4, fault: 'hang' } }, counting()],
      ['under another id', { 'home-4': { ...HOME_4, id: 'home-04' } }, counting()],
    ] as const) {
      const result = countableEvents(
        [event('a-000001'), event('b-000001', { kind: 'rolledBack' })],
        known,
        on,
      );
      expect(result.events, label).toEqual([]);
    }
  });

  it('nothing for a kind that never counts', () => {
    const result = countableEvents(
      [event('a-000001', { kind: 'installFailed' }), event('b-000001', { kind: 'verifyFailed' })],
      releases,
      counting(),
    );
    expect(result.events).toEqual([]);
    expect(result.counted).toEqual({});
  });

  it('remembers the twenty newest releases it counted on', () => {
    const counted = Object.fromEntries(
      Array.from({ length: 25 }, (_, index) => [`home-${String(index + 1)}`, ['installed']]),
    );
    const result = countableEvents([], releases, counting({ counted }));
    expect(Object.keys(result.counted)).toHaveLength(20);
    expect(result.counted).toHaveProperty('home-25');
    expect(result.counted).toHaveProperty('home-6');
    expect(result.counted).not.toHaveProperty('home-5');
  });
});

describe('the APKs a device fetched', () => {
  it('keeps the ten newest, the one just fetched among them', () => {
    const fetched = Object.fromEntries(
      Array.from({ length: 10 }, (_, index) => [`home-${String(index + 1)}`, index + 1]),
    );
    const next = withFetched(fetched, 'agent-2', 100);
    expect(Object.keys(next)).toHaveLength(10);
    expect(next).toMatchObject({ 'agent-2': 100, 'home-10': 10 });
    expect(next).not.toHaveProperty('home-1');
    expect(withFetched({ 'home-4': 1 }, 'home-4', 50)).toEqual({ 'home-4': 50 });
  });
});

const STORED_RELEASE = {
  app: 'home',
  versionCode: 4,
  versionName: '1.0.4',
  minSdk: 23,
  size: 1000,
  sha256: 'c'.repeat(64),
  storagePath: 'frameReleases/home/4.apk',
  stage: 'all',
  paused: false,
};

describe('a release document as other writers leave it', () => {
  it('reads without a fault or a stagedAt, and with them', () => {
    expect(parsedRelease('home-4', STORED_RELEASE)).toMatchObject({
      id: 'home-4',
      fault: null,
      stagedAt: null,
    });
    const stagedAt = Timestamp.now();
    expect(
      parsedRelease('home-4', { ...STORED_RELEASE, fault: 'crashOnStart', stagedAt }),
    ).toMatchObject({ fault: 'crashOnStart', stagedAt });
    expect(parsedRelease('home-4', { ...STORED_RELEASE, fault: null })).toMatchObject({
      fault: null,
    });
  });

  it('reads a fault it cannot make sense of as a fault build', () => {
    expect(parsedRelease('home-4', { ...STORED_RELEASE, fault: 7 })?.fault).not.toBeNull();
  });

  it('is not a release under any id but its own', () => {
    expect(parsedRelease('home-5', STORED_RELEASE)).toBeNull();
    expect(parsedRelease('agent-4', STORED_RELEASE)).toBeNull();
    expect(parsedRelease('home-04', STORED_RELEASE)).toBeNull();
  });
});

describe('a device document as stored', () => {
  it('keeps the readable events when one is broken', () => {
    const device = frameDeviceDocument.parse({
      events: [
        { id: 'a-000001', kind: 'installed' },
        'junk',
        { kind: 'healthy' },
        { id: 'b-000001' },
      ],
    });
    expect(device.events.map((each) => each.id)).toEqual(['a-000001', 'b-000001']);
  });

  it('keeps the readable fetched and counted entries', () => {
    const at = Timestamp.now();
    const device = frameDeviceDocument.parse({
      fetched: { 'home-4': at, 'home-5': 'yesterday' },
      counted: { 'home-4': ['installed'], 'home-5': 'installed' },
    });
    expect(device.fetched).toEqual({ 'home-4': at });
    expect(device.counted).toEqual({ 'home-4': ['installed'] });
    expect(frameDeviceDocument.parse({})).toMatchObject({ events: [], fetched: {}, counted: {} });
  });
});

describe('a download the frame hangs up on', () => {
  it('is the client going away, not a failure', () => {
    expect(
      isClientGone(Object.assign(new Error('closed'), { code: 'ERR_STREAM_PREMATURE_CLOSE' })),
    ).toBe(true);
    expect(isClientGone(Object.assign(new Error('reset'), { code: 'ECONNRESET' }))).toBe(true);
    expect(isClientGone(new Error('storage said no'))).toBe(false);
    expect(isClientGone('ECONNRESET')).toBe(false);
  });
});
