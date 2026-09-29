import { HttpsError } from 'firebase-functions/v2/https';
import { expect } from 'vitest';

import {
  ModelCallError,
  type GenerativeModel,
  type ModelReply,
  type ModelRequest,
} from '../../../src/ai/generative_model';
import type { CallClock } from '../../../src/ai/structured_call';
import type { AiClaim, ClaimRequest, Settlement, UsageLedger } from '../../../src/ai/usage_ledger';
import { decideClaim, tierFrom, type MonthUsage } from '../../../src/ai/usage_rules';
import { refuseAi } from '../../../src/ai/ai_refusals';

/** A scripted attempt that never answers until it is aborted. */
export const HANG = Symbol('hang');

/** One scripted answer: a reply's text, a failure, or a wait for the abort. */
export type Scripted = string | ModelCallError | typeof HANG;

/**
 * A model that answers from a script, one entry per attempt, and remembers
 * every request it was given — so a test can say what was sent and how often.
 */
export class FakeModel implements GenerativeModel {
  readonly name = 'fake-model';
  readonly requests: ModelRequest[] = [];

  constructor(private readonly script: Scripted[]) {}

  get calls(): number {
    return this.requests.length;
  }

  generate(request: ModelRequest, signal: AbortSignal): Promise<ModelReply> {
    this.requests.push(request);
    const next = this.script.shift();
    if (next === undefined) throw new Error('the fake model was asked more often than scripted');
    if (next === HANG) {
      return new Promise((_resolve, reject) => {
        signal.addEventListener('abort', () => {
          reject(new ModelCallError('timeout', 'aborted'));
        });
      });
    }
    if (next instanceof ModelCallError) return Promise.reject(next);
    return Promise.resolve({
      text: next,
      usage: { inputTokens: 100, outputTokens: 20 },
      modelVersion: 'fake-model-001',
    });
  }
}

/** A clock whose sleeps pass instantly but move time on, and are recorded. */
export class FakeClock implements CallClock {
  readonly sleeps: number[] = [];
  private at = 0;

  now(): number {
    return this.at;
  }

  advance(ms: number): void {
    this.at += ms;
  }

  sleep(ms: number): Promise<void> {
    this.sleeps.push(ms);
    this.at += ms;
    return Promise.resolve();
  }
}

/**
 * The Firestore ledger's behaviour without Firestore: the same pure decision,
 * the same refund on failure, the same idempotent settle.
 */
export class InMemoryUsageLedger implements UsageLedger {
  usage: MonthUsage = { calls: 0, attempts: 0 };
  entitlement: unknown = undefined;
  readonly settlements: { claim: AiClaim; settlement: Settlement }[] = [];
  private next = 0;
  private readonly settled = new Set<string>();

  claim(request: ClaimRequest): Promise<AiClaim> {
    const tier = tierFrom(this.entitlement, request.now);
    const decision = decideClaim(this.usage, request.monthlyCalls[tier]);
    if (!decision.allowed) return Promise.reject(refuseAi('aiLimitReached'));
    this.usage = { calls: this.usage.calls + 1, attempts: this.usage.attempts + 1 };
    this.next += 1;
    return Promise.resolve({
      householdId: request.householdId,
      month: '2026-09',
      callId: `call-${String(this.next)}`,
      feature: request.feature,
      tier,
      callsLeft: decision.callsLeft,
    });
  }

  settle(claim: AiClaim, settlement: Settlement): Promise<void> {
    if (this.settled.has(claim.callId)) return Promise.resolve();
    this.settled.add(claim.callId);
    this.settlements.push({ claim, settlement });
    if (!settlement.ok) this.usage = { ...this.usage, calls: this.usage.calls - 1 };
    return Promise.resolve();
  }
}

/** Runs [action] and returns the refusal reason it threw. */
export async function refusalOf(action: () => Promise<unknown>): Promise<string> {
  try {
    await action();
  } catch (error) {
    expect(error).toBeInstanceOf(HttpsError);
    const details = (error as HttpsError).details as { reason?: string } | undefined;
    return details?.reason ?? 'no reason';
  }
  throw new Error('expected a refusal, and the call succeeded');
}

/** The refusal reason a synchronous [action] threw. */
export function refusalOfNow(action: () => unknown): string {
  try {
    action();
  } catch (error) {
    expect(error).toBeInstanceOf(HttpsError);
    const details = (error as HttpsError).details as { reason?: string } | undefined;
    return details?.reason ?? 'no reason';
  }
  throw new Error('expected a refusal, and the call succeeded');
}
