import { describe, expect, it } from 'vitest';
import { z } from 'zod';

import { readAiSettings, type AiSettings } from '../../../src/ai/ai_settings';
import { ModelCallError, type ModelRequest } from '../../../src/ai/generative_model';
import { runAiCall, type AiCall, type AiDependencies } from '../../../src/ai/run_ai_call';
import { FakeClock, FakeModel, InMemoryUsageLedger, refusalOf, type Scripted } from './fakes';

/**
 * The one door every AI feature goes through (foundation ADR-0015): switched
 * off means no cost at all; the cap is claimed before the model is asked; a
 * call that fails is refunded; every failure reaches the app as a reason.
 */

const schema = z.object({ answer: z.number() });
const request: ModelRequest = {
  system: 'test',
  parts: [{ kind: 'text', text: 'what is six times seven' }],
  responseSchema: { type: 'OBJECT', properties: { answer: { type: 'INTEGER' } } },
  maxOutputTokens: 50,
  temperature: 0,
  labels: { feature: 'schoolLetter' },
};
const call: AiCall<z.infer<typeof schema>> = {
  feature: 'schoolLetter',
  householdId: 'h1',
  timeZone: 'Africa/Johannesburg',
  uid: 'uid-sam',
  request,
  schema,
};

interface World {
  model: FakeModel;
  ledger: InMemoryUsageLedger;
  deps: AiDependencies;
}

function world(script: Scripted[], settings: AiSettings = readAiSettings(undefined)): World {
  const model = new FakeModel(script);
  const ledger = new InMemoryUsageLedger();
  const deps: AiDependencies = {
    model,
    ledger,
    settings,
    now: () => new Date('2026-09-29T08:00:00Z'),
    limits: { attempts: 3, perAttemptMs: 50, budgetMs: 10_000, backoffMs: [10, 10] },
    clock: new FakeClock(),
  };
  return { model, ledger, deps };
}

describe('a call that works', () => {
  it('returns the parsed answer and what is left this month', async () => {
    const { deps, ledger } = world(['{"answer":42}']);
    const result = await runAiCall(deps, call);
    expect(result).toEqual({ value: { answer: 42 }, callsLeft: 9 });
    expect(ledger.usage).toEqual({ calls: 1, attempts: 1 });
  });

  it('is settled as succeeded, with the tokens and the version that answered', async () => {
    const { deps, ledger } = world(['{"answer":42}']);
    await runAiCall(deps, call);
    expect(ledger.settlements).toHaveLength(1);
    expect(ledger.settlements[0]?.settlement).toEqual({
      ok: true,
      usage: { inputTokens: 100, outputTokens: 20 },
      model: 'fake-model-001',
    });
    expect(ledger.settlements[0]?.claim.feature).toBe('schoolLetter');
  });

  it('counts against the premium cap when the household has premium', async () => {
    const { deps, ledger } = world(['{"answer":42}']);
    ledger.entitlement = {
      premiumUntil: { toMillis: (): number => new Date('2027-01-01T00:00:00Z').getTime() },
    };
    expect((await runAiCall(deps, call)).callsLeft).toBe(99);
  });
});

describe('a call that is switched off', () => {
  it('by the kill switch is refused before the ledger or the model is touched', async () => {
    const { deps, model, ledger } = world(['{"answer":42}'], readAiSettings({ enabled: false }));
    expect(await refusalOf(() => runAiCall(deps, call))).toBe('aiSwitchedOff');
    expect(model.calls).toBe(0);
    expect(ledger.usage).toEqual({ calls: 0, attempts: 0 });
  });

  it('by its own feature switch is refused the same way', async () => {
    const settings = readAiSettings({ features: { schoolLetter: false } });
    const { deps, model } = world(['{"answer":42}'], settings);
    expect(await refusalOf(() => runAiCall(deps, call))).toBe('aiSwitchedOff');
    expect(model.calls).toBe(0);
  });
});

describe('a household that has spent its month', () => {
  it('is refused, and the model is never asked', async () => {
    const { deps, model, ledger } = world(['{"answer":42}']);
    ledger.usage = { calls: 10, attempts: 10 };
    expect(await refusalOf(() => runAiCall(deps, call))).toBe('aiLimitReached');
    expect(model.calls).toBe(0);
  });

  it('the tenth call of ten works, and the eleventh is refused', async () => {
    const script = Array.from({ length: 10 }, () => '{"answer":1}');
    const { deps } = world(script);
    for (let index = 0; index < 10; index += 1) await runAiCall(deps, call);
    expect(await refusalOf(() => runAiCall(deps, call))).toBe('aiLimitReached');
  });

  it('a lower cap set in the console bites at once', async () => {
    const settings = readAiSettings({ monthlyCalls: { free: 1 } });
    const { deps } = world(['{"answer":1}', '{"answer":2}'], settings);
    await runAiCall(deps, call);
    expect(await refusalOf(() => runAiCall(deps, call))).toBe('aiLimitReached');
  });
});

describe('a call that fails', () => {
  it('is refunded — the family got nothing — but its attempt still counts', async () => {
    const down = (): ModelCallError => new ModelCallError('transient', 'http 503');
    const { deps, ledger } = world([down(), down(), down()]);
    expect(await refusalOf(() => runAiCall(deps, call))).toBe('aiUnavailable');
    expect(ledger.usage).toEqual({ calls: 0, attempts: 1 });
    expect(ledger.settlements[0]?.settlement).toMatchObject({ ok: false, reason: 'unavailable' });
  });

  it('twice in the wrong shape is unreadable', async () => {
    const { deps } = world(['{"answer":"many"}', 'not json']);
    expect(await refusalOf(() => runAiCall(deps, call))).toBe('aiUnreadable');
  });

  it('declined by the model is declined', async () => {
    const { deps } = world([new ModelCallError('blocked', 'SAFETY')]);
    expect(await refusalOf(() => runAiCall(deps, call))).toBe('aiDeclined');
  });

  it('failing forever cannot run up a bill: attempts close the month at three times the cap', async () => {
    const settings = readAiSettings({ monthlyCalls: { free: 1 } });
    const blocked = (): ModelCallError => new ModelCallError('blocked', 'SAFETY');
    const { deps, model } = world([blocked(), blocked(), blocked(), blocked()], settings);
    for (let index = 0; index < 3; index += 1) {
      expect(await refusalOf(() => runAiCall(deps, call))).toBe('aiDeclined');
    }
    expect(await refusalOf(() => runAiCall(deps, call))).toBe('aiLimitReached');
    expect(model.calls).toBe(3);
  });

  it('with a bug rather than a model failure is refunded, then let through as itself', async () => {
    const { deps, ledger } = world([]);
    const broken: AiDependencies = {
      ...deps,
      model: { name: 'broken', generate: () => Promise.reject(new RangeError('bug')) },
    };
    await expect(runAiCall(broken, call)).rejects.toThrow(RangeError);
    expect(ledger.settlements[0]?.settlement).toMatchObject({ ok: false, reason: 'error' });
    expect(ledger.usage.calls).toBe(0);
  });
});
