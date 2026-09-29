import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { readHousehold, roleOf } from '../household/documents';
import { refuse } from '../household/errors';
import { parseInput, requireUid } from '../household/parse_input';
import { pairingRef, parsePairing } from './kid_documents';
import { cancelKidPairingInput } from './kid_schemas';

/**
 * The parent closed the code without using it, so it stops working now rather
 * than in ten minutes (accounts ADR-0003).
 *
 * Safe to call twice and safe to call late: a code already used, expired or
 * gone is already not a way in, so there is nothing to refuse — it answers
 * whether it retired anything. A code belonging to another household is
 * treated as not there, so this cannot be used to learn whose a code is.
 */
export const cancelKidPairing = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(cancelKidPairingInput, request.data);
  const store = db();

  const cancelled = await store.runTransaction(async (transaction) => {
    const household = await readHousehold(transaction, store, input.householdId, () =>
      refuse('householdNotFound'),
    );
    if (roleOf(household, uid) !== 'admin') throw refuse('notAnAdmin');

    const ref = pairingRef(store, input.code);
    const pairing = parsePairing((await transaction.get(ref)).data());
    if (pairing?.householdId !== input.householdId) return false;

    transaction.delete(ref);
    return true;
  });

  logger.info('kid pairing cancelled', { householdId: input.householdId, cancelled });
  return { cancelled };
});
