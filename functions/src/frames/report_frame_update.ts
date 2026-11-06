import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { parseInput } from '../household/parse_input';
import { db } from '../shared/firestore';
import { consumeRateLimit } from '../shared/rate_limit';
import { secretHash } from './frame_documents';
import { refuseFrame } from './frame_errors';
import { FRAME_DEVICE_OPTIONS } from './frame_policy';
import { type FrameUpdateEvent, reportFrameUpdateInput } from './frame_schemas';
import {
  FRAME_RELEASES,
  type FrameRelease,
  frameDeviceDocument,
  frameDeviceRef,
  parsedRelease,
} from './frame_update_documents';
import {
  FRAME_UPDATE_LIST_LIMIT,
  FRAME_UPDATE_REPORT_PER_DEVICE,
  countReport,
  countableEvents,
  countsOnRelease,
  freshEvents,
  releaseIdOf,
  releaseTallies,
} from './frame_update_policy';

export interface ReportFrameUpdateResult {
  readonly status: 'ok' | 'unknownDevice';
}

const OK: ReportFrameUpdateResult = { status: 'ok' };
const UNKNOWN: ReportFrameUpdateResult = { status: 'unknownDevice' };

export const reportFrameUpdate = onCall(
  FRAME_DEVICE_OPTIONS,
  async (request): Promise<ReportFrameUpdateResult> => {
    const input = parseInput(reportFrameUpdateInput, request.data);
    const store = db();
    const deviceId = secretHash(input.device);
    const ref = frameDeviceRef(store, deviceId);

    if (!(await ref.get()).exists) return UNKNOWN;
    if (!(await consumeRateLimit(store, FRAME_UPDATE_REPORT_PER_DEVICE, deviceId))) {
      throw refuseFrame('tooManyAttempts');
    }

    const halted = await store.runTransaction(async (transaction): Promise<string[] | null> => {
      const snapshot = await transaction.get(ref);
      if (!snapshot.exists) return null;
      const device = frameDeviceDocument.parse(snapshot.data());
      const fresh = freshEvents(
        device.events.map((event) => event.id),
        input.events,
      );
      const candidates = [
        ...new Set(
          fresh
            .filter((event) => countsOnRelease(event.kind))
            .map((event) => releaseIdOf(event.app, event.versionCode)),
        ),
      ];
      const read = await Promise.all(
        candidates.map(async (id) =>
          parsedRelease(
            id,
            (await transaction.get(store.collection(FRAME_RELEASES).doc(id))).data(),
          ),
        ),
      );
      const releases: Record<string, FrameRelease | undefined> = Object.fromEntries(
        read.flatMap((release) => (release === null ? [] : [[release.id, release]])),
      );
      const countable = countableEvents(fresh, releases, {
        deviceId,
        ring: device.ring,
        fetched: Object.keys(device.fetched),
        counted: device.counted,
      });

      const stopped: string[] = [];
      for (const tally of releaseTallies(countable.events)) {
        const id = releaseIdOf(tally.app, tally.versionCode);
        const release = releases[id];
        if (release === undefined) continue;
        const counts = countReport(release, tally);
        transaction.update(store.collection(FRAME_RELEASES).doc(id), {
          attempts: counts.attempts,
          successes: counts.successes,
          rollbacks: counts.rollbacks,
          ...(counts.haltedReason === null
            ? {}
            : {
                paused: true,
                pausedReason: counts.haltedReason,
                updatedAt: FieldValue.serverTimestamp(),
              }),
        });
        if (counts.haltedReason !== null) stopped.push(id);
      }

      const rolledBack = fresh.filter((event) => event.kind === 'rolledBack').length;
      transaction.update(ref, {
        apps: input.apps,
        state: input.state,
        events: [...fresh.map(storedEvent), ...device.events].slice(0, FRAME_UPDATE_LIST_LIMIT),
        counted: countable.counted,
        rollbacks: device.rollbacks + rolledBack,
      });
      return stopped;
    });

    if (halted === null) return UNKNOWN;
    for (const release of halted) logger.warn('frame release halted', { release });
    return OK;
  },
);

function storedEvent(event: FrameUpdateEvent): Record<string, unknown> {
  return {
    id: event.id,
    kind: event.kind,
    app: event.app,
    versionCode: event.versionCode,
    fromVersionCode: event.fromVersionCode,
    detail: event.detail,
    at: Timestamp.fromMillis(event.at),
  };
}
