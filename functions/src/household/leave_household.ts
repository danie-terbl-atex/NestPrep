import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { adminCount, readHousehold, roleOf } from './documents';
import { refuse } from './errors';
import { detachMember, findClaimedMember } from './membership';
import { parseInput, requireUid } from './parse_input';
import { leaveHouseholdInput } from './schemas';

/**
 * Leaving unclaims the profile and drops the caller out of the membership map;
 * the profile itself stays, so the events and todos it owns still say who they
 * were for (household ADR-0001). The last admin is refused — an orphan
 * household nobody can administer is worse than a household somebody is stuck
 * in (household ADR-0002).
 */
export const leaveHousehold = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(leaveHouseholdInput, request.data);
  const store = db();

  await store.runTransaction(async (transaction) => {
    const household = await readHousehold(transaction, store, input.householdId, () =>
      refuse('householdNotFound'),
    );
    const role = roleOf(household, uid);
    if (role === undefined) throw refuse('notAMember');
    if (role === 'admin' && adminCount(household) === 1) throw refuse('lastAdmin');

    const claimedMember = await findClaimedMember(transaction, store, input.householdId, uid);
    detachMember(transaction, store, { householdId: input.householdId, uid, claimedMember });
  });

  logger.info('member left household', { householdId: input.householdId });
  return { householdId: input.householdId };
});
