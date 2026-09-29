import type { RateLimitRule } from '../shared/rate_limit';
import type { ObjectStore } from '../shared/storage';
import { exportObjectPrefix } from './personal_refs';

/**
 * How long an export can be read after it is written. The Storage rule
 * enforces the same hour from the object's creation time; keep the two
 * equal (`test/unit/account_data_exports.test.ts` reads both).
 */
export const EXPORT_LIFETIME_MS = 60 * 60 * 1000;

/** Three exports an hour per account: each reads every household the person is in. */
export const EXPORT_RATE_LIMIT: RateLimitRule = {
  name: 'exportAccountData',
  limit: 3,
  windowSeconds: 60 * 60,
};

/** The most exports one sweep removes; the next run takes the rest (`BE-15`). */
export const EXPORT_SWEEP_LIMIT = 500;

export const EXPORTS_PREFIX = 'accountExports/';

export function exportPath(uid: string, exportId: string): string {
  return `${exportObjectPrefix(uid)}${exportId}.json`;
}

/**
 * Removes every export past its hour. The rules already refuse to serve one;
 * this makes sure the bytes do not outlive the link (accounts ADR-0006).
 * Idempotent and bounded, so it is safe to run late or twice.
 */
export async function sweepExpiredExports(objects: ObjectStore, now: Date): Promise<number> {
  const expired = await objects.listCreatedBefore(
    EXPORTS_PREFIX,
    new Date(now.getTime() - EXPORT_LIFETIME_MS),
    EXPORT_SWEEP_LIMIT,
  );
  await objects.deleteObjects(expired);
  return expired.length;
}
