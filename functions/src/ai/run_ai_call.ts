import { logger } from 'firebase-functions/v2';
import type { z } from 'zod';

import { refuseAi, type AiRefusal } from './ai_refusals';
import { isFeatureOn, type AiFeature, type AiSettings } from './ai_settings';
import { NO_USAGE, type GenerativeModel, type ModelRequest } from './generative_model';
import { IMAGE_CALL_LIMITS, callForImage } from './image_call';
import type { ImageModel, ImageReply, ImageRequest } from './image_model';
import {
  DEFAULT_CALL_LIMITS,
  StructuredCallFailure,
  callForJson,
  realClock,
  type CallClock,
  type CallLimits,
  type StructuredFailureKind,
  type StructuredReply,
} from './structured_call';
import type { UsageLedger } from './usage_ledger';

/** What spending one AI call needs, whatever the model makes. */
export interface SpendDependencies {
  readonly ledger: UsageLedger;
  readonly settings: AiSettings;
  readonly now: () => Date;
  readonly limits?: CallLimits;
  readonly clock?: CallClock;
}

/**
 * Everything one AI call needs from outside itself. `aiRuntime()` builds the
 * real one; a test builds its own with a fake model and an in-memory ledger.
 */
export interface AiDependencies extends SpendDependencies {
  readonly model: GenerativeModel;
}

/** The same, for a picture; `imageRuntime()` builds the real one. */
export interface ImageDependencies extends SpendDependencies {
  readonly model: ImageModel;
}

/** Who pays for a call, and under which feature. */
export interface AiSpend {
  readonly feature: AiFeature;
  readonly householdId: string;
  /** The household's zone — its month is the one the call is counted in. */
  readonly timeZone: string;
  readonly uid: string;
}

export interface AiCall<T> extends AiSpend {
  readonly request: ModelRequest;
  /** The shape the answer must parse to; the answer is never cast (ENG-09). */
  readonly schema: z.ZodType<T>;
}

export interface ImageCall extends AiSpend {
  readonly request: ImageRequest;
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
export function runAiCall<T>(deps: AiDependencies, call: AiCall<T>): Promise<AiResult<T>> {
  return spendAiCall(deps, call, deps.model.name, () =>
    callForJson(
      deps.model,
      call.request,
      call.schema,
      deps.limits ?? DEFAULT_CALL_LIMITS,
      deps.clock ?? realClock,
    ),
  );
}

/**
 * One picture, through the same door: switched, capped, charged on success
 * and refunded on failure exactly like a text call (lunch-box ADR-0015).
 */
export function runImageCall(
  deps: ImageDependencies,
  call: ImageCall,
): Promise<AiResult<ImageReply>> {
  return spendAiCall(deps, call, deps.model.name, () =>
    callForImage(
      deps.model,
      call.request,
      deps.limits ?? IMAGE_CALL_LIMITS,
      deps.clock ?? realClock,
    ),
  );
}

/**
 * Steps 1, 2 and 4 above around any [perform], which throws a
 * `StructuredCallFailure` when the model gave the family nothing.
 */
async function spendAiCall<T>(
  deps: SpendDependencies,
  spend: AiSpend,
  modelName: string,
  perform: () => Promise<StructuredReply<T>>,
): Promise<AiResult<T>> {
  if (!isFeatureOn(deps.settings, spend.feature)) throw refuseAi('aiSwitchedOff');

  const claim = await deps.ledger.claim({
    householdId: spend.householdId,
    timeZone: spend.timeZone,
    feature: spend.feature,
    uid: spend.uid,
    now: deps.now(),
    monthlyCalls: deps.settings.monthlyCalls,
  });

  let reply;
  try {
    reply = await perform();
  } catch (error) {
    if (!(error instanceof StructuredCallFailure)) {
      // A bug, not the model: still refunded, then let through as itself (ENG-10).
      await deps.ledger.settle(claim, {
        ok: false,
        reason: 'error',
        usage: NO_USAGE,
        model: modelName,
      });
      throw error;
    }
    await deps.ledger.settle(claim, {
      ok: false,
      reason: error.kind,
      usage: error.usage,
      model: modelName,
    });
    // The detail names a status or a count, never the letter or the reply.
    logger.warn('ai call failed', {
      householdId: spend.householdId,
      feature: spend.feature,
      kind: error.kind,
      detail: error.detail,
      attempts: error.attempts,
    });
    throw refuseAi(REFUSAL_FOR[error.kind]);
  }

  await deps.ledger.settle(claim, { ok: true, usage: reply.usage, model: reply.modelVersion });
  logger.info('ai call', {
    householdId: spend.householdId,
    feature: spend.feature,
    tier: claim.tier,
    attempts: reply.attempts,
    inputTokens: reply.usage.inputTokens,
    outputTokens: reply.usage.outputTokens,
    callsLeft: claim.callsLeft,
  });
  return { value: reply.value, callsLeft: claim.callsLeft };
}
