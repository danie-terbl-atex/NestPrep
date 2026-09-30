import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { INVITE_LIFETIME_MS, generateInviteCode } from '../household/invite_code';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { isAlreadyLinked, readKidProfile, sharedChildName } from './child_profiles';
import { requireRole } from './coparent_caller';
import { coParentInviteRef } from './coparent_refs';
import { refuseCoParent } from './errors';
import { createCoParentInviteInput } from './schemas';

/**
 * An admin makes a code that offers one of their kids to another home, with
 * the name and colour they chose for their own home and the schedule they
 * propose (household ADR-0004). It is the household invite's code — eight
 * readable characters, one use, seven days — in a collection no client can
 * read, because a readable list of codes is a list of ways into a child's week.
 *
 * Making the code is this home's half of "both admins accept"; the other
 * home's admin accepts it, and this home's admin confirms.
 */
export const createCoParentInvite = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(createCoParentInviteInput, request.data);
  const store = db();

  const code = generateInviteCode();
  const expiresAt = Timestamp.fromMillis(Date.now() + INVITE_LIFETIME_MS);

  await store.runTransaction(async (transaction) => {
    await requireRole(transaction, store, input.householdId, uid, 'admin');
    const displayName = await readKidProfile(
      transaction,
      store,
      input.householdId,
      input.childMemberId,
    );
    if (await isAlreadyLinked(transaction, store, input.householdId, input.childMemberId)) {
      throw refuseCoParent('childAlreadyLinked');
    }
    transaction.set(coParentInviteRef(store, code), {
      householdId: input.householdId,
      childMemberId: input.childMemberId,
      childName: sharedChildName(displayName),
      home: input.home,
      schedule: input.schedule,
      createdBy: uid,
      createdAt: FieldValue.serverTimestamp(),
      expiresAt,
      redeemedBy: null,
      redeemedAt: null,
    });
  });

  // Ids only: never the child's name (ENG-22).
  logger.info('co-parent invite created', { householdId: input.householdId });
  return { code, expiresAt: expiresAt.toDate().toISOString() };
});
