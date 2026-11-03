import { FieldValue, Timestamp, type Firestore, type Transaction } from 'firebase-admin/firestore';

import { HOUSEHOLDS } from '../../household/documents';
import { consumeRateLimit, type RateLimitRule } from '../../shared/rate_limit';
import {
  ACTIVITY_RETENTION_DAYS,
  ASSISTANT_ACTIVITY,
  type ActivityTargetKind,
  type StoredActivity,
} from '../connections/connection_documents';
import { AssistantRefusal, type AssistantPrincipal } from '../principal';

export interface ActivityTarget {
  readonly kind: ActivityTargetKind;
  readonly id: string;
}

/** Whose call it was: the connection and the member it acts as. */
export interface ActivityActor {
  readonly principal: AssistantPrincipal;
  readonly memberId: string;
}

/**
 * Stages one `assistantActivity` line per target on the write's own
 * transaction (assistants ADR-0005), in the shape the export reads back.
 */
export function recordActivity(
  transaction: Transaction,
  store: Firestore,
  actor: ActivityActor,
  tool: string,
  targets: readonly ActivityTarget[],
  now: Date,
): void {
  const log = store
    .collection(HOUSEHOLDS)
    .doc(actor.principal.householdId)
    .collection(ASSISTANT_ACTIVITY);
  const expiresAt = Timestamp.fromMillis(now.getTime() + ACTIVITY_RETENTION_DAYS * 86_400_000);
  for (const target of targets) {
    const line: Omit<StoredActivity, 'at'> & { at: FieldValue } = {
      grantId: actor.principal.grantId,
      memberId: actor.memberId,
      via: actor.principal.via,
      tool,
      target: { kind: target.kind, id: target.id },
      at: FieldValue.serverTimestamp(),
      expiresAt,
    };
    transaction.set(log.doc(), line);
  }
}

/** Write calls one connection may make in an hour (assistants ADR-0001). */
export const ASSISTANT_WRITES: RateLimitRule = {
  name: 'assistantWrites',
  limit: 60,
  windowSeconds: 3600,
};

/** Counts one write call against the connection, or refuses `rateLimited`. */
export async function consumeWriteAllowance(
  store: Firestore,
  principal: AssistantPrincipal,
  now: Date,
): Promise<void> {
  if (await consumeRateLimit(store, ASSISTANT_WRITES, principal.grantId, now)) return;
  throw new AssistantRefusal(
    'rateLimited',
    'writeLimit',
    'This assistant has made a lot of changes in the last hour. Try again later.',
  );
}
