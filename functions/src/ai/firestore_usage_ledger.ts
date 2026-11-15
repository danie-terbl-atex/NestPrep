import { FieldValue, type DocumentReference, type Firestore } from 'firebase-admin/firestore';

import { householdRef } from '../household/documents';
import { entitlementRef } from '../subscriptions/subscription_documents';
import { refuseClaim } from './ai_refusals';
import type { AiClaim, ClaimRequest, Settlement, UsageLedger } from './usage_ledger';
import { chargeOf, type AiFeature, type AiSettings } from './ai_settings';
import {
  ALLOWANCE_ATTEMPTS,
  LIFETIME_USAGE,
  allowanceAttemptsLeft,
  allowanceAttemptsOf,
  allowanceLeft,
  capFor,
  countOf,
  decideCharge,
  monthKeyIn,
  readMonthUsage,
  tierFrom,
  type AiTier,
} from './usage_rules';

/**
 * The monthly ledger in Firestore (foundation ADR-0015):
 *
 * - `households/{h}/aiUsage/{YYYY-MM}` — the month's counters: `calls`
 *   (charged), `attempts` (started), tokens in and out, per feature, and
 *   `allowanceAttempts` (started for an allowance, its checks included).
 * - `households/{h}/aiUsage/{YYYY-MM}/calls/{callId}` — one line per call:
 *   the feature, the tier, the uid that asked, how it went and what it cost
 *   in tokens. Never the request, never the reply, never a name (ENG-22).
 *
 * Only Functions touch either; no client may read or write them
 * (`rules/firestore/household/ai_usage.rules`).
 */
export const AI_USAGE = 'aiUsage';
export const AI_CALLS = 'calls';

export function monthRef(store: Firestore, householdId: string, month: string): DocumentReference {
  return householdRef(store, householdId).collection(AI_USAGE).doc(month);
}

export function lifetimeRef(store: Firestore, householdId: string): DocumentReference {
  return householdRef(store, householdId).collection(AI_USAGE).doc(LIFETIME_USAGE);
}

export class FirestoreUsageLedger implements UsageLedger {
  constructor(private readonly store: Firestore) {}

  async claim(request: ClaimRequest): Promise<AiClaim> {
    const month = monthKeyIn(request.timeZone, request.now);
    const usageRef = monthRef(this.store, request.householdId, month);
    const everRef = lifetimeRef(this.store, request.householdId);
    const callRef = usageRef.collection(AI_CALLS).doc();
    // The household's premium, from the one document subscriptions writes
    // (subscriptions ADR-0001) — read in this transaction, so the cap and the
    // claim see the same entitlement.
    const premiumRef = entitlementRef(this.store, request.householdId);
    const { charge } = request;

    return this.store.runTransaction(async (transaction) => {
      const [usage, entitlement, ever] = await transaction.getAll(usageRef, premiumRef, everRef);
      const tier = tierFrom(entitlement?.data(), request.now);
      const shares = charge.kind === 'allowance' ? charge.shares : [];
      const decision = decideCharge(
        charge,
        readMonthUsage(usage?.data()),
        capFor(tier, request.monthlyCalls),
        tier,
        {
          month: countOf(usage?.data(), shares),
          lifetime: countOf(ever?.data(), shares),
          attempts: charge.kind === 'calls' ? 0 : allowanceAttemptsOf(usage?.data(), charge.name),
        },
      );
      if (!decision.allowed) throw refuseClaim(tier, request.feature);

      const counted = { [request.feature]: FieldValue.increment(1) };
      transaction.set(
        usageRef,
        {
          ...(charge.kind === 'calls'
            ? { calls: FieldValue.increment(1), attempts: FieldValue.increment(1) }
            : { [ALLOWANCE_ATTEMPTS]: { [charge.name]: FieldValue.increment(1) } }),
          byFeature: counted,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      if (charge.kind === 'allowance') {
        transaction.set(
          everRef,
          { byFeature: counted, updatedAt: FieldValue.serverTimestamp() },
          { merge: true },
        );
      }
      transaction.set(callRef, {
        feature: request.feature,
        tier,
        charge: charge.kind,
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
        charge: charge.kind,
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
      const refund = settlement.ok ? 'none' : claim.charge;
      const uncounted = { [claim.feature]: FieldValue.increment(-1) };
      transaction.set(
        usageRef,
        {
          // A failed call gave the family nothing, so it is not charged.
          ...(refund === 'calls' ? { calls: FieldValue.increment(-1) } : {}),
          ...(refund === 'allowance' ? { byFeature: uncounted } : {}),
          inputTokens: FieldValue.increment(settlement.usage.inputTokens),
          outputTokens: FieldValue.increment(settlement.usage.outputTokens),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      if (refund === 'allowance') {
        transaction.set(
          lifetimeRef(this.store, claim.householdId),
          { byFeature: uncounted, updatedAt: FieldValue.serverTimestamp() },
          { merge: true },
        );
      }
    });
  }
}

export interface AllowanceStanding {
  readonly tier: AiTier;
  readonly left: number;
  readonly attemptsLeft: number;
}

/**
 * What [feature]'s allowance leaves the household now, read before anything
 * is spent so a request can be refused with the right reason. The claim
 * decides again in its own transaction.
 */
export async function allowanceStanding(
  store: Firestore,
  request: {
    readonly householdId: string;
    readonly timeZone: string;
    readonly feature: AiFeature;
    readonly now: Date;
    readonly settings: AiSettings;
  },
): Promise<AllowanceStanding | null> {
  const charge = chargeOf(request.settings, request.feature);
  if (charge.kind !== 'allowance') return null;
  const month = monthKeyIn(request.timeZone, request.now);
  const [usage, entitlement, ever] = await store.getAll(
    monthRef(store, request.householdId, month),
    entitlementRef(store, request.householdId),
    lifetimeRef(store, request.householdId),
  );
  const tier = tierFrom(entitlement?.data(), request.now);
  const used = {
    month: countOf(usage?.data(), charge.shares),
    lifetime: countOf(ever?.data(), charge.shares),
    attempts: allowanceAttemptsOf(usage?.data(), charge.name),
  };
  return {
    tier,
    left: allowanceLeft(tier, used, charge.allowance),
    attemptsLeft: allowanceAttemptsLeft(tier, used, charge.allowance),
  };
}
