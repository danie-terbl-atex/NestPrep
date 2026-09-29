import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { isRestrictedRole } from './access';
import { pushAccountClaims } from './access_claim';
import { memberRef, readHousehold, roleOf } from './documents';
import { refuse } from './errors';
import { readMember, recordClaim } from './membership';
import { parseInput, requireUid } from './parse_input';
import { setMemberAccessInput } from './schemas';

/**
 * A parent chooses what a kid, helper or carer may see and do, area by area
 * (household ADR-0003).
 *
 * It is a Function because a claimed member's grant lives in two places — the
 * profile, which holds the parent's choice, and the household document, which
 * is what every rule reads — and one client write cannot touch both
 * (foundation ADR-0002). An unclaimed profile has only the first, but goes
 * through here too, so there is one way to change a grant and not two.
 *
 * A family member is refused: they see everything, and a grant on them would
 * be a promise the rules do not keep. After the change the affected account's
 * token is brought up to date, so Storage agrees with Firestore as soon as it
 * refreshes rather than within the hour.
 */
export const setMemberAccess = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(setMemberAccessInput, request.data);
  const store = db();

  const claimedBy = await store.runTransaction(async (transaction) => {
    const household = await readHousehold(transaction, store, input.householdId, () =>
      refuse('householdNotFound'),
    );
    if (roleOf(household, uid) !== 'admin') throw refuse('notAnAdmin');

    const member = await readMember(transaction, store, input.householdId, input.memberId);
    if (member === undefined) throw refuse('memberNotFound');
    if (!isRestrictedRole(member.role)) throw refuse('familyHasFullAccess');

    transaction.update(memberRef(store, input.householdId, input.memberId), {
      access: input.access,
    });
    if (member.claimedBy !== null) {
      recordClaim(transaction, store, {
        householdId: input.householdId,
        uid: member.claimedBy,
        memberId: input.memberId,
        role: member.role,
        access: input.access,
      });
    }
    return member.claimedBy;
  });

  const tokenUpdated = claimedBy === null ? true : await pushAccountClaims(store, claimedBy);
  logger.info('member access changed', { householdId: input.householdId });
  return { householdId: input.householdId, tokenUpdated };
});
