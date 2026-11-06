import { type DocumentReference, FieldValue, type Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { type WallClock, knownZoneOr, wallClockOf } from '../calendar_sync/zoned_time';
import { householdRef } from '../household/documents';
import { consumeRateLimit, type RateLimitRule } from '../shared/rate_limit';
import {
  type FrameDocument,
  frameCredentialDocument,
  frameCredentialRef,
  frameDocument,
  frameRef,
  parsed,
  secretHash,
} from './frame_documents';
import { refuseFrame } from './frame_errors';
import { lastSeenIsStale } from './frame_policy';

export interface LinkedFrame {
  readonly frameId: string;
  readonly frame: FrameDocument;
  readonly home: DocumentReference;
  readonly householdName: string;
  readonly timeZone: string | null;
  readonly clock: WallClock;
}

const householdShape = z.object({ name: z.string(), timeZone: z.string().optional() });

/**
 * What every read by a linked frame starts with (photo-frames ADR-0001): its
 * secret opens a credential, the credential a frame record, the record a
 * household and its wall clock. Null means unlinked: a frame family deleted
 * retires its credential here, whichever read noticed first.
 */
export async function readLinkedFrame(
  store: Firestore,
  secret: string,
  rule: RateLimitRule,
): Promise<LinkedFrame | null> {
  const hashed = secretHash(secret);
  const credentialRef = frameCredentialRef(store, hashed);

  const credential = parsed(frameCredentialDocument, (await credentialRef.get()).data());
  if (credential === null) return null;
  if (!(await consumeRateLimit(store, rule, hashed))) {
    throw refuseFrame('tooManyAttempts');
  }

  const now = new Date();
  const ref = frameRef(store, credential.householdId, credential.frameId);
  const frame = await store.runTransaction(async (transaction): Promise<FrameDocument | null> => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) {
      transaction.delete(credentialRef);
      return null;
    }
    const stored = frameDocument.parse(snapshot.data());
    if (lastSeenIsStale(stored.lastSeenAt?.toDate() ?? null, now)) {
      transaction.update(ref, { lastSeenAt: FieldValue.serverTimestamp() });
    }
    return stored;
  });
  if (frame === null) return null;

  const home = householdRef(store, credential.householdId);
  const household = parsed(householdShape, (await home.get()).data());
  if (household === null) return null;
  return {
    frameId: credential.frameId,
    frame,
    home,
    householdName: household.name,
    timeZone: household.timeZone ?? null,
    clock: wallClockOf(now, knownZoneOr(household.timeZone)),
  };
}
