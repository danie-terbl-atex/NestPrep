import { FieldValue } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { isFamilyRole } from '../household/access';
import { memberRef, readHousehold, roleOf } from '../household/documents';
import { refuse } from '../household/errors';
import { parseInput, requireUid } from '../household/parse_input';
import { readFlag } from '../shared/feature_flags';
import { db } from '../shared/firestore';
import { consumeRateLimit } from '../shared/rate_limit';
import { isReadableCode } from '../shared/readable_code';
import {
  frameCredentialDocument,
  frameCredentialRef,
  framePairingDocument,
  framePairingRef,
  frameRef,
  framesOf,
  parsed,
} from './frame_documents';
import { refuseFrame } from './frame_errors';
import { FRAME_CLAIM_PER_UID, FRAME_CODE_LENGTH, FRAME_LIMIT } from './frame_policy';
import { claimFramePairingInput } from './frame_schemas';

/**
 * A parent types or scans the code a frame is showing, names the frame and
 * chooses what it shows (photo-frames ADR-0001). The frame record, the
 * credential its secret now opens and the pairing the frame is polling move
 * in one transaction (`BE-06`), so a frame is never half linked.
 */
export const claimFramePairing = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(claimFramePairingInput, request.data);
  const store = db();

  if (!(await consumeRateLimit(store, FRAME_CLAIM_PER_UID, uid))) {
    throw refuseFrame('tooManyAttempts');
  }
  if (!(await readFlag(store, 'photoFrames'))) throw refuseFrame('framesOff');
  if (!isReadableCode(input.code, FRAME_CODE_LENGTH)) throw refuseFrame('frameCodeNotFound');

  const frameId = framesOf(store, input.householdId).doc().id;

  await store.runTransaction(async (transaction) => {
    const household = await readHousehold(transaction, store, input.householdId, () =>
      refuse('householdNotFound'),
    );
    const role = roleOf(household, uid);
    if (role === undefined) throw refuse('notAMember');
    if (!isFamilyRole(role)) throw refuseFrame('notFamily');

    const helperId = input.panels.helperMemberId;
    if (helperId !== null) {
      const helper = await transaction.get(memberRef(store, input.householdId, helperId));
      if (!helper.exists) throw refuseFrame('helperNotFound');
    }

    const frames = await transaction.get(framesOf(store, input.householdId).limit(FRAME_LIMIT));
    if (frames.size >= FRAME_LIMIT) throw refuseFrame('tooManyFrames');

    const pairingRef = framePairingRef(store, input.code);
    const pairingSnapshot = await transaction.get(pairingRef);
    if (!pairingSnapshot.exists) throw refuseFrame('frameCodeNotFound');
    const pairing = parsed(framePairingDocument, pairingSnapshot.data());
    if (
      pairing === null ||
      pairing.status !== 'waiting' ||
      pairing.expiresAt.toMillis() <= Date.now()
    ) {
      throw refuseFrame('frameCodeExpired');
    }

    // A frame that pairs again while still linked keeps its secret, so the
    // credential moves and the frame it used to be stops existing.
    const credentialRef = frameCredentialRef(store, pairing.secretHash);
    const earlier = parsed(frameCredentialDocument, (await transaction.get(credentialRef)).data());
    if (earlier !== null) transaction.delete(frameRef(store, earlier.householdId, earlier.frameId));

    const linkedBy = household.profiles?.[uid];
    transaction.create(frameRef(store, input.householdId, frameId), {
      name: input.name,
      panels: input.panels,
      model: pairing.model,
      linkedBy: typeof linkedBy === 'string' ? linkedBy : null,
      linkedAt: FieldValue.serverTimestamp(),
      lastSeenAt: null,
    });
    transaction.set(credentialRef, {
      householdId: input.householdId,
      frameId,
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.update(pairingRef, {
      status: 'linked',
      householdId: input.householdId,
      frameId,
      householdName: household.name,
    });
  });

  logger.info('frame linked', { householdId: input.householdId });
  return { frameId };
});
