import { FieldValue, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { parseInput } from '../household/parse_input';
import { clientAddress } from '../shared/client_address';
import { db } from '../shared/firestore';
import { consumeRateLimit } from '../shared/rate_limit';
import { generateReadableCode } from '../shared/readable_code';
import { framePairingRef, secretHash } from './frame_documents';
import { refuseFrame } from './frame_errors';
import {
  FRAME_CODE_LENGTH,
  FRAME_CODE_LIFETIME_MS,
  FRAME_DEVICE_OPTIONS,
  FRAME_POLL_SECONDS,
  FRAME_START_OVERALL,
  FRAME_START_PER_ADDRESS,
} from './frame_policy';
import { startFramePairingInput } from './frame_schemas';

const CODE_ATTEMPTS = 5;

/**
 * A frame asks for a ten-minute code to show on its screen (photo-frames
 * ADR-0001). **Unauthenticated on purpose**: a frame has no Firebase SDK and
 * nobody to be. Only the hash of its secret is kept, so the code alone never
 * lets anybody else read what the frame is later shown.
 */
export const startFramePairing = onCall(FRAME_DEVICE_OPTIONS, async (request) => {
  const input = parseInput(startFramePairingInput, request.data);
  const store = db();
  const allowed =
    (await consumeRateLimit(store, FRAME_START_OVERALL, 'all')) &&
    (await consumeRateLimit(store, FRAME_START_PER_ADDRESS, clientAddress(request.rawRequest)));
  if (!allowed) throw refuseFrame('tooManyAttempts');

  const expiresAt = Timestamp.fromMillis(Date.now() + FRAME_CODE_LIFETIME_MS);
  const pairing = {
    secretHash: secretHash(input.secret),
    model: input.model ?? null,
    status: 'waiting',
    createdAt: FieldValue.serverTimestamp(),
    expiresAt,
  };

  for (let attempt = 0; attempt < CODE_ATTEMPTS; attempt += 1) {
    const code = generateReadableCode(FRAME_CODE_LENGTH);
    if (await createIfFree(store, code, pairing)) {
      logger.info('frame pairing started');
      return { code, expiresAt: expiresAt.toMillis(), pollSeconds: FRAME_POLL_SECONDS };
    }
  }
  throw new Error('no free frame code after several attempts');
});

async function createIfFree(
  store: Firestore,
  code: string,
  pairing: Record<string, unknown>,
): Promise<boolean> {
  return store.runTransaction(async (transaction) => {
    const ref = framePairingRef(store, code);
    if ((await transaction.get(ref)).exists) return false;
    transaction.create(ref, pairing);
    return true;
  });
}
