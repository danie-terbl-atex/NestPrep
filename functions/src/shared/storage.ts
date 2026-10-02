import { getStorage } from 'firebase-admin/storage';

import { adminApp } from './admin_app';

/**
 * The one handle on the default Storage bucket. Account data is its first
 * server-side user: an export is written here and an erased account's bytes
 * are removed from here (accounts ADR-0006).
 *
 * The bucket is named explicitly rather than left to `initializeApp()`,
 * because the emulator's `FIREBASE_CONFIG` does not always carry one; the
 * project's bucket is `<project>.firebasestorage.app` (documents row 6 in the
 * work index — created in `africa-south1`).
 */
export function bucketName(
  env: Readonly<Record<string, string | undefined>> = process.env,
): string {
  const config = env['FIREBASE_CONFIG'];
  if (config !== undefined && config.startsWith('{')) {
    const parsed: unknown = JSON.parse(config);
    if (typeof parsed === 'object' && parsed !== null && 'storageBucket' in parsed) {
      const named = parsed.storageBucket;
      if (typeof named === 'string' && named !== '') return named;
    }
  }
  const project = env['GCLOUD_PROJECT'] ?? env['GCP_PROJECT'] ?? 'nestprep-643b7';
  return `${project}.firebasestorage.app`;
}

/** What Functions do with Storage, behind an interface so erasure is testable (BE-09). */
export interface ObjectStore {
  /** Deletes every object under the prefix; returns nothing, fails loudly. */
  deletePrefix(prefix: string): Promise<void>;
  save(
    path: string,
    contents: string | Uint8Array,
    contentType: string,
    cacheControl?: string,
  ): Promise<void>;
  /** Objects under the prefix created before the instant, up to `limit`. */
  listCreatedBefore(prefix: string, before: Date, limit: number): Promise<string[]>;
  deleteObjects(paths: readonly string[]): Promise<void>;
}

export function objectStore(): ObjectStore {
  const bucket = getStorage(adminApp()).bucket(bucketName());
  return {
    async deletePrefix(prefix: string): Promise<void> {
      await bucket.deleteFiles({ prefix, force: true });
    },
    async save(
      path: string,
      contents: string | Uint8Array,
      contentType: string,
      cacheControl?: string,
    ): Promise<void> {
      await bucket.file(path).save(contents, {
        contentType,
        resumable: false,
        ...(cacheControl === undefined ? {} : { metadata: { cacheControl } }),
      });
    },
    async listCreatedBefore(prefix: string, before: Date, limit: number): Promise<string[]> {
      const [files] = await bucket.getFiles({ prefix, maxResults: limit });
      return files
        .filter((file) => {
          const created = file.metadata.timeCreated;
          return typeof created === 'string' && new Date(created).getTime() < before.getTime();
        })
        .map((file) => file.name);
    },
    async deleteObjects(paths: readonly string[]): Promise<void> {
      // By prefix, which for a full object name is that object: one Storage
      // call shape for every delete here, and none that a scan for Firestore
      // writes outside a transaction mistakes for one (writes_are_atomic).
      await Promise.all(paths.map((path) => bucket.deleteFiles({ prefix: path, force: true })));
    },
  };
}

/**
 * The same bucket, for documents' shared links (documents ADR-0006), which
 * stream a document to somebody with no account.
 */
export function documentsBucket(): ReturnType<ReturnType<typeof getStorage>['bucket']> {
  return getStorage(adminApp()).bucket(bucketName());
}
