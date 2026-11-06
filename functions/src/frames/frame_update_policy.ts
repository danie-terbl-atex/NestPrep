import { addDays, instantOf, isKnownZone, wallClockOf } from '../calendar_sync/zoned_time';
import type { RateLimitRule } from '../shared/rate_limit';

export const FRAME_UPDATE_APPS = ['home', 'agent'] as const;
export type FrameUpdateApp = (typeof FRAME_UPDATE_APPS)[number];

export const FRAME_RELEASE_STAGES = ['draft', 'internal', 'some', 'all'] as const;
export type FrameReleaseStage = (typeof FRAME_RELEASE_STAGES)[number];

export const FRAME_DEVICE_RINGS = ['internal', 'standard'] as const;
export type FrameDeviceRing = (typeof FRAME_DEVICE_RINGS)[number];

export const FRAME_DEVICE_STATES = [
  'idle',
  'downloading',
  'waiting',
  'installing',
  'probation',
  'rollingBack',
] as const;

export const FRAME_UPDATE_EVENT_KINDS = [
  'installed',
  'healthy',
  'rolledBack',
  'installFailed',
  'downloadFailed',
  'verifyFailed',
] as const;

export const FRAME_APK_CONTENT_TYPE = 'application/vnd.android.package-archive';

export const FRAME_UPDATE_LIST_LIMIT = 20;
export const FRAME_FETCHED_LIMIT = 10;
export const FRAME_COUNTED_LIMIT = 20;

export const FRAME_SOME_PERCENT = 10;

export const CHECK_AFTER_SECONDS = 60 * 60;
export const INSTALL_NOW_CHECK_AFTER_SECONDS = 15 * 60;

const UNLINKED_WINDOW_MS = 6 * 60 * 60 * 1000;
const WINDOW_STARTS = 60;
const WINDOW_ENDS = 5 * 60;
export const FRAME_UPDATE_FALLBACK_ZONE = 'Africa/Johannesburg';

const HALT_ALL_ONE_IN = 20;

export const FRAME_NEW_DEVICE_PER_ADDRESS: RateLimitRule = {
  name: 'checkFrameUpdate:newDevice',
  limit: 20,
  windowSeconds: 60 * 60,
};
export const FRAME_NEW_DEVICE_OVERALL: RateLimitRule = {
  name: 'checkFrameUpdate:newDeviceAll',
  limit: 2000,
  windowSeconds: 60 * 60,
};
export const FRAME_UPDATE_CHECK_PER_DEVICE: RateLimitRule = {
  name: 'checkFrameUpdate:device',
  limit: 60,
  windowSeconds: 60 * 60,
};
export const FRAME_UPDATE_CHECK_PER_CREDENTIAL: RateLimitRule = {
  name: 'checkFrameUpdate:credential',
  limit: 60,
  windowSeconds: 60 * 60,
};
export const FRAME_UPDATE_APK_PER_DEVICE: RateLimitRule = {
  name: 'getFrameUpdateApk:device',
  limit: 30,
  windowSeconds: 60 * 60,
};
export const FRAME_UPDATE_REPORT_PER_DEVICE: RateLimitRule = {
  name: 'reportFrameUpdate:device',
  limit: 60,
  windowSeconds: 60 * 60,
};

export interface OfferableRelease {
  readonly app: FrameUpdateApp;
  readonly versionCode: number;
  readonly minSdk: number;
  readonly stage: FrameReleaseStage;
  readonly paused: boolean;
  readonly fault: string | null;
}

export interface OfferedDevice {
  readonly deviceId: string;
  readonly ring: FrameDeviceRing;
  readonly sdk: number;
  readonly installed: number | null;
  readonly bad: readonly number[];
}

export function bucketOf(deviceId: string): number {
  return parseInt(deviceId.slice(0, 8), 16) % 100;
}

export function visibleStages(
  deviceId: string,
  ring: FrameDeviceRing,
): readonly FrameReleaseStage[] {
  if (ring === 'internal') return ['internal', 'some', 'all'];
  if (bucketOf(deviceId) < FRAME_SOME_PERCENT) return ['some', 'all'];
  return ['all'];
}

