import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';

import { isFamilyRole } from '../../household/access';
import { householdRef } from '../../household/documents';
import { parseInput, requireUid } from '../../household/parse_input';
import { db } from '../../shared/firestore';
import { refuseDocument } from '../errors';
import { shareRef } from './share_refs';
import { revokeDocumentShareInput } from './share_schemas';

const householdShape = z.object({ members: z.record(z.string(), z.string()) });
const shareShape = z.object({ createdByUid: z.string(), status: z.string() });

/**
 * Stops a link working, now (documents ADR-0006). The family may stop any
 * link; anybody else only one they made. The link is marked `revoked`, which
 * the serving side refuses on the very next request. Its secrets are left for
 * their TTL, so whoever holds the link reads "this link no longer works"
 * rather than "this link does not work". Stopping a link that already ended
 * is not an error: the person's intent is already true.
 */
export const revokeDocumentShare = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(revokeDocumentShareInput, request.data);
  const store = db();

  await store.runTransaction(async (transaction) => {
    const household = householdShape.safeParse(
      (await transaction.get(householdRef(store, input.householdId))).data(),
    );
    const role = household.success ? household.data.members[uid] : undefined;
    if (role === undefined) throw refuseDocument('notAMember');

    const reference = shareRef(store, input.householdId, input.shareId);
    const share = shareShape.safeParse((await transaction.get(reference)).data());
    if (!share.success) throw refuseDocument('shareNotFound');
    if (!isFamilyRole(role) && share.data.createdByUid !== uid) {
      throw refuseDocument('notAllowedToShare');
    }
    if (share.data.status !== 'active') return;
    transaction.update(reference, {
      status: 'revoked',
      revokedAt: FieldValue.serverTimestamp(),
      revokedByUid: uid,
    });
  });

  logger.info('document share revoked', {
    householdId: input.householdId,
    shareId: input.shareId,
  });
  return { revoked: true };
});
