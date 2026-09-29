import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import {
  type InviteDocument,
  type MemberDocument,
  householdRef,
  inviteRef,
  memberRef,
  readHousehold,
  roleOf,
  userRef,
} from './documents';
import { refuse } from './errors';
import { looksLikeInviteCode } from './invite_code';
import { parseInput, requireVerifiedUid } from './parse_input';
import { redeemInviteInput } from './schemas';

/**
 * The one call that turns a code into membership, in one transaction: the
 * profile is claimed, the household's uid→role map gains the caller, the
 * account's household list gains the household, and the invite is spent
 * (household ADR-0002). Any refusal leaves nothing half-done (BE-07).
 */
export const redeemInvite = onCall(async (request) => {
  const uid = requireVerifiedUid(request.auth);
  const { code } = parseInput(redeemInviteInput, request.data);
  const store = db();

  // A code that could never have been ours is refused without a read, so
  // guessing costs the guesser and not us.
  if (!looksLikeInviteCode(code)) throw refuse('inviteNotFound');

  const result = await store.runTransaction(async (transaction) => {
    const invite = inviteRef(store, code);
    const inviteSnapshot = await transaction.get(invite);
    const inviteData = inviteSnapshot.data() as InviteDocument | undefined;
    if (!inviteSnapshot.exists || inviteData === undefined) {
      throw refuse('inviteNotFound');
    }
    if (inviteData.redeemedBy !== null) throw refuse('inviteAlreadyUsed');

    const expiresAt = inviteSnapshot.get('expiresAt') as Timestamp | undefined;
    if (expiresAt === undefined || expiresAt.toMillis() <= Date.now()) {
      throw refuse('inviteExpired');
    }

    const household = await readHousehold(transaction, store, inviteData.householdId, () =>
      refuse('householdNotFound'),
    );
    // One account holds at most one profile per household (household ADR-0001).
    if (roleOf(household, uid) !== undefined) throw refuse('alreadyInHousehold');

    const member = memberRef(store, inviteData.householdId, inviteData.memberId);
    const memberSnapshot = await transaction.get(member);
    const memberData = memberSnapshot.data() as MemberDocument | undefined;
    if (!memberSnapshot.exists || memberData === undefined) {
      throw refuse('memberNotFound');
    }
    if (memberData.claimedBy !== null) throw refuse('memberAlreadyClaimed');

    transaction.update(member, { claimedBy: uid });
    transaction.update(householdRef(store, inviteData.householdId), {
      [`members.${uid}`]: memberData.role,
    });
    transaction.set(
      userRef(store, uid),
      {
        householdIds: FieldValue.arrayUnion(inviteData.householdId),
        activeHouseholdId: inviteData.householdId,
      },
      { merge: true },
    );
    transaction.update(invite, {
      redeemedBy: uid,
      redeemedAt: FieldValue.serverTimestamp(),
    });

    return { householdId: inviteData.householdId, memberId: inviteData.memberId };
  });

  logger.info('invite redeemed', { householdId: result.householdId });
  return result;
});
