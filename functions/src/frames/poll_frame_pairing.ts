import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { parseInput } from '../household/parse_input';
import { clientAddress } from '../shared/client_address';
import { db } from '../shared/firestore';
import { consumeRateLimit } from '../shared/rate_limit';
import { isReadableCode } from '../shared/readable_code';
import {
  type FramePairingDocument,
  framePairingDocument,
  framePairingRef,
  parsed,
  secretHash,
} from './frame_documents';
import { refuseFrame } from './frame_errors';
import { FRAME_CODE_LENGTH, FRAME_DEVICE_OPTIONS, FRAME_POLL_PER_ADDRESS } from './frame_policy';
import { pollFramePairingInput } from './frame_schemas';

export type PollFramePairingResult =
  { status: 'waiting' } | { status: 'expired' } | { status: 'linked'; householdName: string };

const EXPIRED: PollFramePairingResult = { status: 'expired' };

/**
 * A frame asks whether its code has been claimed yet (photo-frames ADR-0001).
 * An unknown code, a secret that is not the one that asked for it and a code
 * past its ten minutes all read as `expired`, so a poll never says which.
 * The first poll that sees it linked removes the pairing: the credential is
 * what the frame is from then on.
 */
export const pollFramePairing = onCall(
  FRAME_DEVICE_OPTIONS,
  async (request): Promise<PollFramePairingResult> => {
    const { code, secret } = parseInput(pollFramePairingInput, request.data);
    const store = db();
    if (
      !(await consumeRateLimit(store, FRAME_POLL_PER_ADDRESS, clientAddress(request.rawRequest)))
    ) {
      throw refuseFrame('tooManyAttempts');
    }
    if (!isReadableCode(code, FRAME_CODE_LENGTH)) return EXPIRED;

    const hashed = secretHash(secret);
    const result = await store.runTransaction(async (transaction) => {
      const ref = framePairingRef(store, code);
      const pairing = parsed(framePairingDocument, (await transaction.get(ref)).data());
      const answer = answerFor(pairing, hashed, Date.now());
      if (answer.status === 'linked') transaction.delete(ref);
      return answer;
    });
    if (result.status === 'linked') logger.info('frame pairing collected');
    return result;
  },
);

/**
 * What a poll says. A linked pairing answers even past its expiry: the frame
 * is already linked, and one that was offline for the claim must still learn it.
 */
export function answerFor(
  pairing: FramePairingDocument | null,
  hashed: string,
  nowMs: number,
): PollFramePairingResult {
  if (pairing === null || pairing.secretHash !== hashed) return EXPIRED;
  if (pairing.status === 'linked') {
    return { status: 'linked', householdName: pairing.householdName ?? '' };
  }
  return pairing.expiresAt.toMillis() <= nowMs ? EXPIRED : { status: 'waiting' };
}
