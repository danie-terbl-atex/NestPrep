import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { refuse } from './errors';
import { type MemberDocument, inviteRef, memberRef, readHousehold, roleOf } from './documents';
import { INVITE_LIFETIME_MS, generateInviteCode } from './invite_code';
import { parseInput, requireUid } from './parse_input';
import { createInviteInput } from './schemas';

/**
 * An admin creates a single-use, seven-day code for one unclaimed profile
 * (household ADR-0002). Invites live at the top level so redeeming one does not
 * need to know the household first, and no client can read the collection at
 * all — only this Function and its redeemer touch it.
 */
export const createInvite = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(createInviteInput, request.data);
  const store = db();

  const code = generateInviteCode();
  const expiresAt = Timestamp.fromMillis(Date.now() + INVITE_LIFETIME_MS);

  await store.runTransaction(async (transaction) => {
    const household = await readHousehold(transaction, store, input.householdId, () =>
      refuse('householdNotFound'),
    );
    if (roleOf(household, uid) !== 'admin') throw refuse('notAnAdmin');

    const member = memberRef(store, input.householdId, input.memberId);
    const snapshot = await transaction.get(member);
    const data = snapshot.data() as MemberDocument | undefined;
    if (!snapshot.exists || data === undefined) throw refuse('memberNotFound');
    if (data.claimedBy !== null) throw refuse('memberAlreadyClaimed');

    transaction.set(inviteRef(store, code), {
      householdId: input.householdId,
      memberId: input.memberId,
      createdBy: uid,
      createdAt: FieldValue.serverTimestamp(),
      expiresAt,
      redeemedBy: null,
      redeemedAt: null,
    });
  });

  logger.info('invite created', { householdId: input.householdId });
  return { code, expiresAt: expiresAt.toDate().toISOString() };
});
