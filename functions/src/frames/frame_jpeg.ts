import { pipeline } from 'node:stream/promises';

import { logger } from 'firebase-functions/v2';
import { HttpsError, onRequest } from 'firebase-functions/v2/https';
import type { Response } from 'express';

import type { RateLimitRule } from '../shared/rate_limit';
import { db } from '../shared/firestore';
import { documentsBucket } from '../shared/storage';
import { type LinkedFrame, readLinkedFrame } from './frame_access';
import { getFramePhotoInput } from './frame_schemas';

type Answer = 'invalid' | 'unlinked' | 'tooManyAttempts' | 'missing';

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
    if (req.method !== 'POST') {
      res.setHeader('Allow', 'POST');
      res.status(405).send('Method not allowed');
      return;
    }
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
    const photo = file === null ? null : await jpegAt(file);
    if (file === null || photo === null) {
      answer(res, 404, 'missing');
      return;
    }
    res.setHeader('Content-Type', 'image/jpeg');
    if (photo.size !== undefined) res.setHeader('Content-Length', String(photo.size));
    res.status(200);
    try {
      await pipeline(file.createReadStream(), res);
    } catch (error) {
      logger.error('frame photo stream failed', { error: String(error) });
      res.destroy();
    }
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

type BucketFile = ReturnType<ReturnType<typeof documentsBucket>['file']>;

async function jpegAt(
  file: BucketFile,
): Promise<{ readonly size: string | number | undefined } | null> {
  const [found] = await file.exists();
  if (!found) return null;
  const [metadata] = await file.getMetadata();
  return metadata.contentType === 'image/jpeg' ? { size: metadata.size } : null;
}

function answer(res: Response, status: number, said: Answer): void {
  res.status(status).json({ status: said });
}

function securityHeaders(res: Response): void {
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('X-Robots-Tag', 'noindex, nofollow');
  res.setHeader('Referrer-Policy', 'no-referrer');
  res.setHeader('X-Content-Type-Options', 'nosniff');
}
