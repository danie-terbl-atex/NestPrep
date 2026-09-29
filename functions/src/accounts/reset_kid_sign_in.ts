import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { readHousehold, roleOf } from '../household/documents';
import { refuse } from '../household/errors';
import { parseInput, requireUid } from '../household/parse_input';
import { kidAuthAccounts } from './kid_auth_accounts';
import { pairingsFor } from './kid_documents';
import { detachKidDevices, readKidDeviceUids } from './kid_devices';
import { resetKidSignInInput } from './kid_schemas';

/**
 * An admin starts a kid's sign-in over: every device signed in as the profile
 * is signed out, and any code still waiting is retired (accounts ADR-0003).
 *
 * It refuses nothing about the profile itself. A profile with no devices is
 * already reset, and one that has since been removed has had its devices
 * signed out by `removeMember` — so this is safe to call twice and late.
 */
export const resetKidSignIn = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(resetKidSignInInput, request.data);
  const store = db();

  const revoked = await store.runTransaction(async (transaction) => {
    const household = await readHousehold(transaction, store, input.householdId, () =>
      refuse('householdNotFound'),
    );
    if (roleOf(household, uid) !== 'admin') throw refuse('notAnAdmin');

    const devices = await readKidDeviceUids(transaction, store, input.householdId, input.memberId);
    const pairings = await transaction.get(pairingsFor(store, input.householdId, input.memberId));

    for (const pairing of pairings.docs) transaction.delete(pairing.ref);
    detachKidDevices(transaction, store, input.householdId, devices);
    return devices;
  });

  await kidAuthAccounts().close(revoked);

  logger.info('kid sign-in reset', { householdId: input.householdId, devices: revoked.length });
  return { revoked: revoked.length };
});
