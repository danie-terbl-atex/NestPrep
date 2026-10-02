import {
  FieldValue,
  Timestamp,
  type DocumentReference,
  type Firestore,
} from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { householdRef } from '../household/documents';
import { PROMPT_VERSION, type LunchCombination } from './combination';

/**
 * Where a box's picture is cached (lunch-box ADR-0015). A shared picture —
 * catalogue foods only — lives at the root, a household's own under the
 * household; each is a Firestore document saying how far it has got and a
 * Storage object with the bytes, both under the combination's key. Only
 * Functions write either; the rules let no client touch the documents.
 *
 * `lunchPhotos/{key}` / `households/{h}/lunchPhotos/{key}`:
 * `{ status: 'pending' | 'ready', path?, promptVersion, model?, pendingSince?, createdAt? }`.
 */
export const LUNCH_PHOTOS = 'lunchPhotos';

/** A picture being made for longer than this was abandoned, and may be made again. */
export const PENDING_FOR_MS = 120_000;

export interface PhotoPlace {
  readonly ref: DocumentReference;
  /** The Storage object, which is also what the app is told to load. */
  readonly path: string;
}

export function photoPlace(
  store: Firestore,
  householdId: string,
  combination: LunchCombination,
): PhotoPlace {
  const file = `${LUNCH_PHOTOS}/${combination.key}`;
  if (combination.scope === 'shared') {
    return { ref: store.collection(LUNCH_PHOTOS).doc(combination.key), path: `${file}.jpg` };
  }
  return {
    ref: householdRef(store, householdId).collection(LUNCH_PHOTOS).doc(combination.key),
    path: `households/${householdId}/${file}.jpg`,
  };
}

const storedPhoto = z.object({
  status: z.enum(['pending', 'ready']),
  path: z.string().min(1).optional(),
  pendingSince: z.instanceof(Timestamp).optional(),
});

export type PhotoState =
  | { readonly status: 'ready'; readonly path: string }
  | { readonly status: 'pending' }
  | { readonly status: 'claimed' };

/**
 * What a stored document means at [now]: a picture to hand back, one somebody
 * else is making, or nothing usable — which the caller then claims.
 */
export function photoStateOf(stored: unknown, now: Date): PhotoState {
  const photo = storedPhoto.safeParse(stored);
  if (!photo.success) return { status: 'claimed' };
  if (photo.data.status === 'ready' && photo.data.path !== undefined) {
    return { status: 'ready', path: photo.data.path };
  }
  const since = photo.data.pendingSince?.toMillis();
  if (photo.data.status === 'pending' && since !== undefined) {
    if (now.getTime() - since < PENDING_FOR_MS) return { status: 'pending' };
  }
  return { status: 'claimed' };
}

/**
 * Reads the cache and, when there is nothing to hand back, marks the picture
 * as being made — in one transaction, so two phones asking for the same box
 * at once pay for it once (BE-06).
 */
export function claimPhoto(store: Firestore, place: PhotoPlace, now: Date): Promise<PhotoState> {
  return store.runTransaction(async (transaction) => {
    const state = photoStateOf((await transaction.get(place.ref)).data(), now);
    if (state.status === 'claimed') {
      transaction.set(place.ref, {
        status: 'pending',
        promptVersion: PROMPT_VERSION,
        pendingSince: Timestamp.fromDate(now),
      });
    }
    return state;
  });
}

export async function markReady(store: Firestore, place: PhotoPlace, model: string): Promise<void> {
  const batch = store.batch();
  batch.set(place.ref, {
    status: 'ready',
    path: place.path,
    promptVersion: PROMPT_VERSION,
    model,
    createdAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
}

/**
 * Lets the next ask make the picture again after this one failed. Best
 * effort: a claim left behind lapses after [PENDING_FOR_MS] anyway, so a
 * failure here is logged rather than hiding the failure that brought us here.
 */
export async function releaseClaim(store: Firestore, place: PhotoPlace): Promise<void> {
  try {
    await store.runTransaction(async (transaction) => {
      const current = await transaction.get(place.ref);
      if (current.get('status') === 'pending') transaction.delete(place.ref);
    });
  } catch (error) {
    logger.warn('lunch photo claim not released', {
      error: error instanceof Error ? error.name : 'unknown',
    });
  }
}
