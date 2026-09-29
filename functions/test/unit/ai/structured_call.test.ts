import { describe, expect, it } from 'vitest';
import { z } from 'zod';

import {
  ModelCallError,
  type ModelReply,
  type ModelRequest,
} from '../../../src/ai/generative_model';
import {
  StructuredCallFailure,
  callForJson,
  parseReply,
  type CallLimits,
  type StructuredReply,
} from '../../../src/ai/structured_call';
import { FakeClock, FakeModel, HANG, type Scripted } from './fakes';

/**
 * The retry, timeout and parse policy every AI feature inherits (foundation
 * ADR-0015, BE-19): what is retried, what is not, how long it may take, and
 * that the answer is parsed rather than trusted.
 */

const schema = z.object({ events: z.array(z.object({ title: z.string() })) });
const request: ModelRequest = {
  system: 'test',
  parts: [{ kind: 'text', text: 'hello' }],
  responseSchema: { type: 'OBJECT', properties: {} },
  maxOutputTokens: 100,
  temperature: 0,
  labels: { feature: 'schoolLetter' },
};
const good = '{"events":[{"title":"Spring market"}]}';
const limits: CallLimits = {
  attempts: 3,
  perAttemptMs: 50,
  budgetMs: 10_000,
  backoffMs: [1_000, 3_000],
};

interface Ran {
  model: FakeModel;
  clock: FakeClock;
  reply: StructuredReply<z.infer<typeof schema>> | undefined;
  failure: unknown;
}

async function run(script: Scripted[], clock = new FakeClock(), given = limits): Promise<Ran> {
  const model = new FakeModel(script);
  const outcome = await callForJson(model, request, schema, given, clock).then(
    (reply) => ({ reply, failure: undefined }),
    (failure: unknown) => ({ reply: undefined, failure }),
  );
  return { model, clock, ...outcome };
}

const transient = (): ModelCallError => new ModelCallError('transient', 'http 503');

describe('an answer in the shape asked for', () => {
  it('is parsed, typed and returned with its usage on the first attempt', async () => {
    const { reply, model } = await run([good]);
    expect(reply?.value).toEqual({ events: [{ title: 'Spring market' }] });
    expect(reply?.attempts).toBe(1);
    expect(reply?.usage).toEqual({ inputTokens: 100, outputTokens: 20 });
    expect(reply?.modelVersion).toBe('fake-model-001');
    expect(model.calls).toBe(1);
  });

  it('is read out of a Markdown fence, which a JSON-mode model still sometimes adds', () => {
    expect(parseReply('```json\n' + good + '\n```', schema)).toEqual({
      success: true,
      value: { events: [{ title: 'Spring market' }] },
    });
  });
});

describe('a failure worth retrying', () => {
  it('is retried with backoff, and every attempt’s tokens are counted', async () => {
    const tokenBearing = new ModelCallError('transient', 'empty', {
      inputTokens: 7,
      outputTokens: 1,
    });
    const { reply, clock, model } = await run([transient(), tokenBearing, good]);
    expect(reply?.attempts).toBe(3);
    expect(model.calls).toBe(3);
    expect(clock.sleeps).toEqual([1_000, 3_000]);
    expect(reply?.usage).toEqual({ inputTokens: 107, outputTokens: 21 });
  });

  it('includes an attempt that ran out of time, which is aborted rather than left hanging', async () => {
    const { reply, model } = await run([HANG, good]);
    expect(reply?.attempts).toBe(2);
    expect(model.calls).toBe(2);
  });

  it('gives up as unavailable once the attempts are spent', async () => {
    const { failure, model } = await run([transient(), transient(), transient()]);
    expect(failure).toBeInstanceOf(StructuredCallFailure);
    expect((failure as StructuredCallFailure).kind).toBe('unavailable');
    expect((failure as StructuredCallFailure).attempts).toBe(3);
    expect(model.calls).toBe(3);
  });

  it('starts no new attempt once the budget has gone', async () => {
    // The first attempt used the whole budget: a second would overrun the
    // callable's own timeout, so it is never started.
    const clock = new FakeClock();
    const tight: CallLimits = { ...limits, budgetMs: 500 };
    const slow = new FakeModel([transient(), good]);
    const generate = slow.generate.bind(slow);
    slow.generate = (req, signal): Promise<ModelReply> => {
      clock.advance(600);
      return generate(req, signal);
    };
    const failure = await callForJson(slow, request, schema, tight, clock).catch((e: unknown) => e);
    const model = slow;
    expect((failure as StructuredCallFailure).kind).toBe('unavailable');
    expect(model.calls).toBe(1);
  });
});

describe('a failure not worth retrying', () => {
  it('a refusal by the model is declined at once', async () => {
    const { failure, model } = await run([new ModelCallError('blocked', 'SAFETY'), good]);
    expect((failure as StructuredCallFailure).kind).toBe('declined');
    expect(model.calls).toBe(1);
  });

  it('a bad request (wrong model, no access, cut off) is unavailable at once', async () => {
    const { failure, model } = await run([new ModelCallError('permanent', 'http 404'), good]);
    expect((failure as StructuredCallFailure).kind).toBe('unavailable');
    expect(model.calls).toBe(1);
  });
});

describe('an answer in the wrong shape', () => {
  it('is asked for again once, and the second answer is used', async () => {
    const { reply, model } = await run(['not json at all', good]);
    expect(reply?.attempts).toBe(2);
    expect(model.calls).toBe(2);
  });

  it('twice is unreadable, and no third attempt is made', async () => {
    const { failure, model } = await run(['{"events":"nope"}', '{"other":1}', good]);
    expect((failure as StructuredCallFailure).kind).toBe('unreadable');
    expect((failure as StructuredCallFailure).usage.inputTokens).toBe(200);
    expect(model.calls).toBe(2);
  });

  it('never carries the reply into the failure’s detail, which is logged', async () => {
    const { failure } = await run(['{"secret":"Mia"}', '{"secret":"Mia"}']);
    expect((failure as StructuredCallFailure).detail).not.toContain('Mia');
  });
});

describe('an adapter bug', () => {
  it('is let through rather than dressed up as a model failure (ENG-10)', async () => {
    const broken = {
      name: 'broken',
      generate: (): Promise<never> => Promise.reject(new TypeError('adapter bug')),
    };
    await expect(callForJson(broken, request, schema, limits, new FakeClock())).rejects.toThrow(
      TypeError,
    );
  });
});
