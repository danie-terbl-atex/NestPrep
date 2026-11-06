import { type DocumentReference, type Firestore, Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';

import {
  type CountableRelease,
  FRAME_DEVICE_RINGS,
  FRAME_RELEASE_STAGES,
  FRAME_UPDATE_APPS,
  type FrameUpdateApp,
  releaseIdOf,
} from './frame_update_policy';

export const FRAME_RELEASES = 'frameReleases';
export const FRAME_DEVICES = 'frameDevices';

export function frameReleaseRef(
  store: Firestore,
  app: FrameUpdateApp,
  versionCode: number,
): DocumentReference {
  return store.collection(FRAME_RELEASES).doc(releaseIdOf(app, versionCode));
}

export function frameDeviceRef(store: Firestore, deviceId: string): DocumentReference {
  return store.collection(FRAME_DEVICES).doc(deviceId);
}

const count = z.number().int().nonnegative().catch(0);

export const frameReleaseDocument = z.object({
  app: z.enum(FRAME_UPDATE_APPS),
  versionCode: z.number().int().positive(),
  versionName: z.string(),
  minSdk: z.number().int(),
  size: z.number().int().nonnegative(),
  sha256: z.string().regex(/^[0-9a-f]{64}$/),
  storagePath: z.string().startsWith(`${FRAME_RELEASES}/`),
  stage: z.enum(FRAME_RELEASE_STAGES),
  paused: z.boolean(),
  /** Anything but a string or nothing still reads as a fault build: the guard fails closed. */
  fault: z
    .string()
    .nullish()
    .transform((fault) => fault ?? null)
    .catch('unreadable'),
  stagedAt: z
    .instanceof(Timestamp)
    .nullish()
    .transform((at) => at ?? null)
    .catch(null),
  attempts: count,
  successes: count,
  rollbacks: count,
});
export type FrameReleaseDocument = z.infer<typeof frameReleaseDocument>;
export type FrameRelease = FrameReleaseDocument & CountableRelease;

/** A release only when it parses and its doc id is its own `{app}-{versionCode}`. */
export function parsedRelease(id: string, data: unknown): FrameRelease | null {
  const result = frameReleaseDocument.safeParse(data);
  if (!result.success || releaseIdOf(result.data.app, result.data.versionCode) !== id) return null;
  return { ...result.data, id };
}

function entriesOf<T extends z.ZodType>(entry: T): z.ZodType<Record<string, z.infer<T>>> {
  return z
    .record(z.string(), z.unknown())
    .catch({})
    .transform((map) =>
      Object.fromEntries(
        Object.entries(map).flatMap(([key, value]): [string, z.infer<T>][] => {
          const result = entry.safeParse(value);
          return result.success ? [[key, result.data]] : [];
        }),
      ),
    );
}

const storedEvent = z.looseObject({ id: z.string() });

export const frameDeviceDocument = z.object({
  ring: z.enum(FRAME_DEVICE_RINGS).catch('standard'),
  installNowUntil: z.instanceof(Timestamp).nullable().catch(null),
  events: z
    .array(z.unknown())
    .catch([])
    .transform((events) =>
      events.flatMap((event) => {
        const result = storedEvent.safeParse(event);
        return result.success ? [result.data] : [];
      }),
    ),
  fetched: entriesOf(z.instanceof(Timestamp)),
  counted: entriesOf(z.array(z.string())),
  rollbacks: count,
});
export type FrameDeviceDocument = z.infer<typeof frameDeviceDocument>;
