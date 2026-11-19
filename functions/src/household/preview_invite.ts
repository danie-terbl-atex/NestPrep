import type { Timestamp } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';

import { clientAddress } from '../shared/client_address';
import { db } from '../shared/firestore';
import { consumeRateLimit } from '../shared/rate_limit';
import {
  type HouseholdDocument,
  type InviteDocument,
  type MemberDocument,
  MEMBERS,
  householdRef,
  inviteRef,
  memberRef,
  roleOf,
} from './documents';
import { refuse } from './errors';
import {
  INVITE_PREVIEW_OVERALL,
  INVITE_PREVIEW_PER_ADDRESS,
  looksLikeInviteCode,
} from './invite_code';
import { parseInput, requireUid } from './parse_input';
import { previewInviteInput } from './schemas';

/**
 * What an invite link offers before anybody accepts it (household ADR-0005):
 * the household's name, the profile the code was made for and who sent it.
 * Refuses exactly as `redeemInvite` would, and writes nothing but a count.
 *
 * Answers a caller who has not signed in yet, so the invite way in can say
 * whose family it is before an account exists (household ADR-0011). That
 * caller is counted first, per address and overall, well-formed code or not;
 * a signed-in caller still goes through `requireUid`, which refuses a kid.
 */
export const previewInvite = onCall(async (request) => {
  const uid = request.auth === undefined ? null : requireUid(request.auth);
  const { code } = parseInput(previewInviteInput, request.data);
  const store = db();
  if (uid === null) {
    const allowed =
      (await consumeRateLimit(store, INVITE_PREVIEW_OVERALL, 'all')) &&
      (await consumeRateLimit(
        store,
        INVITE_PREVIEW_PER_ADDRESS,
        clientAddress(request.rawRequest),
      ));
    if (!allowed) throw refuse('tooManyAttempts');
  }
  if (!looksLikeInviteCode(code)) throw refuse('inviteNotFound');

  const inviteSnapshot = await inviteRef(store, code).get();
  const invite = inviteSnapshot.data() as InviteDocument | undefined;
  if (!inviteSnapshot.exists || invite === undefined) throw refuse('inviteNotFound');
  if (invite.redeemedBy !== null) throw refuse('inviteAlreadyUsed');
  const expiresAt = inviteSnapshot.get('expiresAt') as Timestamp | undefined;
  if (expiresAt === undefined || expiresAt.toMillis() <= Date.now()) throw refuse('inviteExpired');

  const [householdSnapshot, memberSnapshot, inviterSnapshot] = await Promise.all([
    householdRef(store, invite.householdId).get(),
    memberRef(store, invite.householdId, invite.memberId).get(),
    householdRef(store, invite.householdId)
      .collection(MEMBERS)
      .where('claimedBy', '==', invite.createdBy)
      .limit(1)
      .get(),
  ]);
  const household = householdSnapshot.data() as HouseholdDocument | undefined;
  if (household === undefined) throw refuse('householdNotFound');
  if (uid !== null && roleOf(household, uid) !== undefined) throw refuse('alreadyInHousehold');
  const member = memberSnapshot.data() as MemberDocument | undefined;
  if (member === undefined) throw refuse('memberNotFound');
  if (member.claimedBy !== null) throw refuse('memberAlreadyClaimed');

  const inviter = inviterSnapshot.docs[0]?.data() as MemberDocument | undefined;
  return {
    householdName: household.name,
    memberName: member.displayName,
    role: member.role === 'member' ? 'parent' : member.role,
    invitedBy: inviter?.displayName ?? null,
    expiresAt: expiresAt.toDate().toISOString(),
  };
});
