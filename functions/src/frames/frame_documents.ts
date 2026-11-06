import { hash } from 'node:crypto';

import {
  Timestamp,
  type CollectionReference,
  type DocumentReference,
  type Firestore,
} from 'firebase-admin/firestore';
import { z } from 'zod';

import { householdRef } from '../household/documents';
import { FRAME_AREA_CODES } from './frame_areas';
import { frameRecipe } from './frame_recipe';
import {
  SCREENSAVER_IDLE_MINUTES,
  SCREENSAVER_SECONDS_PER_PHOTO,
  WOOLWORTHS_PRICE_ZONES,
} from './frame_policy';

/**
 * Where photo frames are kept (photo-frames ADR-0001).
 *
 * - `framePairings/{code}` — a frame waiting to be claimed, top level so the
 *   frame can poll it with no household. Closed to every client.
 * - `frameCredentials/{sha256(secret)}` — which frame a secret is. The
 *   secret itself is never stored. Closed to every client.
 * - `households/{h}/frames/{frameId}` — what family sees, renames, chooses
 *   panels on and deletes. Deleting it is the unlink.
 * - `households/{h}/framePhotos/{photoId}` in Storage — the household's one
 *   screensaver album, which a frame reads only through its secret (ADR-0006).
 */
export const FRAME_PAIRINGS = 'framePairings';
export const FRAME_CREDENTIALS = 'frameCredentials';
export const FRAMES = 'frames';

export function secretHash(secret: string): string {
  return hash('sha256', secret, 'hex');
}

export function framePhotosPrefix(householdId: string): string {
  return `households/${householdId}/framePhotos/`;
}

export function framePairingRef(store: Firestore, code: string): DocumentReference {
  return store.collection(FRAME_PAIRINGS).doc(code);
}

export function frameCredentialRef(store: Firestore, hashed: string): DocumentReference {
  return store.collection(FRAME_CREDENTIALS).doc(hashed);
}

export function framesOf(store: Firestore, householdId: string): CollectionReference {
  return householdRef(store, householdId).collection(FRAMES);
}

export function frameRef(
  store: Firestore,
  householdId: string,
  frameId: string,
): DocumentReference {
  return framesOf(store, householdId).doc(frameId);
}

export const framePairingDocument = z.object({
  secretHash: z.string().min(1),
  model: z.string().nullable().default(null),
  status: z.enum(['waiting', 'linked']),
  expiresAt: z.instanceof(Timestamp),
  householdName: z.string().optional(),
});
export type FramePairingDocument = z.infer<typeof framePairingDocument>;

export const frameCredentialDocument = z.object({
  householdId: z.string().min(1),
  frameId: z.string().min(1),
});
export type FrameCredentialDocument = z.infer<typeof frameCredentialDocument>;

export const FRAME_SHARE_KINDS = ['page', 'recipe'] as const;
export type FrameShareKind = (typeof FRAME_SHARE_KINDS)[number];
export const FRAME_PAGE_ONLY: readonly FrameShareKind[] = ['page'];

const shareCommon = {
  id: z.string().min(1),
  title: z.string().nullable().catch(null),
  by: z.string().catch(''),
  at: z.instanceof(Timestamp),
};

export const frameRecipeShareDocument = z.object({
  ...shareCommon,
  kind: z.literal('recipe'),
  recipe: frameRecipe,
  photoPath: z.string().min(1).nullable().catch(null),
});

/** Shares stored before kinds existed have no `kind` and are pages (photo-frames ADR-0013). */
export const framePageShareDocument = z.object({
  ...shareCommon,
  kind: z.literal('page').optional(),
  url: z.string().min(1),
});

export const frameShareDocument = z.union([frameRecipeShareDocument, framePageShareDocument]);
export type FrameShareDocument = z.infer<typeof frameShareDocument>;

export function shareKind(share: FrameShareDocument): FrameShareKind {
  return share.kind ?? 'page';
}

const frameArea = z.enum(FRAME_AREA_CODES);

/**
 * A frame as stored, read so that a field somebody broke switches its panel
 * off rather than unlinking the frame.
 */
export const frameDocument = z.object({
  name: z.string().catch(''),
  panels: z
    .object({
      calendar: z.boolean().catch(false),
      todos: z.boolean().catch(false),
      meals: z.boolean().catch(false),
      lunch: z.boolean().catch(false),
      addEvents: z.boolean().catch(false),
      share: z.boolean().catch(false),
      people: z.boolean().catch(false),
      helperMemberId: z.string().min(1).nullable().catch(null),
    })
    .catch({
      calendar: false,
      todos: false,
      meals: false,
      lunch: false,
      addEvents: false,
      share: false,
      people: false,
      helperMemberId: null,
    }),
  lastSeenAt: z.instanceof(Timestamp).nullable().catch(null),
  /** Null is off: never set, set to zero minutes, or broken. */
  screensaver: z
    .object({
      idleMinutes: z.literal(SCREENSAVER_IDLE_MINUTES),
      secondsPerPhoto: z.literal(SCREENSAVER_SECONDS_PER_PHOTO),
    })
    .transform((screensaver) => (screensaver.idleMinutes === 0 ? null : screensaver))
    .nullable()
    .catch(null),
  share: frameShareDocument.nullable().catch(null),
  accepts: z.array(z.enum(FRAME_SHARE_KINDS)).catch([...FRAME_PAGE_ONLY]),
  /** Null is off: never set, or broken (ADR-0012). Woolworths carries the store the phone found. */
  groceries: z
    .discriminatedUnion('shop', [
      z.object({ shop: z.literal(['checkers', 'pickNPay']), area: frameArea }),
      z.object({
        shop: z.literal('woolworths'),
        area: frameArea,
        store: z.string().regex(/^[0-9]{1,10}$/),
        priceZone: z.enum(WOOLWORTHS_PRICE_ZONES),
      }),
    ])
    .nullable()
    .catch(null),
});
export type FrameDocument = z.infer<typeof frameDocument>;
export type FrameScreensaver = NonNullable<FrameDocument['screensaver']>;
export type FrameGroceries = NonNullable<FrameDocument['groceries']>;

export function parsed<T extends z.ZodType>(schema: T, data: unknown): z.infer<T> | null {
  const result = schema.safeParse(data);
  return result.success ? result.data : null;
}
