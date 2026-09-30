import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { ROLE_DEFAULTS } from '../household/access';
import { householdRef, MEMBERS } from '../household/documents';
import { looksLikeInviteCode } from '../household/invite_code';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { isAlreadyLinked, readKidProfile } from './child_profiles';
import { requireRole } from './coparent_caller';
import { authorityRef, coParentInviteRef, COPARENT_LINKS, mirrorRef } from './coparent_refs';
import { refuseCoParent } from './errors';
import { usableInvite } from './link_invite';
import { acceptCoParentInviteInput } from './schemas';

/**
 * The other home's admin accepts a code (household ADR-0004): names and
 * colours their own home, and picks — or makes — their own kid profile for
 * the child. The link is born **pending**: nothing is shared but the two
 * homes' names and the proposed schedule until an admin of the home that made
 * the code confirms it, so a leaked code cannot quietly link a stranger.
 *
 * One transaction moves five documents — the code, the authority, both
 * mirrors and, when the child is new here, their profile (BE-06, BE-07).
 */
export const acceptCoParentInvite = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(acceptCoParentInviteInput, request.data);
  if (!looksLikeInviteCode(input.code)) throw refuseCoParent('linkInviteNotFound');
  const store = db();

  const linkId = await store.runTransaction(async (transaction) => {
    const inviteSnapshot = await transaction.get(coParentInviteRef(store, input.code));
    const invite = usableInvite(inviteSnapshot.exists ? inviteSnapshot.data() : undefined);
    if (invite.householdId === input.householdId) throw refuseCoParent('sameHousehold');
    await requireRole(transaction, store, input.householdId, uid, 'admin');

    // The code's child must still be there, and still unlinked, on its side.
    await readKidProfile(transaction, store, invite.householdId, invite.childMemberId);
    if (await isAlreadyLinked(transaction, store, invite.householdId, invite.childMemberId)) {
      throw refuseCoParent('childAlreadyLinked');
    }

    const newChild =
      input.childMemberId === null
        ? householdRef(store, input.householdId).collection(MEMBERS).doc()
        : null;
    const childMemberId = newChild?.id ?? input.childMemberId ?? '';
    if (newChild === null) {
      await readKidProfile(transaction, store, input.householdId, childMemberId);
      if (await isAlreadyLinked(transaction, store, input.householdId, childMemberId)) {
        throw refuseCoParent('childAlreadyLinked');
      }
    }

    const id = store.collection(COPARENT_LINKS).doc().id;
    const now = FieldValue.serverTimestamp();
    const homes = { a: invite.home, b: input.home };
    const shared = {
      status: 'pending',
      childName: invite.childName,
      homes,
      schedule: invite.schedule,
      overrides: {},
      awaitingSide: 'a',
      endedBySide: null,
      createdAt: now,
      updatedAt: now,
    };

    if (newChild !== null) {
      transaction.set(newChild, {
        displayName: input.newChildName,
        color: input.home.color,
        role: 'kid',
        access: ROLE_DEFAULTS.kid,
        claimedBy: null,
        createdAt: now,
      });
    }
    transaction.set(authorityRef(store, id), {
      householdIds: { a: invite.householdId, b: input.householdId },
      childMemberIds: { a: invite.childMemberId, b: childMemberId },
      status: 'pending',
      awaitingSide: 'a',
      createdAt: now,
      updatedAt: now,
    });
    transaction.set(mirrorRef(store, invite.householdId, id), {
      ...shared,
      ownSide: 'a',
      childMemberId: invite.childMemberId,
    });
    transaction.set(mirrorRef(store, input.householdId, id), {
      ...shared,
      ownSide: 'b',
      childMemberId,
    });
    transaction.update(coParentInviteRef(store, input.code), {
      redeemedBy: uid,
      redeemedAt: now,
      linkId: id,
    });
    return id;
  });

  logger.info('co-parent invite accepted', { householdId: input.householdId, linkId });
  return { linkId };
});
