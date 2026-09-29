import { FieldValue, type Firestore, type Transaction } from 'firebase-admin/firestore';

import { householdRef } from '../household/documents';
import { KIDS_FIELD, deviceRef, devicesOf } from './kid_documents';

/**
 * How many devices one read of a profile's devices can return — every device
 * it may have, with a margin for any that predate a lower limit.
 */
const DEVICE_READ_LIMIT = 50;

/** The uids of every device signed in as one profile, read inside a transaction. */
export async function readKidDeviceUids(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  memberId: string,
): Promise<string[]> {
  const devices = await transaction.get(devicesOf(store, householdId, memberId, DEVICE_READ_LIMIT));
  return devices.docs.map((device) => device.id);
}

/**
 * Stops the household trusting these devices: their entries leave the `kids`
 * map the rules read, and their device documents go. Staged on the caller's
 * transaction, so a revoke, a reset and a member's removal are each atomic
 * (`BE-07`). Ending the Auth sessions is the caller's next step, after commit.
 */
export function detachKidDevices(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  uids: readonly string[],
): void {
  if (uids.length === 0) return;
  for (const uid of uids) {
    transaction.delete(deviceRef(store, householdId, uid));
  }
  transaction.update(
    householdRef(store, householdId),
    Object.fromEntries(uids.map((uid) => [`${KIDS_FIELD}.${uid}`, FieldValue.delete()])),
  );
}
