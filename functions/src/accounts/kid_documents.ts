import {
  Timestamp,
  type DocumentReference,
  type Firestore,
  type Query,
} from 'firebase-admin/firestore';
import { z } from 'zod';

import { householdRef } from '../household/documents';

/**
 * Where kid sign-ins are kept (accounts ADR-0003).
 *
 * - `kidPairings/{code}` — a live code, top level so redeeming it needs no
 *   household first. No client reads or writes it: a readable pairing
 *   collection would be a list of ways into somebody's household.
 * - `households/{h}/kidDevices/{uid}` — one signed-in kid device, readable by
 *   the household's admins so they can see and end it.
 * - `households/{h}.kids` — `{ uid: memberId }`, the map Security Rules read
 *   to let a kid device see its own things. Never the `members` map: a kid is
 *   not a member, so every rule that asks "is this a member" says no.
 */
export const KID_PAIRINGS = 'kidPairings';
export const KID_DEVICES = 'kidDevices';
export const KIDS_FIELD = 'kids';

export const kidPairingDocument = z.object({
  householdId: z.string().min(1),
  memberId: z.string().min(1),
  label: z.string(),
  createdBy: z.string().min(1),
  expiresAt: z.instanceof(Timestamp),
});
export type KidPairingDocument = z.infer<typeof kidPairingDocument>;

export function pairingRef(store: Firestore, code: string): DocumentReference {
  return store.collection(KID_PAIRINGS).doc(code);
}

/** Every code still waiting for one profile — at most one, unless two admins raced. */
export function pairingsFor(store: Firestore, householdId: string, memberId: string): Query {
  return store
    .collection(KID_PAIRINGS)
    .where('householdId', '==', householdId)
    .where('memberId', '==', memberId)
    .limit(10);
}

export function deviceRef(store: Firestore, householdId: string, uid: string): DocumentReference {
  return householdRef(store, householdId).collection(KID_DEVICES).doc(uid);
}

/** One profile's devices. Bounded by the limit, plus room to see it was reached. */
export function devicesOf(
  store: Firestore,
  householdId: string,
  memberId: string,
  limit: number,
): Query {
  return householdRef(store, householdId)
    .collection(KID_DEVICES)
    .where('memberId', '==', memberId)
    .limit(limit);
}

/** A stored pairing, parsed rather than cast (`ENG-09`); anything else is no pairing at all. */
export function parsePairing(data: unknown): KidPairingDocument | null {
  const parsed = kidPairingDocument.safeParse(data);
  return parsed.success ? parsed.data : null;
}
