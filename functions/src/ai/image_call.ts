import { NO_USAGE } from './generative_model';
import type { ImageModel, ImageReply, ImageRequest } from './image_model';
import {
  StructuredCallFailure,
  attemptWithin,
  finalFailureOf,
  mayAttempt,
  realClock,
  type CallClock,
  type CallLimits,
  type StructuredReply,
} from './structured_call';

/**
 * An image takes far longer than a JSON answer, so it gets fewer, longer
 * attempts — inside the callable's 120 seconds, with room for the ledger and
 * the upload (BE-19).
 */
export const IMAGE_CALL_LIMITS: CallLimits = {
  attempts: 2,
  perAttemptMs: 60_000,
  budgetMs: 100_000,
  backoffMs: [2_000],
};

/**
 * Asks [model] for one image, retrying a timeout, a rate limit or a server
 * error within the budget — the same policy as `callForJson`, with no reply to
 * parse. An image is billed per picture, not in tokens, so its usage is none.
 */
export async function callForImage(
  model: ImageModel,
  request: ImageRequest,
  limits: CallLimits = IMAGE_CALL_LIMITS,
  clock: CallClock = realClock,
): Promise<StructuredReply<ImageReply>> {
  const startedAt = clock.now();
  let lastDetail = 'not attempted';
  let made = 0;

  for (let attempt = 1; attempt <= limits.attempts; attempt += 1) {
    if (!(await mayAttempt(attempt, startedAt, limits, clock))) break;
    made = attempt;
    const outcome = await attemptWithin(limits.perAttemptMs, (signal) =>
      model.generate(request, signal),
    );
    if (outcome.kind === 'reply') {
      return {
        value: outcome.reply,
        usage: NO_USAGE,
        attempts: attempt,
        modelVersion: outcome.reply.modelVersion,
      };
    }
    lastDetail = outcome.error.detail;
    const final = finalFailureOf(outcome.error);
    if (final !== null) throw new StructuredCallFailure(final, lastDetail, NO_USAGE, attempt);
  }
  throw new StructuredCallFailure('unavailable', lastDetail, NO_USAGE, made);
}
