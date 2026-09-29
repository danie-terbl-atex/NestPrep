import { FieldValue, type DocumentReference, type Firestore } from 'firebase-admin/firestore';

import { householdRef } from '../household/documents';
import { refuseAi } from './ai_refusals';
import type { AiClaim, ClaimRequest, Settlement, UsageLedger } from './usage_ledger';
import { capFor, decideClaim, monthKeyIn, readMonthUsage, tierFrom } from './usage_rules';

/**
 * The monthly ledger in Firestore (foundation ADR-0015):
 *
 * - `households/{h}/aiUsage/{YYYY-MM}` — the month's counters: `calls`
 *   (charged), `attempts` (started), tokens in and out, per feature.
 * - `households/{h}/aiUsage/{YYYY-MM}/calls/{callId}` — one line per call:
 *   the feature, the tier, the uid that asked, how it went and what it cost
 *   in tokens. Never the request, never the reply, never a name (ENG-22).
 *
 * Only Functions touch either; no client may read or write them
 * (`rules/firestore/household/ai_usage.rules`).
 */
export const AI_USAGE = 'aiUsage';
export const AI_CALLS = 'calls';
export const ENTITLEMENT = 'entitlement';
export const CURRENT_ENTITLEMENT = 'current';

export function monthRef(store: Firestore, householdId: string, month: string): DocumentReference {
  return householdRef(store, householdId).collection(AI_USAGE).doc(month);
}

export class FirestoreUsageLedger implements UsageLedger {
  constructor(private readonly store: Firestore) {}

  async claim(request: ClaimRequest): Promise<AiClaim> {
    const month = monthKeyIn(request.timeZone, request.now);
    const usageRef = monthRef(this.store, request.householdId, month);
    const callRef = usageRef.collection(AI_CALLS).doc();
    const entitlementRef = householdRef(this.store, request.householdId)
      .collection(ENTITLEMENT)
      .doc(CURRENT_ENTITLEMENT);

    return this.store.runTransaction(async (transaction) => {
      const [usage, entitlement] = await Promise.all([
        transaction.get(usageRef),
        transaction.get(entitlementRef),
      ]);
      const tier = tierFrom(entitlement.data(), request.now);
      const decision = decideClaim(
        readMonthUsage(usage.data()),
        capFor(tier, request.monthlyCalls),
      );
      if (!decision.allowed) throw refuseAi('aiLimitReached');

      transaction.set(
        usageRef,
        {
          calls: FieldValue.increment(1),
          attempts: FieldValue.increment(1),
          byFeature: { [request.feature]: FieldValue.increment(1) },
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      transaction.set(callRef, {
        feature: request.feature,
        tier,
        uid: request.uid,
        status: 'claimed',
        claimedAt: FieldValue.serverTimestamp(),
      });
      return {
        householdId: request.householdId,
        month,
        callId: callRef.id,
        feature: request.feature,
        tier,
        callsLeft: decision.callsLeft,
      };
    });
  }

  async settle(claim: AiClaim, settlement: Settlement): Promise<void> {
    const usageRef = monthRef(this.store, claim.householdId, claim.month);
    const callRef = usageRef.collection(AI_CALLS).doc(claim.callId);
    await this.store.runTransaction(async (transaction) => {
      const call = await transaction.get(callRef);
      if (call.get('status') !== 'claimed') return;
      transaction.update(callRef, {
        status: settlement.ok ? 'succeeded' : 'failed',
        failure: settlement.ok ? null : settlement.reason,
        model: settlement.model,
        inputTokens: settlement.usage.inputTokens,
        outputTokens: settlement.usage.outputTokens,
        settledAt: FieldValue.serverTimestamp(),
      });
      transaction.set(
        usageRef,
        {
          // A failed call gave the family nothing, so it is not charged.
          ...(settlement.ok ? {} : { calls: FieldValue.increment(-1) }),
          inputTokens: FieldValue.increment(settlement.usage.inputTokens),
          outputTokens: FieldValue.increment(settlement.usage.outputTokens),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });
  }
}
