import { logger } from 'firebase-functions/v2';
import type { z } from 'zod';

import { refuseAi, type AiRefusal } from './ai_refusals';
import { isFeatureOn, type AiFeature, type AiSettings } from './ai_settings';
import { NO_USAGE, type GenerativeModel, type ModelRequest } from './generative_model';
import {
  DEFAULT_CALL_LIMITS,
  StructuredCallFailure,
  callForJson,
  realClock,
  type CallClock,
  type CallLimits,
  type StructuredFailureKind,
} from './structured_call';
import type { UsageLedger } from './usage_ledger';

/**
 * Everything one AI call needs from outside itself. `aiRuntime()` builds the
 * real one; a test builds its own with a fake model and an in-memory ledger.
 */
export interface AiDependencies {
  readonly model: GenerativeModel;
  readonly ledger: UsageLedger;
  readonly settings: AiSettings;
  readonly now: () => Date;
  readonly limits?: CallLimits;
  readonly clock?: CallClock;
}

export interface AiCall<T> {
  readonly feature: AiFeature;
  readonly householdId: string;
  /** The household's zone — its month is the one the call is counted in. */
  readonly timeZone: string;
  readonly uid: string;
  readonly request: ModelRequest;
  /** The shape the answer must parse to; the answer is never cast (ENG-09). */
  readonly schema: z.ZodType<T>;
}

export interface AiResult<T> {
  readonly value: T;
  /** Calls the household has left this month, for the app to say. */
  readonly callsLeft: number;
}

const REFUSAL_FOR: Record<StructuredFailureKind, AiRefusal> = {
  unavailable: 'aiUnavailable',
  unreadable: 'aiUnreadable',
  declined: 'aiDeclined',
};

/**
 * The one way any feature asks the model anything (foundation ADR-0015):
 *
 * 1. the kill switch and the feature's switch, before anything is spent;
 * 2. the household's monthly cap, claimed in a transaction **before** the
 *    call (BE-06) — so the cap cannot be raced past;
 * 3. the call, with its timeouts and retries, and the answer parsed;
 * 4. the claim settled: charged if it worked, refunded if it did not.
 *
 * Callers authorise first — this knows nothing of households or grants — and
 * send the model only what the feature needs (the ADR's POPIA section).
 */
export async function runAiCall<T>(deps: AiDependencies, call: AiCall<T>): Promise<AiResult<T>> {
  if (!isFeatureOn(deps.settings, call.feature)) throw refuseAi('aiSwitchedOff');

  const claim = await deps.ledger.claim({
    householdId: call.householdId,
    timeZone: call.timeZone,
    feature: call.feature,
    uid: call.uid,
    now: deps.now(),
    monthlyCalls: deps.settings.monthlyCalls,
  });

  let reply;
  try {
    reply = await callForJson(
      deps.model,
      call.request,
      call.schema,
      deps.limits ?? DEFAULT_CALL_LIMITS,
      deps.clock ?? realClock,
    );
  } catch (error) {
    if (!(error instanceof StructuredCallFailure)) {
      // A bug, not the model: still refunded, then let through as itself (ENG-10).
      await deps.ledger.settle(claim, {
        ok: false,
        reason: 'error',
        usage: NO_USAGE,
        model: deps.model.name,
      });
      throw error;
    }
    await deps.ledger.settle(claim, {
      ok: false,
      reason: error.kind,
      usage: error.usage,
      model: deps.model.name,
    });
    // The detail names a status or a count, never the letter or the reply.
    logger.warn('ai call failed', {
      householdId: call.householdId,
      feature: call.feature,
      kind: error.kind,
      detail: error.detail,
      attempts: error.attempts,
    });
    throw refuseAi(REFUSAL_FOR[error.kind]);
  }

  await deps.ledger.settle(claim, { ok: true, usage: reply.usage, model: reply.modelVersion });
  logger.info('ai call', {
    householdId: call.householdId,
    feature: call.feature,
    tier: claim.tier,
    attempts: reply.attempts,
    inputTokens: reply.usage.inputTokens,
    outputTokens: reply.usage.outputTokens,
    callsLeft: claim.callsLeft,
  });
  return { value: reply.value, callsLeft: claim.callsLeft };
}
