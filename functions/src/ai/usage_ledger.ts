import type { AiFeature, MonthlyCalls } from './ai_settings';
import type { ModelUsage } from './generative_model';
import type { AiTier } from './usage_rules';

/**
 * Where a household's AI calls are counted (foundation ADR-0015). An
 * interface so `runAiCall` is tested against an in-memory ledger and the
 * Firestore one is tested once, around the emulator.
 */
export interface ClaimRequest {
  readonly householdId: string;
  readonly timeZone: string;
  readonly feature: AiFeature;
  /** The account that asked — a uid, never a name (ENG-22). */
  readonly uid: string;
  readonly now: Date;
  readonly monthlyCalls: MonthlyCalls;
}

/** A call the household has been charged for, until it is settled. */
export interface AiClaim {
  readonly householdId: string;
  readonly month: string;
  readonly callId: string;
  readonly feature: AiFeature;
  readonly tier: AiTier;
  /** What is left this month once this call is counted. */
  readonly callsLeft: number;
}

export type Settlement =
  | { readonly ok: true; readonly usage: ModelUsage; readonly model: string }
  | {
      readonly ok: false;
      readonly reason: string;
      readonly usage: ModelUsage;
      readonly model: string;
    };

export interface UsageLedger {
  /**
   * Counts one call against this month **before** the model is asked, in a
   * transaction, so two calls at once cannot both take the last one (BE-06).
   * Throws the `aiLimitReached` refusal when the month is spent.
   */
  claim(request: ClaimRequest): Promise<AiClaim>;

  /**
   * Records how the call went. A failed call is refunded — the family got
   * nothing — but its attempt still counts. Settling twice changes nothing.
   */
  settle(claim: AiClaim, settlement: Settlement): Promise<void>;
}
