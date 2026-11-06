import { type DocumentReference, FieldValue, type Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { parseInput } from '../household/parse_input';
import { clientAddress } from '../shared/client_address';
import { db } from '../shared/firestore';
import { consumeRateLimit } from '../shared/rate_limit';
import { type LinkedFrame, readLinkedFrame } from './frame_access';
import { secretHash } from './frame_documents';
import { refuseFrame } from './frame_errors';
import { FRAME_DEVICE_OPTIONS } from './frame_policy';
import { type CheckFrameUpdateInput, checkFrameUpdateInput } from './frame_schemas';
import {
  FRAME_RELEASES,
  type FrameDeviceDocument,
  type FrameRelease,
  frameDeviceDocument,
  frameDeviceRef,
  parsedRelease,
} from './frame_update_documents';
import {
  FRAME_NEW_DEVICE_OVERALL,
  FRAME_NEW_DEVICE_PER_ADDRESS,
  FRAME_UPDATE_CHECK_PER_CREDENTIAL,
  FRAME_UPDATE_CHECK_PER_DEVICE,
  type FrameUpdateApp,
  type InstallWindow,
  checkAfterSeconds,
  installWindow,
  offerFor,
  visibleStages,
} from './frame_update_policy';

export interface FrameUpdateOffer {
  readonly versionCode: number;
  readonly versionName: string;
  readonly size: number;
  readonly sha256: string;
}

export interface CheckFrameUpdateResult {
  readonly checkAfterSeconds: number;
  readonly window: InstallWindow;
  readonly home: FrameUpdateOffer | null;
  readonly agent: FrameUpdateOffer | null;
}

export const checkFrameUpdate = onCall(
  FRAME_DEVICE_OPTIONS,
  async (request): Promise<CheckFrameUpdateResult> => {
    const input = parseInput(checkFrameUpdateInput, request.data);
    const store = db();
    const deviceId = secretHash(input.device);
    const ref = frameDeviceRef(store, deviceId);

    if (!(await ref.get()).exists) {
      const allowed =
        (await consumeRateLimit(
          store,
          FRAME_NEW_DEVICE_PER_ADDRESS,
          clientAddress(request.rawRequest),
        )) && (await consumeRateLimit(store, FRAME_NEW_DEVICE_OVERALL, 'all'));
      if (!allowed) throw refuseFrame('tooManyAttempts');
    }
    if (!(await consumeRateLimit(store, FRAME_UPDATE_CHECK_PER_DEVICE, deviceId))) {
      throw refuseFrame('tooManyAttempts');
    }

    const linked =
      input.frame === null
        ? null
        : await readLinkedFrame(store, input.frame, FRAME_UPDATE_CHECK_PER_CREDENTIAL);
    const device = await recordCheck(store, ref, input, linked);
    const now = new Date();
    const installNowUntil = device.installNowUntil?.toDate() ?? null;
    const releases = await releasesVisibleTo(store, deviceId, device);
    const offered = (app: FrameUpdateApp): FrameUpdateOffer | null =>
      offerOf(
        offerFor(app, releases, {
          deviceId,
          ring: device.ring,
          sdk: input.sdk,
          installed: input.apps[app]?.versionCode ?? null,
          bad: input.bad[app],
        }),
      );

    return {
      checkAfterSeconds: checkAfterSeconds(now, installNowUntil),
      window: installWindow({
        now,
        installNowUntil,
        linked: linked !== null,
        timeZone: linked?.timeZone ?? null,
      }),
      home: offered('home'),
      agent: offered('agent'),
    };
  },
);

async function recordCheck(
  store: Firestore,
  ref: DocumentReference,
  input: CheckFrameUpdateInput,
  linked: LinkedFrame | null,
): Promise<FrameDeviceDocument> {
  const seen = {
    lastCheckAt: FieldValue.serverTimestamp(),
    model: input.model,
    sdk: input.sdk,
    apps: input.apps,
    bad: input.bad,
    state: input.state,
    frame: linked === null ? null : { householdId: linked.home.id, frameId: linked.frameId },
    frameName: linked?.frame.name ?? null,
    householdName: linked?.householdName ?? null,
  };
  const outcome = await store.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (snapshot.exists) {
      transaction.update(ref, seen);
      return { created: false, device: frameDeviceDocument.parse(snapshot.data()) };
    }
    transaction.create(ref, {
      ...seen,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      ring: 'standard',
      installNowUntil: null,
      rollbacks: 0,
      events: [],
    });
    return { created: true, device: frameDeviceDocument.parse({}) };
  });
  if (outcome.created) logger.info('frame update device registered');
  return outcome.device;
}

async function releasesVisibleTo(
  store: Firestore,
  deviceId: string,
  device: FrameDeviceDocument,
): Promise<FrameRelease[]> {
  const snapshot = await store
    .collection(FRAME_RELEASES)
    .where('stage', 'in', [...visibleStages(deviceId, device.ring)])
    .get();
  return snapshot.docs.flatMap((doc) => parsedRelease(doc.id, doc.data()) ?? []);
}

function offerOf(release: FrameRelease | null): FrameUpdateOffer | null {
  if (release === null) return null;
  const { versionCode, versionName, size, sha256 } = release;
  return { versionCode, versionName, size, sha256 };
}
