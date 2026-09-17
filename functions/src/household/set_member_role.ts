import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { adminCount, householdRef, memberRef, readHousehold, roleOf } from './documents';
import { refuse } from './errors';
import { readMember } from './membership';
import { parseInput, requireUid } from './parse_input';
import { setMemberRoleInput } from './schemas';

/**
 * Changing a **claimed** member's role has to move two documents at once — the
 * profile and the household's uid→role map that every rule reads — so it is a
 * Function, not a client write (foundation ADR-0002). An unclaimed profile has
 * no map entry, so the rules let an admin change its role directly.
 *
 * This is what makes the last-admin refusal survivable: promote somebody, then
 * leave (household phase 1).
 */
export const setMemberRole = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(setMemberRoleInput, request.data);
  const store = db();

  await store.runTransaction(async (transaction) => {
    const household = await readHousehold(transaction, store, input.householdId, () =>
      refuse('householdNotFound'),
    );
    if (roleOf(household, uid) !== 'admin') throw refuse('notAnAdmin');

    const member = await readMember(transaction, store, input.householdId, input.memberId);
    if (member === undefined) throw refuse('memberNotFound');

    // Demoting the only admin would leave nobody able to promote anyone.
    if (member.role === 'admin' && input.role !== 'admin' && adminCount(household) === 1) {
      throw refuse('lastAdmin');
    }

    transaction.update(memberRef(store, input.householdId, input.memberId), {
      role: input.role,
    });
    if (member.claimedBy !== null) {
      transaction.update(householdRef(store, input.householdId), {
        [`members.${member.claimedBy}`]: input.role,
      });
    }
  });

  logger.info('member role changed', { householdId: input.householdId, role: input.role });
  return { householdId: input.householdId };
});
