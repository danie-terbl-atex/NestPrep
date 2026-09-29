import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';

import { parseInput, requireUid } from '../../household/parse_input';
import { readFlag } from '../../shared/feature_flags';
import { db } from '../../shared/firestore';
import { shiftRef } from '../../nanny_hub/nanny_refs';
import { refuseDocument } from '../errors';
import { sharerIn } from './share_caller';
import {
  MAX_LIVE_SHARES,
  expiryFor,
  mayShare,
  purgeAfter,
  type ShareLifetime,
  type ShareScope,
} from './share_policy';
import { liveSharesOf, newShareRef, sharedDocumentRef, shareUrlFor, tokenRef } from './share_refs';
import { createDocumentShareInput, type CreateDocumentShareInput } from './share_schemas';
import { hashPin, hashShareToken, newShareToken } from './share_secrets';

const documentShape = z.object({ name: z.string(), contentType: z.string() });
const shiftShape = z.object({ status: z.string() });

/**
 * Makes one expiring link to one document (documents ADR-0006).
 *
 * Who may share is re-derived here — the family for anything, a vault's owner
 * for their own vault — and so is everything the link says about itself: the
 * document's name and type, when it ends, whether its shift is open. The link
 * and its secrets are written in one transaction, beside a count of the live
 * links that keeps the household under its cap (`BE-06`, `BE-08`).
 *
 * The token is returned once and stored nowhere but as its hash.
 */
export const createDocumentShare = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(createDocumentShareInput, request.data);
  const store = db();
  const scope: ShareScope = input.ownerMemberId === null ? 'household' : 'vault';

  if (!(await readFlag(store, 'documentShareLinks'))) throw refuseDocument('featureOff');
  const { household, sharer } = await sharerIn(store, input.householdId, uid);
  if (household === null || sharer.role === undefined) throw refuseDocument('notAMember');
  if (!mayShare(sharer, scope, input.ownerMemberId)) {
    logger.info('document share refused', { householdId: input.householdId, scope });
    throw refuseDocument('notAllowedToShare');
  }

  const now = new Date();
  const lifetime = lifetimeOf(input);
  const expiresAt = expiryFor(now, lifetime);
  const token = newShareToken();
  const shareRef = newShareRef(store, input.householdId);
  const pin = input.pin === null ? null : hashPin(input.pin);

  await store.runTransaction(async (transaction) => {
    const address = { ...input, scope };
    const document = documentShape.safeParse(
      (await transaction.get(sharedDocumentRef(store, address))).data(),
    );
    if (!document.success) throw refuseDocument('documentNotFound');
    if (lifetime.kind === 'shift') {
      const shift = shiftShape.safeParse(
        (await transaction.get(shiftRef(store, input.householdId, lifetime.shiftId))).data(),
      );
      if (!shift.success || shift.data.status !== 'open') throw refuseDocument('shiftNotOpen');
    }
    const live = await transaction.get(
      liveSharesOf(store, input.householdId, now, MAX_LIVE_SHARES),
    );
    if (live.size >= MAX_LIVE_SHARES) throw refuseDocument('tooManyShares');

    transaction.create(shareRef, {
      scope,
      ownerMemberId: input.ownerMemberId,
      documentId: input.documentId,
      documentName: document.data.name,
      contentType: document.data.contentType,
      createdBy: sharer.memberId ?? null,
      createdByUid: uid,
      createdAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromDate(expiresAt),
      shiftId: lifetime.kind === 'shift' ? lifetime.shiftId : null,
      hasPin: pin !== null,
      status: 'active',
      openCount: 0,
      lastOpenedAt: null,
      purgeAt: Timestamp.fromDate(purgeAfter(expiresAt)),
    });
    transaction.create(tokenRef(store, hashShareToken(token)), {
      householdId: input.householdId,
      shareId: shareRef.id,
      pinHash: pin?.pinHash ?? null,
      pinSalt: pin?.pinSalt ?? null,
      failedPinAttempts: 0,
      expiresAt: Timestamp.fromDate(expiresAt),
    });
  });

  // No token, no document name: an id finds the entry again (ENG-22).
  logger.info('document share made', {
    householdId: input.householdId,
    shareId: shareRef.id,
    scope,
    hasPin: pin !== null,
  });
  return {
    shareId: shareRef.id,
    url: shareUrlFor(token),
    expiresAt: expiresAt.toISOString(),
  };
});

function lifetimeOf(input: CreateDocumentShareInput): ShareLifetime {
  if (input.shiftId !== null) return { kind: 'shift', shiftId: input.shiftId };
  return { kind: 'hours', hours: input.lifetimeHours ?? 1 };
}
