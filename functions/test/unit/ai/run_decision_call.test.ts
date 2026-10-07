import { describe, expect, it } from 'vitest';

import { readAiSettings } from '../../../src/ai/ai_settings';
import {
  MAX_DECISION_REQUEST_CHARS,
  callForDecisions,
  choiceOf,
  noulOf,
  questionBatches,
} from '../../../src/ai/decision_call';
import type { DecisionModel, DecisionReply, DecisionRequest } from '../../../src/ai/decision_model';
import { ModelCallError } from '../../../src/ai/generative_model';
import {
  askDecisions,
  runDecisionCall,
  type DecisionDependencies,
} from '../../../src/ai/run_decision_call';
import { StructuredCallFailure } from '../../../src/ai/structured_call';
import { InMemoryUsageLedger, refusalOf } from './fakes';

class FakeJev implements DecisionModel {
  readonly name = 'fake-jev';
  readonly asked: DecisionRequest[] = [];

  constructor(private readonly answer: (id: string) => unknown = () => yes) {}

  decide(request: DecisionRequest): Promise<DecisionReply> {
    this.asked.push(request);
    const answers: Record<string, unknown> = {};
    for (const id of Object.keys(request.questions)) {
      const answer = this.answer(id);
      if (answer instanceof ModelCallError) return Promise.reject(answer);
      if (answer !== undefined) answers[id] = answer;
    }
    return Promise.resolve({
      answers,
      usage: { inputTokens: 40, outputTokens: 2 },
      modelVersion: 'jev-test',
    });
  }
}

const yes = { type: 'noul', noul: 0.9 };
const request = (count: number, padding = 0): DecisionRequest => ({
  label: 'test',
  state: 'a test',
  questions: Object.fromEntries(
    Array.from({ length: count }, (_, n) => [
      `q${String(n)}`,
      { type: 'noul', instructions: 'x'.repeat(padding) },
    ]),
  ),
});
const spend = {
  feature: 'planMyWeek' as const,
  householdId: 'h1',
  timeZone: 'Africa/Johannesburg',
  uid: 'uid-sam',
};

function deps(
  model: DecisionModel,
  settings = readAiSettings(undefined),
): DecisionDependencies & { ledger: InMemoryUsageLedger } {
  return {
    model,
    ledger: new InMemoryUsageLedger(),
    settings,
    now: (): Date => new Date('2026-10-04T08:00:00Z'),
  };
}

describe('asking Jev', () => {
  it('splits a long request into batches that each fit the budget, and merges the answers', async () => {
    const padding = Math.floor(MAX_DECISION_REQUEST_CHARS / 2) - 100;
    expect(questionBatches(request(7, padding).questions)).toHaveLength(4);
    const jev = new FakeJev();
    const reply = await callForDecisions(jev, request(7, padding));
    expect(jev.asked).toHaveLength(4);
    expect(Object.keys(reply.value)).toHaveLength(7);
    expect(reply.usage).toEqual({ inputTokens: 160, outputTokens: 8 });
  });

  it('is unreadable when a question comes back unanswered', async () => {
    const jev = new FakeJev((id) => (id === 'q1' ? undefined : yes));
    await expect(callForDecisions(jev, request(2))).rejects.toMatchObject({ kind: 'unreadable' });
  });

  it('is unavailable when Jev fails, and declined when it refuses', async () => {
    const down = new FakeJev(() => new ModelCallError('transient', 'jev answered 503'));
    await expect(callForDecisions(down, request(1))).rejects.toBeInstanceOf(StructuredCallFailure);
    await expect(callForDecisions(down, request(1))).rejects.toMatchObject({
      kind: 'unavailable',
    });
    const refused = new FakeJev(() => new ModelCallError('blocked', 'no'));
    await expect(callForDecisions(refused, request(1))).rejects.toMatchObject({ kind: 'declined' });
  });

  it('reads a probability or a label, and nothing else', () => {
    const answers = {
      a: { type: 'noul', noul: 0.25 },
      b: { type: 'choice', choice: '6', confidence: 0.8 },
      c: { noul: 7 },
    };
    expect(noulOf(answers, 'a')).toBe(0.25);
    expect(noulOf(answers, 'c')).toBeNull();
    expect(noulOf(answers, 'missing')).toBeNull();
    expect(choiceOf(answers, 'b')).toBe('6');
    expect(choiceOf(answers, 'a')).toBeNull();
  });
});

describe('a charged decision', () => {
  it('claims one of the month’s calls and keeps it when Jev answers', async () => {
    const world = deps(new FakeJev());
    const result = await runDecisionCall(world, { ...spend, request: request(3) });
    expect(Object.keys(result.value)).toHaveLength(3);
    expect(world.ledger.usage.calls).toBe(1);
    expect(world.ledger.settlements[0]?.settlement).toMatchObject({ ok: true, model: 'jev-test' });
  });

  it('refunds the call when Jev is down, and says so', async () => {
    const world = deps(new FakeJev(() => new ModelCallError('transient', 'down')));
    expect(await refusalOf(() => runDecisionCall(world, { ...spend, request: request(1) }))).toBe(
      'aiUnavailable',
    );
    expect(world.ledger.usage.calls).toBe(0);
  });

  it('costs nothing when its feature is switched off', async () => {
    const jev = new FakeJev();
    const world = deps(jev, readAiSettings({ features: { planMyWeek: false } }));
    expect(await refusalOf(() => runDecisionCall(world, { ...spend, request: request(1) }))).toBe(
      'aiSwitchedOff',
    );
    expect(jev.asked).toHaveLength(0);
  });
});

describe('an uncharged decision', () => {
  it('asks Jev under the switch and claims nothing', async () => {
    const jev = new FakeJev();
    const world = deps(jev);
    expect(Object.keys(await askDecisions(world, 'productMatch', request(2)))).toHaveLength(2);
    expect(world.ledger.usage.calls).toBe(0);
  });

  it('is refused, unasked, when switched off', async () => {
    const jev = new FakeJev();
    const world = deps(jev, readAiSettings({ features: { productMatch: false } }));
    expect(await refusalOf(() => askDecisions(world, 'productMatch', request(1)))).toBe(
      'aiSwitchedOff',
    );
    expect(jev.asked).toHaveLength(0);
  });
});
