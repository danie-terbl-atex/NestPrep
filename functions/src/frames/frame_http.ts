import { pipeline } from 'node:stream/promises';

import { logger } from 'firebase-functions/v2';
import type { Request, Response } from 'express';

import type { documentsBucket } from '../shared/storage';

export type BucketFile = ReturnType<ReturnType<typeof documentsBucket>['file']>;

export interface StoredFile {
  readonly size: number | null;
}

export async function storedAs(file: BucketFile, contentType: string): Promise<StoredFile | null> {
  const [found] = await file.exists();
  if (!found) return null;
  const [metadata] = await file.getMetadata();
  if (metadata.contentType !== contentType) return null;
  return { size: metadata.size === undefined ? null : Number(metadata.size) };
}

export interface Sending {
  readonly contentType: string;
  readonly size: number | null;
  readonly status?: number;
  readonly start?: number;
}

export async function sendFile(
  res: Response,
  file: BucketFile,
  { contentType, size, status = 200, start = 0 }: Sending,
): Promise<void> {
  res.setHeader('Content-Type', contentType);
  if (size !== null) res.setHeader('Content-Length', String(size - start));
  res.status(status);
  try {
    await pipeline(file.createReadStream(start === 0 ? {} : { start }), res);
  } catch (error) {
    if (isClientGone(error)) logger.info('frame file stream ended by the client');
    else logger.error('frame file stream failed', { error: String(error) });
    res.destroy();
  }
}

const CLIENT_GONE = ['ERR_STREAM_PREMATURE_CLOSE', 'ECONNRESET', 'EPIPE'];

export function isClientGone(error: unknown): boolean {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    typeof error.code === 'string' &&
    CLIENT_GONE.includes(error.code)
  );
}

/** False, with the 405 already sent, for anything but a POST. */
export function isPost(req: Request, res: Response): boolean {
  if (req.method === 'POST') return true;
  res.setHeader('Allow', 'POST');
  res.status(405).send('Method not allowed');
  return false;
}

export function answer(res: Response, status: number, said: string): void {
  res.status(status).json({ status: said });
}

export function securityHeaders(res: Response): void {
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('X-Robots-Tag', 'noindex, nofollow');
  res.setHeader('Referrer-Policy', 'no-referrer');
  res.setHeader('X-Content-Type-Options', 'nosniff');
}
