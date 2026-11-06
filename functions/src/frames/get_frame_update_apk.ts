import { type DocumentReference, type Firestore, Timestamp } from 'firebase-admin/firestore';
import { onRequest } from 'firebase-functions/v2/https';

import { db } from '../shared/firestore';
import { consumeRateLimit } from '../shared/rate_limit';
import { documentsBucket } from '../shared/storage';
import { secretHash } from './frame_documents';
import { answer, isPost, securityHeaders, sendFile, storedAs } from './frame_http';
import { getFrameUpdateApkInput } from './frame_schemas';
import {
  frameDeviceDocument,
  frameDeviceRef,
  frameReleaseRef,
  parsedRelease,
} from './frame_update_documents';
import {
  FRAME_APK_CONTENT_TYPE,
  FRAME_UPDATE_APK_PER_DEVICE,
  isVisibleTo,
  resumeOffset,
  withFetched,
} from './frame_update_policy';

/**
 * A release's APK for a registered device, resumable from a byte offset. Any
 * release in a stage the device can see is served, paused or not, so a
 * download in flight survives a pause.
 */
export const getFrameUpdateApk = onRequest({ timeoutSeconds: 300 }, async (req, res) => {
  securityHeaders(res);
  if (!isPost(req, res)) return;
  const body = getFrameUpdateApkInput.safeParse(req.body);
  if (!body.success) {
    answer(res, 400, 'invalid');
    return;
  }
  const { app, versionCode } = body.data;
  const store = db();
  const deviceId = secretHash(body.data.device);
  const deviceRef = frameDeviceRef(store, deviceId);
  const snapshot = await deviceRef.get();
  if (!snapshot.exists) {
    answer(res, 410, 'unknownDevice');
    return;
  }
  if (!(await consumeRateLimit(store, FRAME_UPDATE_APK_PER_DEVICE, deviceId))) {
    answer(res, 429, 'tooManyAttempts');
    return;
  }

  const device = frameDeviceDocument.parse(snapshot.data());
  const releaseRef = frameReleaseRef(store, app, versionCode);
  const release = parsedRelease(releaseRef.id, (await releaseRef.get()).data());
  const servable = release !== null && isVisibleTo(release, { deviceId, ring: device.ring });
  const file = servable ? documentsBucket().file(release.storagePath) : null;
  const apk = file === null ? null : await storedAs(file, FRAME_APK_CONTENT_TYPE);
  if (file === null || apk === null || apk.size === null) {
    answer(res, 404, 'missing');
    return;
  }

  await recordFetched(store, deviceRef, releaseRef.id);
  const size = apk.size;
  res.setHeader('Accept-Ranges', 'bytes');
  const start = resumeOffset(req.headers.range, size);
  if (start === null) {
    await sendFile(res, file, { contentType: FRAME_APK_CONTENT_TYPE, size });
    return;
  }
  res.setHeader('Content-Range', `bytes ${String(start)}-${String(size - 1)}/${String(size)}`);
  await sendFile(res, file, { contentType: FRAME_APK_CONTENT_TYPE, size, status: 206, start });
});

async function recordFetched(
  store: Firestore,
  ref: DocumentReference,
  releaseId: string,
): Promise<void> {
  await store.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) return;
    const { fetched } = frameDeviceDocument.parse(snapshot.data());
    const millis = Object.fromEntries(
      Object.entries(fetched).map(([id, at]) => [id, at.toMillis()]),
    );
    const newest = withFetched(millis, releaseId, Date.now());
    transaction.update(ref, {
      fetched: Object.fromEntries(
        Object.entries(newest).map(([id, at]) => [id, Timestamp.fromMillis(at)]),
      ),
    });
  });
}
