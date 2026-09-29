import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pipeline } from 'node:stream/promises';

import { logger } from 'firebase-functions/v2';
import { onRequest, type Request } from 'firebase-functions/v2/https';
import type { Response } from 'express';
import { z } from 'zod';

import { db } from '../../shared/firestore';
import { documentsBucket } from '../../shared/storage';
import { answerShareRequest, type ShareRequest, type SharedFile } from './share_gate';
import { SHARE_PAGE_CSP, renderSharePage, sharePageStatus, type SharePage } from './share_page';
import { contentDispositionFor } from './shared_file';

/**
 * A shared link, opened (documents ADR-0006) — the transport only: parse the
 * request, ask `answerShareRequest`, send back a page or stream the file. No
 * Storage URL of any kind is ever made; the bytes pass through here after
 * every check has run again.
 *
 * Its timeout is longer than a callable's because it streams up to 20 MiB to
 * a phone that may be on a slow connection (`BE-19`).
 */
export const documentShare = onRequest({ timeoutSeconds: 120 }, async (req, res) => {
  securityHeaders(res);
  if (req.method !== 'GET' && req.method !== 'POST') {
    res.status(405).send('Method not allowed');
    return;
  }
  if (req.method === 'GET' && queryString(req, 'asset') === 'mark') {
    await sendMark(res);
    return;
  }
  const outcome = await answerShareRequest(db(), parseRequest(req), objectExists);
  if (outcome.kind === 'page') {
    sendPage(res, outcome.page);
    return;
  }
  await streamFile(res, outcome.file);
});

const formShape = z.object({ pin: z.string().max(16) });

function parseRequest(req: Request): ShareRequest {
  const form = req.method === 'POST' ? formShape.safeParse(req.body) : null;
  return {
    token: queryString(req, 't') ?? '',
    wantsFile: queryString(req, 'file') === '1',
    pass: queryString(req, 'p'),
    pin: form?.success === true ? form.data.pin : req.method === 'POST' ? '' : null,
  };
}

function queryString(req: Request, name: string): string | null {
  const value = req.query[name];
  return typeof value === 'string' ? value : null;
}

function securityHeaders(res: Response): void {
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('X-Robots-Tag', 'noindex, nofollow');
  res.setHeader('Referrer-Policy', 'no-referrer');
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
}

function sendPage(res: Response, page: SharePage): void {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Content-Security-Policy', SHARE_PAGE_CSP);
  res.status(sharePageStatus(page)).send(renderSharePage(page));
}

async function objectExists(path: string): Promise<boolean> {
  const [exists] = await documentsBucket().file(path).exists();
  return exists;
}

async function streamFile(res: Response, file: SharedFile): Promise<void> {
  res.setHeader('Content-Type', file.contentType);
  res.setHeader('Content-Disposition', contentDispositionFor(file.documentName, file.contentType));
  res.status(200);
  try {
    await pipeline(documentsBucket().file(file.objectPath).createReadStream(), res);
  } catch (error) {
    // The open is already logged and the headers are gone; all that is left
    // is to say so where somebody will see it and end the response.
    logger.error('document share stream failed', { error: String(error) });
    res.destroy();
  }
}

/** The nest, 192 px, read once per instance (`tools/brand/share_page_mark.sh`). */
let mark: Buffer | undefined;

export const MARK_PATH = resolve(__dirname, '../../../assets/share/nest_mark.png');

async function sendMark(res: Response): Promise<void> {
  mark ??= await readFile(MARK_PATH);
  res.setHeader('Content-Type', 'image/png');
  res.setHeader('Cache-Control', 'public, max-age=86400');
  res.status(200).send(mark);
}
