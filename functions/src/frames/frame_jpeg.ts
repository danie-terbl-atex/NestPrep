import { HttpsError, onRequest } from 'firebase-functions/v2/https';

import type { RateLimitRule } from '../shared/rate_limit';
import { db } from '../shared/firestore';
import { documentsBucket } from '../shared/storage';
import { type LinkedFrame, readLinkedFrame } from './frame_access';
import { answer, isPost, securityHeaders, sendFile, storedAs } from './frame_http';
import { getFramePhotoInput } from './frame_schemas';

/**
 * A JPEG's bytes for a linked frame, streamed through here after its secret is
 * checked, so nothing a frame shows has a URL (photo-frames ADR-0006). A plain
 * POST of `{secret, id}` rather than a callable, because a callable answers in
 * JSON. [locate] turns the id into a Storage path this frame may read, or null.
 */
export function frameJpegEndpoint(
  rule: RateLimitRule,
  locate: (linked: LinkedFrame, id: string) => Promise<string | null> | string | null,
): ReturnType<typeof onRequest> {
  return onRequest({ timeoutSeconds: 60 }, async (req, res) => {
    securityHeaders(res);
    if (!isPost(req, res)) return;
    const body = getFramePhotoInput.safeParse(req.body);
    if (!body.success) {
      answer(res, 400, 'invalid');
      return;
    }
    const linked = await linkedOrRefused(body.data.secret, rule);
    if (linked === 'tooManyAttempts') {
      answer(res, 429, 'tooManyAttempts');
      return;
    }
    if (linked === null) {
      answer(res, 410, 'unlinked');
      return;
    }
    const path = await locate(linked, body.data.id);
    const file = path === null ? null : documentsBucket().file(path);
    const photo = file === null ? null : await storedAs(file, 'image/jpeg');
    if (file === null || photo === null) {
      answer(res, 404, 'missing');
      return;
    }
    await sendFile(res, file, { contentType: 'image/jpeg', size: photo.size });
  });
}

async function linkedOrRefused(
  secret: string,
  rule: RateLimitRule,
): Promise<LinkedFrame | null | 'tooManyAttempts'> {
  try {
    return await readLinkedFrame(db(), secret, rule);
  } catch (error) {
    if (error instanceof HttpsError && error.code === 'resource-exhausted') {
      return 'tooManyAttempts';
    }
    throw error;
  }
}