/** A fault-injection build never reaches past the internal ring, whatever its stage says. */
export function isVisibleTo(
  release: Pick<OfferableRelease, 'stage' | 'fault'>,
  device: Pick<OfferedDevice, 'deviceId' | 'ring'>,
): boolean {
  if (release.fault !== null && device.ring !== 'internal') return false;
  return visibleStages(device.deviceId, device.ring).includes(release.stage);
}

/** A paused newer release lets an older eligible one through. */
export function offerFor<T extends OfferableRelease>(
  app: FrameUpdateApp,
  releases: readonly T[],
  device: OfferedDevice,
): T | null {
  let best: T | null = null;
  for (const release of releases) {
    const eligible =
      release.app === app &&
      isVisibleTo(release, device) &&
      !release.paused &&
      release.minSdk <= device.sdk &&
      (device.installed === null || release.versionCode > device.installed) &&
      !device.bad.includes(release.versionCode);
    if (eligible && (best === null || release.versionCode > best.versionCode)) best = release;
  }
  return best;
}

export interface InstallWindow {
  readonly start: number;
  readonly end: number;
}

export interface WindowOf {
  readonly now: Date;
  readonly installNowUntil: Date | null;
  readonly linked: boolean;
  readonly timeZone: string | null;
}

export function installWindow({ now, installNowUntil, linked, timeZone }: WindowOf): InstallWindow {
  const at = now.getTime();
  if (installNowUntil !== null && installNowUntil.getTime() > at) {
    return { start: at, end: installNowUntil.getTime() };
  }
  if (!linked) return { start: at, end: at + UNLINKED_WINDOW_MS };

  const zone = timeZone !== null && isKnownZone(timeZone) ? timeZone : FRAME_UPDATE_FALLBACK_ZONE;
  const today = wallClockOf(now, zone).date;
  const date = at < instantOf(today, WINDOW_ENDS, zone).getTime() ? today : addDays(today, 1);
  return {
    start: instantOf(date, WINDOW_STARTS, zone).getTime(),
    end: instantOf(date, WINDOW_ENDS, zone).getTime(),
  };
}

export function checkAfterSeconds(now: Date, installNowUntil: Date | null): number {
  return installNowUntil !== null && installNowUntil.getTime() > now.getTime()
    ? INSTALL_NOW_CHECK_AFTER_SECONDS
    : CHECK_AFTER_SECONDS;
}

export function haltsAfterRollback(
  stage: FrameReleaseStage,
  attempts: number,
  rollbacks: number,
): boolean {
  if (stage === 'internal' || stage === 'some') return true;
  return stage === 'all' && rollbacks * HALT_ALL_ONE_IN >= Math.max(attempts, 1);
}

export function haltReason(attempts: number, rollbacks: number): string {
  return `Halted: rolled back on ${String(rollbacks)} of ${String(Math.max(attempts, rollbacks))} frames`;
}

export function resumeOffset(range: string | undefined, size: number): number | null {
  const match = /^bytes=(\d+)-$/.exec(range?.trim() ?? '');
  if (match === null) return null;
  const start = Number(match[1]);
  return Number.isSafeInteger(start) && start < size ? start : null;
}

export interface ReportedEvent {
  readonly id: string;
  readonly kind: (typeof FRAME_UPDATE_EVENT_KINDS)[number];
  readonly app: FrameUpdateApp;
  readonly versionCode: number;
  readonly at: number;
}

/** What a report adds: events not already on the device, each once, newest first. */
export function freshEvents<T extends ReportedEvent>(
  storedIds: readonly string[],
  reported: readonly T[],
): T[] {
  const seen = new Set(storedIds);
  const fresh: T[] = [];
  for (const event of reported) {
    if (seen.has(event.id)) continue;
    seen.add(event.id);
    fresh.push(event);
  }
  return fresh.sort((a, b) => b.at - a.at);
}

export interface ReleaseTally {
  readonly app: FrameUpdateApp;
  readonly versionCode: number;
  readonly installed: number;
  readonly healthy: number;
  readonly rolledBack: number;
}

