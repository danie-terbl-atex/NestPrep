import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { isReadableCode } from '../shared/readable_code';
import { householdRef, readHousehold } from '../household/documents';
import { refuse } from '../household/errors';
import { readMember } from '../household/membership';
import { parseInput } from '../household/parse_input';
import { kidAuthAccounts } from './kid_auth_accounts';
import {
  KIDS_FIELD,
  type KidPairingDocument,
  deviceRef,
  devicesOf,
  pairingRef,
  parsePairing,
} from './kid_documents';
import { refuseKid } from './kid_errors';
import { redeemKidPairingInput } from './kid_schemas';
import {
  KID_CODE_LENGTH,
  KID_DEVICE_LIMIT,
  isEligibleForKidSignIn,
  newKidUid,
  pairingRefusal,
} from './kid_sign_in_policy';

/**
 * A kid's device trades a pairing code for a custom token that signs it in as
 * that kid profile (accounts ADR-0003).
 *
 * **Unauthenticated on purpose**: the device has nobody to be yet. The code is
 * the whole credential, which is why it is short-lived, single-use and checked
 * for shape before anything is read.
 *
 * The order is `BE-06`'s. The token is minted *before* the code is spent, so a
 * signer that is not set up leaves the code usable and nothing half-made; the
 * code, the device record and the household's `kids` entry then move in one
 * transaction, and if that refuses, the Auth user it minted is closed again.
 */
export const redeemKidPairing = onCall(async (request) => {
  const { code } = parseInput(redeemKidPairingInput, request.data);
  if (!isReadableCode(code, KID_CODE_LENGTH)) throw refuseKid('codeNotFound');
  const store = db();

  const pairing = await readRedeemablePairing(store, code);
  const uid = newKidUid();
  const accounts = kidAuthAccounts();

  let token: string;
  try {
    token = await accounts.open(uid, {
      householdId: pairing.householdId,
      memberId: pairing.memberId,
    });
  } catch (error: unknown) {
    logger.error('kid token could not be minted', { error: String(error) });
    await accounts.close([uid]);
    throw refuseKid('signInUnavailable');
  }

  try {
    await store.runTransaction(async (transaction) => {
      const live = parsePairing((await transaction.get(pairingRef(store, code))).data());
      const refusal = pairingRefusal(live, Date.now());
      if (refusal !== null || live === null) throw refuseKid(refusal ?? 'codeNotFound');

      await readHousehold(transaction, store, live.householdId, () => refuse('householdNotFound'));
      const member = await readMember(transaction, store, live.householdId, live.memberId);
      if (member === undefined) throw refuse('memberNotFound');
      if (!isEligibleForKidSignIn(member)) throw refuseKid('notEligible');

      const devices = await transaction.get(
        devicesOf(store, live.householdId, live.memberId, KID_DEVICE_LIMIT),
      );
      if (devices.size >= KID_DEVICE_LIMIT) throw refuseKid('tooManyDevices');

      transaction.delete(pairingRef(store, code));
      transaction.set(deviceRef(store, live.householdId, uid), {
        memberId: live.memberId,
        label: live.label,
        pairedBy: live.createdBy,
        pairedAt: FieldValue.serverTimestamp(),
      });
      transaction.update(householdRef(store, live.householdId), {
        [`${KIDS_FIELD}.${uid}`]: live.memberId,
      });
    });
  } catch (error: unknown) {
    await accounts.close([uid]);
    throw error;
  }

  logger.info('kid device paired', { householdId: pairing.householdId });
  return { token };
});

/**
 * The code's pairing, checked before anything is minted, so a wrong or stale
 * code costs one read and creates nobody. The transaction checks it again,
 * because this read can be stale by the time it commits.
 */
async function readRedeemablePairing(store: Firestore, code: string): Promise<KidPairingDocument> {
  const pairing = parsePairing((await pairingRef(store, code).get()).data());
  const refusal = pairingRefusal(pairing, Date.now());
  if (refusal !== null || pairing === null) throw refuseKid(refusal ?? 'codeNotFound');
  return pairing;
}
