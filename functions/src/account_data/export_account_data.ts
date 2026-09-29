import { randomUUID } from 'node:crypto';

import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { consumeRateLimit } from '../shared/rate_limit';
import { objectStore } from '../shared/storage';
import { accountAuth } from './account_auth';
import { EXPORT_OPTIONS } from './account_data_options';
import { refuseAccountData } from './errors';
import { EXPORT_RATE_LIMIT, EXPORT_LIFETIME_MS, exportPath } from './export_files';
import { assembleExport } from './personal_data_export';
import { exportObjectPrefix } from './personal_refs';

/**
 * Downloads everything NestPrep holds about the caller (accounts ADR-0006 —
 * POPIA's right of access). The export is written to Storage under the
 * caller's own prefix, readable by that account alone and only for an hour
 * (`rules/storage/paths/account_exports.rules`); the app fetches it straight
 * away and hands it to the phone's share sheet. Any earlier export is removed
 * first, so there is only ever one.
 *
 * It takes no body — the subject is the caller — and at most three an hour,
 * because each one reads the whole of somebody's households.
 */
export const exportAccountData = onCall(EXPORT_OPTIONS, async (request) => {
  const uid = requireUid(request.auth);
  const store = db();
  const now = new Date();
  if (!(await consumeRateLimit(store, EXPORT_RATE_LIMIT, uid, now))) {
    throw refuseAccountData('tooManyRequests');
  }

  const exported = await assembleExport(store, {
    uid,
    auth: await accountAuth().describe(uid),
    now,
  });
  const objects = objectStore();
  const path = exportPath(uid, randomUUID());
  await objects.deletePrefix(exportObjectPrefix(uid));
  await objects.save(path, JSON.stringify(exported.body, null, 2), 'application/json');

  logger.info('account data exported', { files: exported.files.length });
  return {
    path,
    expiresAt: new Date(now.getTime() + EXPORT_LIFETIME_MS).toISOString(),
    fileCount: exported.files.length,
  };
});
