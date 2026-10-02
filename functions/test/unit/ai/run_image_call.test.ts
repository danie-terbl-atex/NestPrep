import { describe, expect, it } from 'vitest';

import { readAiSettings, type AiSettings } from '../../../src/ai/ai_settings';
import { ModelCallError } from '../../../src/ai/generative_model';
import { IMAGE_CALL_LIMITS } from '../../../src/ai/image_call';
import type { ImageRequest } from '../../../src/ai/image_model';
import { runImageCall, type ImageCall, type ImageDependencies } from '../../../src/ai/run_ai_call';
import {
  FAKE_JPEG,
  FakeClock,
  FakeImageModel,
  HANG,
  InMemoryUsageLedger,
  refusalOf,
  type ScriptedImage,
} from './fakes';

/**
 * A picture goes through the same door as every text call (lunch-box
 * ADR-0015, foundation ADR-0015): switched, capped before the model is asked,
 * charged when it worked and refunded when it did not — with fewer, longer
 * attempts of its own.
 */

const request: ImageRequest = {
  prompt: 'A lunch box',
  aspectRatio: '4:3',
  labels: { feature: 'lunchPhoto' },
};
const call: ImageCall = {
  feature: 'lunchPhoto',
  householdId: 'h1',
  timeZone: 'Africa/Johannesburg',
  uid: 'uid-sam',
  request,
};

interface World {
  model: FakeImageModel;
  ledger: InMemoryUsageLedger;
  clock: FakeClock;
  deps: ImageDependencies;
}

function world(script: ScriptedImage[], settings: AiSettings = readAiSettings(undefined)): World {
  const model = new FakeImageModel(script);
  const ledger = new InMemoryUsageLedger();
  const clock = new FakeClock();
  const deps: ImageDependencies = {
    model,
    ledger,
    settings,
    now: () => new Date('2026-10-02T08:00:00Z'),
    limits: { ...IMAGE_CALL_LIMITS, perAttemptMs: 50 },
    clock,
  };
  return { model, ledger, clock, deps };
}

describe('a picture that works', () => {
  it('is the image, charged as one call, with no tokens', async () => {
    const { deps, ledger } = world(['image']);
    const result = await runImageCall(deps, call);
    expect(result.value.bytes).toEqual(FAKE_JPEG);
    expect(result.callsLeft).toBe(9);
    expect(ledger.usage).toEqual({ calls: 1, attempts: 1 });
    expect(ledger.settlements[0]?.settlement).toEqual({
      ok: true,
      usage: { inputTokens: 0, outputTokens: 0 },
      model: 'fake-image-model-001',
    });
    expect(ledger.settlements[0]?.claim.feature).toBe('lunchPhoto');
  });

  it('is asked for exactly what the feature sent', async () => {
    const { deps, model } = world(['image']);
    await runImageCall(deps, call);
    expect(model.requests).toEqual([request]);
  });
});

describe('a picture that is switched off or over the cap', () => {
  it('by the kill switch costs nothing', async () => {
    const { deps, model, ledger } = world(['image'], readAiSettings({ enabled: false }));
    expect(await refusalOf(() => runImageCall(deps, call))).toBe('aiSwitchedOff');
    expect(model.calls).toBe(0);
    expect(ledger.usage).toEqual({ calls: 0, attempts: 0 });
  });

  it('by its own feature switch the same way', async () => {
    const settings = readAiSettings({ features: { lunchPhoto: false } });
    const { deps, model } = world(['image'], settings);
    expect(await refusalOf(() => runImageCall(deps, call))).toBe('aiSwitchedOff');
    expect(model.calls).toBe(0);
  });

  it('when the month is spent, before the model is asked', async () => {
    const { deps, model, ledger } = world(['image']);
    ledger.usage = { calls: 10, attempts: 10 };
    expect(await refusalOf(() => runImageCall(deps, call))).toBe('aiLimitReached');
    expect(model.calls).toBe(0);
  });
});

describe('a picture that fails', () => {
  it('is retried once after a transient failure, and charged once', async () => {
    const { deps, model, ledger, clock } = world([
      new ModelCallError('transient', 'http 503'),
      'image',
    ]);
    await runImageCall(deps, call);
    expect(model.calls).toBe(2);
    expect(clock.sleeps).toEqual([2_000]);
    expect(ledger.usage).toEqual({ calls: 1, attempts: 1 });
  });

  it('twice is refunded, and unavailable', async () => {
    const down = (): ModelCallError => new ModelCallError('transient', 'http 503');
    const { deps, model, ledger } = world([down(), down()]);
    expect(await refusalOf(() => runImageCall(deps, call))).toBe('aiUnavailable');
    expect(model.calls).toBe(2);
    expect(ledger.usage).toEqual({ calls: 0, attempts: 1 });
    expect(ledger.settlements[0]?.settlement).toMatchObject({ ok: false, reason: 'unavailable' });
  });

  it('times out per attempt, then is unavailable', async () => {
    const { deps } = world([HANG, HANG]);
    expect(await refusalOf(() => runImageCall(deps, call))).toBe('aiUnavailable');
  });

  it('filtered by the model is declined at once, and refunded', async () => {
    const { deps, model, ledger } = world([new ModelCallError('blocked', 'filtered')]);
    expect(await refusalOf(() => runImageCall(deps, call))).toBe('aiDeclined');
    expect(model.calls).toBe(1);
    expect(ledger.usage.calls).toBe(0);
  });

  it('with a bad request is unavailable at once', async () => {
    const { deps, model } = world([new ModelCallError('permanent', 'http 400')]);
    expect(await refusalOf(() => runImageCall(deps, call))).toBe('aiUnavailable');
    expect(model.calls).toBe(1);
  });

  it('starts no second attempt once the budget has gone', async () => {
    const { deps, model, clock } = world([new ModelCallError('transient', 'http 503'), 'image']);
    const original = deps.model.generate.bind(deps.model);
    const late: ImageDependencies = {
      ...deps,
      model: {
        name: deps.model.name,
        generate: (sent, signal) => {
          clock.advance(IMAGE_CALL_LIMITS.budgetMs);
          return original(sent, signal);
        },
      },
    };
    expect(await refusalOf(() => runImageCall(late, call))).toBe('aiUnavailable');
    expect(model.calls).toBe(1);
  });

  it('with a bug rather than a model failure is refunded, then let through as itself', async () => {
    const { deps, ledger } = world([]);
    const broken: ImageDependencies = {
      ...deps,
      model: { name: 'broken', generate: () => Promise.reject(new RangeError('bug')) },
    };
    await expect(runImageCall(broken, call)).rejects.toThrow(RangeError);
    expect(ledger.settlements[0]?.settlement).toMatchObject({ ok: false, reason: 'error' });
    expect(ledger.usage.calls).toBe(0);
  });
});
