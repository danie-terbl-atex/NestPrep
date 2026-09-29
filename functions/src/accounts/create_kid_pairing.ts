import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { generateReadableCode } from '../shared/readable_code';
import { readHousehold, roleOf } from '../household/documents';
import { refuse } from '../household/errors';
import { readMember } from '../household/membership';
import { parseInput, requireUid } from '../household/parse_input';
import { devicesOf, pairingRef, pairingsFor } from './kid_documents';
import { refuseKid } from './kid_errors';
import { createKidPairingInput } from './kid_schemas';
import {
  KID_CODE_LENGTH,
  KID_CODE_LIFETIME_MS,
  KID_DEVICE_LIMIT,
  isEligibleForKidSignIn,
} from './kid_sign_in_policy';

/**
 * An admin makes a ten-minute, single-use code that signs one device in as one
 * kid profile (accounts ADR-0003). A profile has at most one live code: making
 * another retires the one before, so a code read aloud and then abandoned is
 * dead the moment the parent tries again.
 */
export const createKidPairing = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(createKidPairingInput, request.data);
  const store = db();

  const code = generateReadableCode(KID_CODE_LENGTH);
  const expiresAt = Timestamp.fromMillis(Date.now() + KID_CODE_LIFETIME_MS);

  await store.runTransaction(async (transaction) => {
    const household = await readHousehold(transaction, store, input.householdId, () =>
      refuse('householdNotFound'),
    );
    if (roleOf(household, uid) !== 'admin') throw refuse('notAnAdmin');

    const member = await readMember(transaction, store, input.householdId, input.memberId);
    if (member === undefined) throw refuse('memberNotFound');
    if (!isEligibleForKidSignIn(member)) throw refuseKid('notEligible');

    const devices = await transaction.get(
      devicesOf(store, input.householdId, input.memberId, KID_DEVICE_LIMIT),
    );
    if (devices.size >= KID_DEVICE_LIMIT) throw refuseKid('tooManyDevices');

    const earlier = await transaction.get(pairingsFor(store, input.householdId, input.memberId));
    for (const pairing of earlier.docs) transaction.delete(pairing.ref);

    // `create`, not `set`: two live codes colliding is one in hundreds of
    // millions, and when it happens the commit fails rather than handing
    // somebody else's household this profile's code.
    transaction.create(pairingRef(store, code), {
      householdId: input.householdId,
      memberId: input.memberId,
      label: input.label,
      createdBy: uid,
      createdAt: FieldValue.serverTimestamp(),
      expiresAt,
    });
  });

  logger.info('kid pairing created', { householdId: input.householdId });
  return { code, expiresAt: expiresAt.toDate().toISOString() };
});
