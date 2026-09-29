import { getStorage } from 'firebase-admin/storage';
import { z } from 'zod';

import { adminApp } from './admin_app';

/**
 * The project's default bucket, through the one admin app. Only documents'
 * shared links read it (documents ADR-0006): everywhere else the app reads
 * Storage itself, under `storage.rules`.
 *
 * The name comes from the `FIREBASE_CONFIG` Cloud Functions provides; the
 * derived `<project>.firebasestorage.app` is the fallback, which is what a
 * project created after October 2024 has and what the emulator accepts.
 */
export function documentsBucket(): ReturnType<ReturnType<typeof getStorage>['bucket']> {
  return getStorage(adminApp()).bucket(defaultBucketName());
}

const configShape = z.object({ storageBucket: z.string().min(1) });

export function defaultBucketName(): string {
  const fromConfig = configShape.safeParse(parseConfig(process.env['FIREBASE_CONFIG']));
  if (fromConfig.success) return fromConfig.data.storageBucket;
  return `${process.env['GCLOUD_PROJECT'] ?? ''}.firebasestorage.app`;
}

function parseConfig(raw: string | undefined): unknown {
  if (raw === undefined || !raw.trim().startsWith('{')) return undefined;
  try {
    return JSON.parse(raw);
  } catch {
    // A malformed config is the platform's, not ours; the derived name is
    // the documented fallback, so this is a decision rather than a loss.
    return undefined;
  }
}
