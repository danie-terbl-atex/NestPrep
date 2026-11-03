import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { parseInput } from '../household/parse_input';
import { db } from '../shared/firestore';
import { consumeRateLimit } from '../shared/rate_limit';
import {
  frameCredentialDocument,
  frameCredentialRef,
  frameRef,
  parsed,
  secretHash,
} from './frame_documents';
import { refuseFrame } from './frame_errors';
import { FRAME_DEVICE_OPTIONS, FRAME_UNLINK_PER_CREDENTIAL } from './frame_policy';
import { unlinkFrameInput } from './frame_schemas';

export interface UnlinkFrameResult {
  readonly status: 'unlinked';
}

const UNLINKED: UnlinkFrameResult = { status: 'unlinked' };

/**
 * A frame unlinks itself with its own secret (photo-frames ADR-0004): the
 * credential and the frame record it opens go in one transaction (`BE-06`).
 * Every secret, known or not, reads `unlinked`, so the answer says nothing
 * about which secrets exist.
 */
export const unlinkFrame = onCall(
  FRAME_DEVICE_OPTIONS,
  async (request): Promise<UnlinkFrameResult> => {
    const { secret } = parseInput(unlinkFrameInput, request.data);
    const store = db();
    const hashed = secretHash(secret);
    const credentialRef = frameCredentialRef(store, hashed);

    if (!(await credentialRef.get()).exists) return UNLINKED;
    if (!(await consumeRateLimit(store, FRAME_UNLINK_PER_CREDENTIAL, hashed))) {
      throw refuseFrame('tooManyAttempts');
    }

    const removed = await store.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(credentialRef);
      if (!snapshot.exists) return false;
      const credential = parsed(frameCredentialDocument, snapshot.data());
      if (credential !== null) {
        transaction.delete(frameRef(store, credential.householdId, credential.frameId));
      }
      transaction.delete(credentialRef);
      return true;
    });
    if (removed) logger.info('frame unlinked itself');
    return UNLINKED;
  },
);
