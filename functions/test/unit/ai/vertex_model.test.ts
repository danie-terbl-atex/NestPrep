import { describe, expect, it } from 'vitest';

import { ModelCallError, type ModelRequest } from '../../../src/ai/generative_model';
import { VertexModel, vertexBody } from '../../../src/ai/vertex_model';

/**
 * The Vertex adapter against canned responses (BE-09): what it sends, where,
 * as whom, and how every way Vertex answers becomes a reply or a typed
 * failure the retry policy can act on.
 */

const request: ModelRequest = {
  system: 'You read school letters.',
  parts: [
    { kind: 'text', text: 'Today is Tuesday 2026-09-29.' },
    { kind: 'inline', mimeType: 'application/pdf', base64: 'JVBERi0=' },
  ],
  responseSchema: {
    type: 'OBJECT',
    properties: { events: { type: 'ARRAY', items: { type: 'STRING' } } },
  },
  maxOutputTokens: 4096,
  temperature: 0,
  labels: { feature: 'schoolLetter' },
};

interface Sent {
  url: string;
  init: RequestInit;
}

function vertexWith(respond: () => Promise<Response>, sent: Sent[] = []): VertexModel {
  return new VertexModel({
    project: 'nestprep-test',
    location: 'europe-west4',
    model: 'gemini-2.5-flash',
    tokens: { token: () => Promise.resolve('token-abc') },
    fetcher: (url, init): Promise<Response> => {
      sent.push({ url: url instanceof Request ? url.url : url.toString(), init: init ?? {} });
      return respond();
    },
  });
}

const json = (body: unknown, status = 200): Promise<Response> =>
  Promise.resolve(new Response(JSON.stringify(body), { status }));

const answered = (text: string, finishReason = 'STOP'): unknown => ({
  candidates: [{ content: { parts: [{ text }] }, finishReason }],
  usageMetadata: { promptTokenCount: 1200, candidatesTokenCount: 300, thoughtsTokenCount: 0 },
  modelVersion: 'gemini-2.5-flash-002',
});

async function failureOf(
  model: VertexModel,
  signal = new AbortController().signal,
): Promise<ModelCallError> {
  try {
    await model.generate(request, signal);
  } catch (error) {
    expect(error).toBeInstanceOf(ModelCallError);
    return error as ModelCallError;
  }
  throw new Error('expected a failure');
}

describe('the request', () => {
  it('goes to the regional endpoint, as the service account, and nowhere else', async () => {
    const sent: Sent[] = [];
    await vertexWith(() => json(answered('{}')), sent).generate(
      request,
      new AbortController().signal,
    );
    expect(sent).toHaveLength(1);
    expect(sent[0]?.url).toBe(
      'https://europe-west4-aiplatform.googleapis.com/v1/projects/nestprep-test/locations/' +
        'europe-west4/publishers/google/models/gemini-2.5-flash:generateContent',
    );
    expect(sent[0]?.init.method).toBe('POST');
    expect(new Headers(sent[0]?.init.headers).get('Authorization')).toBe('Bearer token-abc');
  });

  it('the global location has no regional host', () => {
    const model = new VertexModel({
      project: 'p',
      location: 'global',
      model: 'm',
      tokens: { token: (): Promise<string> => Promise.resolve('t') },
    });
    expect(model.endpoint).toBe(
      'https://aiplatform.googleapis.com/v1/projects/p/locations/global/publishers/google/models/m:generateContent',
    );
  });

  it('asks for JSON of the schema, with no thinking tokens, and labels the feature', () => {
    expect(vertexBody(request)).toEqual({
      systemInstruction: { parts: [{ text: 'You read school letters.' }] },
      contents: [
        {
          role: 'user',
          parts: [
            { text: 'Today is Tuesday 2026-09-29.' },
            { inlineData: { mimeType: 'application/pdf', data: 'JVBERi0=' } },
          ],
        },
      ],
      generationConfig: {
        temperature: 0,
        maxOutputTokens: 4096,
        responseMimeType: 'application/json',
        responseSchema: request.responseSchema,
        thinkingConfig: { thinkingBudget: 0 },
      },
      labels: { feature: 'schoolLetter' },
    });
  });
});

describe('an answer', () => {
  it('is its text, its token counts and the version that answered', async () => {
    const reply = await vertexWith(() => json(answered('{"events":[]}'))).generate(
      request,
      new AbortController().signal,
    );
    expect(reply).toEqual({
      text: '{"events":[]}',
      usage: { inputTokens: 1200, outputTokens: 300 },
      modelVersion: 'gemini-2.5-flash-002',
    });
  });

  it('leaves out the model’s thoughts and joins the parts it said', async () => {
    const body = {
      candidates: [
        {
          content: { parts: [{ text: 'hmm', thought: true }, { text: '{"a"' }, { text: ':1}' }] },
          finishReason: 'STOP',
        },
      ],
    };
    const reply = await vertexWith(() => json(body)).generate(
      request,
      new AbortController().signal,
    );
    expect(reply.text).toBe('{"a":1}');
    expect(reply.modelVersion).toBe('gemini-2.5-flash');
  });
});

describe('a failure', () => {
  it.each([429, 500, 502, 503, 504])('HTTP %i is transient', async (status) => {
    expect((await failureOf(vertexWith(() => json({}, status)))).kind).toBe('transient');
  });

  it.each([400, 401, 403, 404])('HTTP %i is permanent', async (status) => {
    expect((await failureOf(vertexWith(() => json({}, status)))).kind).toBe('permanent');
  });

  it('a network error is transient', async () => {
    const model = vertexWith(() => Promise.reject(new TypeError('fetch failed')));
    expect((await failureOf(model)).kind).toBe('transient');
  });

  it('an aborted attempt is a timeout', async () => {
    const controller = new AbortController();
    controller.abort();
    const model = vertexWith(() => Promise.reject(new DOMException('aborted', 'AbortError')));
    expect((await failureOf(model, controller.signal)).kind).toBe('timeout');
  });

  it('a blocked prompt is blocked, and still carries what it cost', async () => {
    const body = {
      promptFeedback: { blockReason: 'SAFETY' },
      usageMetadata: { promptTokenCount: 900 },
    };
    const failure = await failureOf(vertexWith(() => json(body)));
    expect(failure.kind).toBe('blocked');
    expect(failure.usage.inputTokens).toBe(900);
  });

  it.each(['SAFETY', 'PROHIBITED_CONTENT', 'SPII', 'RECITATION'])(
    'finishing for %s is blocked',
    async (finishReason) => {
      const failure = await failureOf(vertexWith(() => json(answered('', finishReason))));
      expect(failure.kind).toBe('blocked');
    },
  );

  it('an answer cut off at the token limit is permanent — more of the same will not fit', async () => {
    const failure = await failureOf(vertexWith(() => json(answered('{"events":[', 'MAX_TOKENS'))));
    expect(failure.kind).toBe('permanent');
  });

  it('an empty answer is transient', async () => {
    expect((await failureOf(vertexWith(() => json(answered('  '))))).kind).toBe('transient');
  });

  it('a body that is not Vertex’s shape is permanent, never trusted', async () => {
    expect((await failureOf(vertexWith(() => json({ candidates: 'nope' })))).kind).toBe(
      'permanent',
    );
  });

  it('never puts the request or the reply in its message, which is logged', async () => {
    const failure = await failureOf(vertexWith(() => json(answered('Mia', 'SAFETY'))));
    expect(failure.message).not.toContain('Mia');
    expect(failure.message).not.toContain('JVBERi0=');
  });
});
