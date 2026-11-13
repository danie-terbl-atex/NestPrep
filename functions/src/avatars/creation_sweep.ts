import { FieldValue, type DocumentReference, type Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import type { AiFeature } from '../ai/ai_settings';
import { AI_CALLS, monthRef } from '../ai/firestore_usage_ledger';
import { NO_USAGE } from '../ai/generative_model';
import type { UsageLedger } from '../ai/usage_ledger';
import { monthKeyIn } from '../ai/usage_rules';
import type { ObjectStore } from '../shared/storage';
import {
  AVATAR_CREATIONS,
  avatarInboxPath,
  avatarKeepsakePath,
  avatarKeepsakeRef,
} from './avatar_refs';

/**
 * A creation whose run died (a crash, a timeout, a deploy mid-draw) stays at
 * `checking` or `drawing` for ever, because a trigger is not retried, and
 * keeps its reference in the inbox and its claim on the allowance (avatars
 * ADR-0003). A run lasts five minutes at most, so after an hour nothing is
 * still working on it.
 */
export const STUCK_AFTER_MS = 60 * 60 * 1000;
export const STUCK_STATUSES = ['checking', 'drawing'] as const;
export const SWEEP_PAGE = 100;

const CREATION_FEATURES: readonly AiFeature[] = ['avatarCheck', 'avatarCreate', 'avatarPortrait'];
const LEDGER_SKEW_MS = 10 * 60 * 1000;

export type StuckEnding = 'ready' | 'failed';

/**
 * How a stuck creation ends. One whose picture was already kept is ready: the
 * keep is the last thing a run does before it settles, and the family has
 * the picture.
 */
export function stuckEnding(creation: Record<string, unknown>): StuckEnding {
  return typeof creation['imageHash'] === 'string' && typeof creation['keepsakeId'] === 'string'
    ? 'ready'
    : 'failed';
}

export function isAbandonedClaim(call: Record<string, unknown>, cutoff: Date): boolean {
  const claimedAt = call['claimedAt'];
  return (
    call['status'] === 'claimed' &&
    CREATION_FEATURES.includes(call['feature'] as AiFeature) &&
    isTimestamp(claimedAt) &&
    claimedAt.toMillis() < cutoff.getTime()
  );
}

/** The months a creation asked for at [requestedAt] may have been counted in. */
export function ledgerMonths(timeZone: string, requestedAt: Date): string[] {
  return [
    ...new Set([
      monthKeyIn(timeZone, requestedAt),
      monthKeyIn(timeZone, new Date(requestedAt.getTime() + LEDGER_SKEW_MS)),
    ]),
  ];
}

function isTimestamp(value: unknown): value is { toMillis(): number; toDate(): Date } {
  return typeof value === 'object' && value !== null && 'toMillis' in value && 'toDate' in value;
}

export interface SweepDeps {
  readonly store: Firestore;
  readonly objects: Pick<ObjectStore, 'deleteObjects'>;
  readonly ledger: UsageLedger;
}

export interface SweepCount {
  readonly failed: number;
  readonly ready: number;
  readonly refunded: number;
}

export async function sweepStuckCreations(deps: SweepDeps, now: Date): Promise<SweepCount> {
  const cutoff = new Date(now.getTime() - STUCK_AFTER_MS);
  const stuck = await deps.store
    .collectionGroup(AVATAR_CREATIONS)
    .where('status', 'in', [...STUCK_STATUSES])
    .where('requestedAt', '<', cutoff)
    .limit(SWEEP_PAGE)
    .get();

  const count = { failed: 0, ready: 0, refunded: 0 };
  const ended: { home: DocumentReference; requestedAt: unknown; ending: StuckEnding }[] = [];
  for (const creation of stuck.docs) {
    const home = creation.ref.parent.parent;
    if (home === null) continue;
    const ending = await end(deps.store, creation.ref);
    if (ending === null) continue;
    count[ending] += 1;
    ended.push({ home, requestedAt: creation.get('requestedAt'), ending });
    await deps.objects.deleteObjects(await leftovers(deps.store, home.id, creation, ending));
  }

  for (const householdId of new Set(ended.map(({ home }) => home.id))) {
    const here = ended.filter(({ home }) => home.id === householdId);
    // A kept picture's claim is rightly charged, and a claim does not say which creation it is for.
    if (here.some(({ ending }) => ending === 'ready')) continue;
    const asked = here.flatMap(({ requestedAt }) =>
      isTimestamp(requestedAt) ? [requestedAt.toDate()] : [],
    );
    const home = here[0]?.home;
    if (home !== undefined) count.refunded += await refund(deps, home, asked, cutoff);
  }
  logger.info('stuck avatar creations swept', count);
  return count;
}

async function end(store: Firestore, ref: DocumentReference): Promise<StuckEnding | null> {
  return store.runTransaction(async (transaction) => {
    const creation = await transaction.get(ref);
    const status: unknown = creation.get('status');
    if (!STUCK_STATUSES.some((stuck) => stuck === status)) return null;
    const ending = stuckEnding(creation.data() ?? {});
    transaction.update(ref, {
      status: ending,
      ...(ending === 'failed' ? { reason: 'unavailable' } : {}),
      settledAt: FieldValue.serverTimestamp(),
    });
    return ending;
  });
}

async function leftovers(
  store: Firestore,
  householdId: string,
  creation: FirebaseFirestore.QueryDocumentSnapshot,
  ending: StuckEnding,
): Promise<string[]> {
  const memberId: unknown = creation.get('memberId');
  const inboxId: unknown = creation.get('inboxId');
  if (typeof memberId !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(memberId)) return [];
  const paths: string[] = [];
  if (typeof inboxId === 'string' && /^[A-Za-z0-9_-]{8,64}$/.test(inboxId)) {
    paths.push(avatarInboxPath(householdId, memberId, inboxId));
  }
  if (ending === 'failed') {
    const keepsake = await avatarKeepsakeRef(store, householdId, creation.id).get();
    if (!keepsake.exists) paths.push(avatarKeepsakePath(householdId, memberId, creation.id));
  }
  return paths;
}

async function refund(
  deps: SweepDeps,
  home: DocumentReference,
  requestedAt: readonly Date[],
  cutoff: Date,
): Promise<number> {
  const zone: unknown = (await home.get()).get('timeZone');
  const timeZone = typeof zone === 'string' ? zone : 'UTC';
  const keys = new Set(requestedAt.flatMap((at) => ledgerMonths(timeZone, at)));
  let refunded = 0;
  for (const month of keys) {
    const claimed = await monthRef(deps.store, home.id, month)
      .collection(AI_CALLS)
      .where('status', '==', 'claimed')
      .limit(SWEEP_PAGE)
      .get();
    for (const call of claimed.docs) {
      if (!isAbandonedClaim(call.data(), cutoff)) continue;
      const charge: unknown = call.get('charge');
      if (charge !== 'allowance' && charge !== 'none') continue;
      await deps.ledger.settle(
        {
          householdId: home.id,
          month,
          callId: call.id,
          feature: call.get('feature') as AiFeature,
          tier: call.get('tier') === 'premium' ? 'premium' : 'free',
          charge,
          callsLeft: 0,
        },
        { ok: false, reason: 'abandoned', usage: NO_USAGE, model: 'unknown' },
      );
      refunded += 1;
    }
  }
  return refunded;
}
