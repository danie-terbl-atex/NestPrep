import { onCall } from 'firebase-functions/v2/https';

import { looksLikeInviteCode } from '../household/invite_code';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { coParentInviteRef } from './coparent_refs';
import { refuseCoParent } from './errors';
import { usableInvite } from './link_invite';
import { previewCoParentInviteInput } from './schemas';

/**
 * What a code offers, before anybody accepts it (household ADR-0004): the
 * child's first name, the other home's name and colour, and the schedule it
 * proposes — exactly what the accepting admin is agreeing to, and nothing
 * else about the household that made it. Only the code opens it, and a code
 * is only ever handed from one parent to the other.
 *
 * A read, so no transaction: nothing is written.
 */
export const previewCoParentInvite = onCall(async (request) => {
  requireUid(request.auth);
  const input = parseInput(previewCoParentInviteInput, request.data);
  if (!looksLikeInviteCode(input.code)) throw refuseCoParent('linkInviteNotFound');

  const snapshot = await coParentInviteRef(db(), input.code).get();
  const invite = usableInvite(snapshot.exists ? snapshot.data() : undefined);
  return {
    childName: invite.childName,
    home: invite.home,
    schedule: invite.schedule,
    expiresAt: invite.expiresAt.toDate().toISOString(),
  };
});
