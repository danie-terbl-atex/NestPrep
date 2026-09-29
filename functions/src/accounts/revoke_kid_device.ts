import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { readHousehold, roleOf } from '../household/documents';
import { refuse } from '../household/errors';
import { parseInput, requireUid } from '../household/parse_input';
import { kidAuthAccounts } from './kid_auth_accounts';
import { deviceRef } from './kid_documents';
import { detachKidDevices } from './kid_devices';
import { refuseKid } from './kid_errors';
import { revokeKidDeviceInput } from './kid_schemas';

/**
 * An admin signs one kid device out — the lost tablet, and not the phone
 * (accounts ADR-0003).
 *
 * The household stops trusting it in the transaction: from that commit, the
 * rules refuse every read it makes. Its Auth session and user go after, so the
 * next token refresh fails as well.
 */
export const revokeKidDevice = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(revokeKidDeviceInput, request.data);
  const store = db();

  await store.runTransaction(async (transaction) => {
    const household = await readHousehold(transaction, store, input.householdId, () =>
      refuse('householdNotFound'),
    );
    if (roleOf(household, uid) !== 'admin') throw refuse('notAnAdmin');

    const device = await transaction.get(deviceRef(store, input.householdId, input.deviceUid));
    if (!device.exists) throw refuseKid('deviceNotFound');

    detachKidDevices(transaction, store, input.householdId, [input.deviceUid]);
  });

  await kidAuthAccounts().close([input.deviceUid]);

  logger.info('kid device revoked', { householdId: input.householdId });
  return { revoked: 1 };
});
