import { Timestamp, type Firestore } from 'firebase-admin/firestore';

import { NO_USAGE } from '../ai/generative_model';
import { StructuredCallFailure } from '../ai/structured_call';

export const IMAGE_GAP_MS = 60_000;
export const IMAGE_WAIT_MAX_MS = 2 * 60_000;
export const IMAGE_PACING_PATH = 'aiPacing/image';

export interface PacingClock {
  now(): number;
  sleep(ms: number): Promise<void>;
}

const realPacingClock: PacingClock = {
  now: () => Date.now(),
  sleep: (ms) => new Promise((resolve) => setTimeout(resolve, ms)),
};

export function imageTurnAfter(reserved: number, now: number): number | null {
  const at = Math.max(now, reserved);
  return at - now > IMAGE_WAIT_MAX_MS ? null : at;
}

/**
 * Vertex grants the image model about one picture a minute, so creations take
 * turns: each reserves the next free minute and waits for it. A queue longer
 * than the trigger can wait fails the request, which refunds it.
 */
export async function waitForImageTurn(
  store: Firestore,
  clock: PacingClock = realPacingClock,
): Promise<void> {
  const ref = store.doc(IMAGE_PACING_PATH);
  const turn = await store.runTransaction(async (transaction) => {
    const next = (await transaction.get(ref)).get('nextAt') as unknown;
    const at = imageTurnAfter(next instanceof Timestamp ? next.toMillis() : 0, clock.now());
    if (at === null) return null;
    transaction.set(ref, { nextAt: Timestamp.fromMillis(at + IMAGE_GAP_MS) });
    return at;
  });
  if (turn === null) {
    throw new StructuredCallFailure('unavailable', 'image queue full', NO_USAGE, 0);
  }
  const wait = turn - clock.now();
  if (wait > 0) await clock.sleep(wait);
}
