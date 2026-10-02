import type { z } from 'zod';

import {
  ModelCallError,
  NO_USAGE,
  addUsage,
  type GenerativeModel,
  type ModelRequest,
  type ModelUsage,
} from './generative_model';

/**
 * How long, and how often, one AI call may try (BE-19). The callable around it
 * has sixty seconds; these leave room for the ledger on either side.
 */
export interface CallLimits {
  /** Attempts in all, the first included. */
  readonly attempts: number;
  readonly perAttemptMs: number;
  /** No new attempt starts once this much time has gone. */
  readonly budgetMs: number;
  /** The wait before the second, third… attempt. */
  readonly backoffMs: readonly number[];
}

export const DEFAULT_CALL_LIMITS: CallLimits = {
  attempts: 3,
  perAttemptMs: 25_000,
  budgetMs: 45_000,
  backoffMs: [1_000, 3_000],
};

/** What the call needs from the outside world, injected so tests control time. */
export interface CallClock {
  now(): number;
  sleep(ms: number): Promise<void>;
}

export const realClock: CallClock = {
  now: () => Date.now(),
  sleep: (ms) =>
    new Promise((resolve) => {
      setTimeout(resolve, ms);
    }),
};

export interface StructuredReply<T> {
  readonly value: T;
  readonly usage: ModelUsage;
  readonly attempts: number;
  readonly modelVersion: string;
}

/**
 * Why no usable answer came back. `unavailable`: the model could not be
 * reached or kept failing; `unreadable`: it answered, but not in the shape
 * asked for, twice; `declined`: it refused the content.
 */
export type StructuredFailureKind = 'unavailable' | 'unreadable' | 'declined';

export class StructuredCallFailure extends Error {
  constructor(
    readonly kind: StructuredFailureKind,
    readonly detail: string,
    readonly usage: ModelUsage,
    readonly attempts: number,
  ) {
    super(`${kind}: ${detail}`);
    this.name = 'StructuredCallFailure';
  }
}

/**
 * Asks [model] and parses its answer as JSON of [schema] — or fails with a
 * reason (foundation ADR-0015).
 *
 * Retries a timeout, a rate limit or a server error, with backoff, within the
 * budget; retries a reply that does not parse **once**, because a model that
 * wandered off the schema usually comes back to it and a second wander means
 * the input is the problem. A refusal or a bad request is never retried.
 * Every attempt's tokens are counted, the failed ones included — they are
 * billed all the same.
 */
export async function callForJson<T>(
  model: GenerativeModel,
  request: ModelRequest,
  schema: z.ZodType<T>,
  limits: CallLimits = DEFAULT_CALL_LIMITS,
  clock: CallClock = realClock,
): Promise<StructuredReply<T>> {
  const startedAt = clock.now();
  let usage = NO_USAGE;
  let unreadableReplies = 0;
  let lastDetail = 'not attempted';
  let lastWasUnreadable = false;
  let made = 0;

  for (let attempt = 1; attempt <= limits.attempts; attempt += 1) {
    if (!(await mayAttempt(attempt, startedAt, limits, clock))) break;
    made = attempt;
    const outcome = await attemptWithin(limits.perAttemptMs, (signal) =>
      model.generate(request, signal),
    );
    if (outcome.kind === 'reply') {
      usage = addUsage(usage, outcome.reply.usage);
      const parsed = parseReply(outcome.reply.text, schema);
      if (parsed.success) {
        return {
          value: parsed.value,
          usage,
          attempts: attempt,
          modelVersion: outcome.reply.modelVersion,
        };
      }
      unreadableReplies += 1;
      lastDetail = parsed.detail;
      lastWasUnreadable = true;
      if (unreadableReplies >= 2) {
        throw new StructuredCallFailure('unreadable', lastDetail, usage, attempt);
      }
      continue;
    }
    usage = addUsage(usage, outcome.error.usage);
    lastDetail = outcome.error.detail;
    lastWasUnreadable = false;
    const final = finalFailureOf(outcome.error);
    if (final !== null) throw new StructuredCallFailure(final, lastDetail, usage, attempt);
  }
  const kind = lastWasUnreadable ? 'unreadable' : 'unavailable';
  throw new StructuredCallFailure(kind, lastDetail, usage, made);
}

/**
 * Whether attempt number [attempt] may start, after its backoff: never once
 * the budget has gone. The first always may, at once.
 */
export async function mayAttempt(
  attempt: number,
  startedAt: number,
  limits: CallLimits,
  clock: CallClock,
): Promise<boolean> {
  if (attempt === 1) return true;
  if (clock.now() - startedAt >= limits.budgetMs) return false;
  await clock.sleep(limits.backoffMs[attempt - 2] ?? limits.backoffMs.at(-1) ?? 0);
  return true;
}

/**
 * What a model failure ends the call as, or null when it is worth another
 * attempt: a refusal is `declined`, a bad request `unavailable`.
 */
export function finalFailureOf(error: ModelCallError): StructuredFailureKind | null {
  if (error.kind === 'blocked') return 'declined';
  return error.isWorthRetrying ? null : 'unavailable';
}

export type Attempt<R> =
  | { readonly kind: 'reply'; readonly reply: R }
  | { readonly kind: 'failed'; readonly error: ModelCallError };

/** One attempt, aborted after [perAttemptMs]. */
export async function attemptWithin<R>(
  perAttemptMs: number,
  run: (signal: AbortSignal) => Promise<R>,
): Promise<Attempt<R>> {
  const controller = new AbortController();
  const timer = setTimeout(() => {
    controller.abort();
  }, perAttemptMs);
  try {
    return { kind: 'reply', reply: await run(controller.signal) };
  } catch (error) {
    // Anything that is not the model's own error is a bug in an adapter, and
    // is let through rather than dressed up as a transient failure (ENG-10).
    if (!(error instanceof ModelCallError)) throw error;
    return { kind: 'failed', error };
  } finally {
    clearTimeout(timer);
  }
}

type Parsed<T> = { success: true; value: T } | { success: false; detail: string };

/** JSON first, then the schema; either failing is an unreadable reply. */
export function parseReply<T>(text: string, schema: z.ZodType<T>): Parsed<T> {
  let json: unknown;
  try {
    json = JSON.parse(stripFence(text));
  } catch {
    return { success: false, detail: 'shape: not JSON' };
  }
  const result = schema.safeParse(json);
  return result.success
    ? { success: true, value: result.data }
    : { success: false, detail: `shape: ${String(result.error.issues.length)} issue(s)` };
}

/** A model asked for JSON sometimes still wraps it in a Markdown fence. */
function stripFence(text: string): string {
  const trimmed = text.trim();
  const fenced = /^```(?:json)?\s*([\s\S]*?)\s*```$/.exec(trimmed);
  return fenced?.[1] ?? trimmed;
}