export function releaseTallies(events: readonly ReportedEvent[]): ReleaseTally[] {
  const tallies: Record<string, ReleaseTally> = {};
  for (const event of events) {
    if (!countsOnRelease(event.kind)) continue;
    const key = releaseIdOf(event.app, event.versionCode);
    const tally = tallies[key] ?? {
      app: event.app,
      versionCode: event.versionCode,
      installed: 0,
      healthy: 0,
      rolledBack: 0,
    };
    tallies[key] = { ...tally, [event.kind]: tally[event.kind] + 1 };
  }
  return Object.values(tallies);
}

export interface ReleaseCounts {
  readonly stage: FrameReleaseStage;
  readonly paused: boolean;
  readonly attempts: number;
  readonly successes: number;
  readonly rollbacks: number;
}

export interface CountedRelease {
  readonly attempts: number;
  readonly successes: number;
  readonly rollbacks: number;
  readonly haltedReason: string | null;
}

export function countReport(release: ReleaseCounts, tally: ReleaseTally): CountedRelease {
  const attempts = release.attempts + tally.installed;
  const rollbacks = release.rollbacks + tally.rolledBack;
  const halts =
    tally.rolledBack > 0 &&
    !release.paused &&
    haltsAfterRollback(release.stage, attempts, rollbacks);
  return {
    attempts,
    successes: release.successes + tally.healthy,
    rollbacks,
    haltedReason: halts ? haltReason(attempts, rollbacks) : null,
  };
}

export function releaseIdOf(app: FrameUpdateApp, versionCode: number): string {
  return `${app}-${String(versionCode)}`;
}

export function withFetched(
  fetched: Readonly<Record<string, number>>,
  releaseId: string,
  at: number,
): Record<string, number> {
  const newest = Object.entries({ ...fetched, [releaseId]: at })
    .sort(([, a], [, b]) => b - a)
    .slice(0, FRAME_FETCHED_LIMIT);
  return Object.fromEntries(newest);
}

export interface CountableRelease extends OfferableRelease {
  readonly id: string;
}

export interface CountingDevice {
  readonly deviceId: string;
  readonly ring: FrameDeviceRing;
  readonly fetched: readonly string[];
  readonly counted: Readonly<Record<string, readonly string[]>>;
}

export interface Countable<T> {
  readonly events: T[];
  readonly counted: Record<string, string[]>;
}

export function countsOnRelease(
  kind: ReportedEvent['kind'],
): kind is 'installed' | 'healthy' | 'rolledBack' {
  return kind === 'installed' || kind === 'healthy' || kind === 'rolledBack';
}

/**
 * The events that may move a release's counters: on a release this device can
 * see, an install only of an APK it fetched, and each kind once per device.
 */
export function countableEvents<T extends ReportedEvent>(
  events: readonly T[],
  releases: Readonly<Record<string, CountableRelease | undefined>>,
  device: CountingDevice,
): Countable<T> {
  const counted: Record<string, string[]> = {};
  for (const [id, kinds] of Object.entries(device.counted)) counted[id] = [...kinds];
  const countable: T[] = [];
  for (const event of events) {
    if (!countsOnRelease(event.kind)) continue;
    const id = releaseIdOf(event.app, event.versionCode);
    const release = releases[id];
    if (release?.id !== id || release.stage === 'draft' || !isVisibleTo(release, device)) continue;
    if (event.kind === 'installed' && !device.fetched.includes(id)) continue;
    const kinds = counted[id] ?? [];
    if (kinds.includes(event.kind)) continue;
    counted[id] = [...kinds, event.kind];
    countable.push(event);
  }
  return { events: countable, counted: newestCounted(counted) };
}

function newestCounted(counted: Record<string, string[]>): Record<string, string[]> {
  const versionOf = (id: string): number => Number(id.slice(id.lastIndexOf('-') + 1));
  const newest = Object.entries(counted)
    .sort(([a], [b]) => versionOf(b) - versionOf(a) || a.localeCompare(b))
    .slice(0, FRAME_COUNTED_LIMIT);
  return Object.fromEntries(newest);
}
