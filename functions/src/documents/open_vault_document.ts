import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { db } from '../shared/firestore';
import { householdRef, roleOf, type HouseholdDocument } from '../household/documents';
import { parseInput, requireUid } from '../household/parse_input';
import { refuseDocument } from './errors';
import { openVaultDocumentInput } from './schemas';
import { TICKET_LIFETIME_MS, mayOpenVault } from './vault_access';
import { claimedMemberId, grantRef, openingRef, vaultDocumentRef, viewsOf } from './vault_refs';

/**
 * Opening a document in somebody's personal vault (documents ADR-0003).
 *
 * The bytes can only be read while a ticket for this caller and this document
 * exists, and this is the only thing that writes one — in the same batch as the
 * view-log entry. So a vault document cannot be read without the log saying who
 * read it, and a modified client cannot skip the line: it has no way to write a
 * ticket of its own.
 *
 * Everything that decides access is re-derived here — the role from the
 * household's map, the caller's profile from `claimedBy`, the grant from its
 * document — and nothing the client sent is trusted but the address (BE-03).
 */
export const openVaultDocument = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(openVaultDocumentInput, request.data);
  const store = db();

  const household = await householdRef(store, input.householdId).get();
  const data = household.data() as HouseholdDocument | undefined;
  const role = data === undefined ? undefined : roleOf(data, uid);
  if (role === undefined) throw refuseDocument('notAMember');

  const [viewerMemberId, grant] = await Promise.all([
    claimedMemberId(store, input.householdId, uid),
    grantRef(store, input.householdId, input.ownerMemberId, uid).get(),
  ]);
  if (!mayOpenVault({ role, viewerMemberId, hasGrant: grant.exists }, input.ownerMemberId)) {
    logger.info('vault open refused', { householdId: input.householdId, reason: 'vaultNotShared' });
    throw refuseDocument('vaultNotShared');
  }

  const document = await vaultDocumentRef(
    store,
    input.householdId,
    input.ownerMemberId,
    input.documentId,
  ).get();
  if (!document.exists) throw refuseDocument('documentNotFound');
  const name: unknown = document.get('name');

  const expiresAt = Timestamp.fromMillis(Date.now() + TICKET_LIFETIME_MS);
  const batch = store.batch();
  batch.create(viewsOf(store, input.householdId, input.ownerMemberId).doc(), {
    documentId: input.documentId,
    // The name at the time it was opened: a log that follows a later rename
    // would say somebody read a document they never saw by that name.
    documentName: typeof name === 'string' ? name : '',
    viewerMemberId: viewerMemberId ?? null,
    viewerRole: role,
    viewedAt: FieldValue.serverTimestamp(),
  });
  batch.set(openingRef(store, input.householdId, uid, input.documentId), {
    ownerMemberId: input.ownerMemberId,
    documentId: input.documentId,
    uid,
    expiresAt,
  });
  await batch.commit();

  // No names, no document titles: an id is enough to find the entry again.
  logger.info('vault document opened', { householdId: input.householdId, role });
  return { expiresAt: expiresAt.toDate().toISOString() };
});
