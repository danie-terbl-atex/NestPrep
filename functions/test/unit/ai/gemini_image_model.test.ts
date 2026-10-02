import { describe, expect, it } from 'vitest';

import { GeminiImageModel, geminiImageBody } from '../../../src/ai/gemini_image_model';
import { ModelCallError } from '../../../src/ai/generative_model';
import type { ImageRequest } from '../../../src/ai/image_model';

/**
 * The Gemini image adapter against canned responses (BE-09): what it sends,
 * where, as whom, and how every way the model answers becomes a picture or a
 * typed failure the retry policy can act on (lunch-box ADR-0016).
 */

const request: ImageRequest = {
  prompt: 'An open lunch box holding: Banana',
  aspectRatio: '4:3',
  labels: { feature: 'lunchPhoto' },
};

interface Sent {
  url: string;
  init: RequestInit;
}

function imageModelWith(respond: () => Promise<Response>, sent: Sent[] = []): GeminiImageModel {
  return new GeminiImageModel({
    project: 'nestprep-test',
    location: 'global',
    model: 'gemini-3.1-flash-image',
    tokens: { token: () => Promise.resolve('token-abc') },
    fetcher: (url, init): Promise<Response> => {
      sent.push({ url: url instanceof Request ? url.url : url.toString(), init: init ?? {} });
      return respond();
    },
  });
}

const json = (body: unknown, status = 200): Promise<Response> =>
  Promise.resolve(new Response(JSON.stringify(body), { status }));

const JPEG = Buffer.from([0xff, 0xd8, 0xff, 0xe0]);
const pictured = (): unknown => ({
  candidates: [
    {
      finishReason: 'STOP',
      content: {
        parts: [{ inlineData: { mimeType: 'image/jpeg', data: JPEG.toString('base64') } }],
      },
    },
  ],
});

async function failureOf(
  model: GeminiImageModel,
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
  it('goes to the global generateContent endpoint, as the service account', async () => {
    const sent: Sent[] = [];
    await imageModelWith(() => json(pictured()), sent).generate(
      request,
      new AbortController().signal,
    );
    expect(sent).toHaveLength(1);
    expect(sent[0]?.url).toBe(
      'https://aiplatform.googleapis.com/v1/projects/nestprep-test/locations/' +
        'global/publishers/google/models/gemini-3.1-flash-image:generateContent',
    );
    expect(sent[0]?.init.method).toBe('POST');
    expect(new Headers(sent[0]?.init.headers).get('Authorization')).toBe('Bearer token-abc');
    expect(JSON.parse(sent[0]?.init.body as string)).toEqual(geminiImageBody(request));
  });

  it('asks for one image, as a JPEG, with no people', () => {
    expect(geminiImageBody(request)).toEqual({
      contents: [{ role: 'user', parts: [{ text: 'An open lunch box holding: Banana' }] }],
      generationConfig: {
        responseModalities: ['IMAGE'],
        imageConfig: {
          aspectRatio: '4:3',
          personGeneration: 'ALLOW_NONE',
          imageOutputOptions: { mimeType: 'image/jpeg', compressionQuality: 82 },
        },
      },
    });
  });
});

describe('an answer', () => {
  it('is the decoded bytes, their type and the model', async () => {
    const reply = await imageModelWith(() => json(pictured())).generate(
      request,
      new AbortController().signal,
    );
    expect(reply).toEqual({
      bytes: JPEG,
      mimeType: 'image/jpeg',
      modelVersion: 'gemini-3.1-flash-image',
    });
  });
});

describe('a failure', () => {
  it.each([429, 500, 502, 503, 504])('HTTP %i is transient', async (status) => {
    expect((await failureOf(imageModelWith(() => json({}, status)))).kind).toBe('transient');
  });

  it.each([400, 401, 403, 404])('HTTP %i is permanent', async (status) => {
    expect((await failureOf(imageModelWith(() => json({}, status)))).kind).toBe('permanent');
  });

  it('a network error is transient', async () => {
    const model = imageModelWith(() => Promise.reject(new TypeError('fetch failed')));
    expect((await failureOf(model)).kind).toBe('transient');
  });

  it('an aborted attempt is a timeout', async () => {
    const controller = new AbortController();
    controller.abort();
    const model = imageModelWith(() => Promise.reject(new DOMException('aborted', 'AbortError')));
    expect((await failureOf(model, controller.signal)).kind).toBe('timeout');
  });

  it('a prompt the model refused is blocked', async () => {
    const body = { promptFeedback: { blockReason: 'SAFETY' } };
    expect((await failureOf(imageModelWith(() => json(body)))).kind).toBe('blocked');
  });

  it.each([
    {},
    { candidates: [] },
    { candidates: [{ finishReason: 'IMAGE_SAFETY', content: { parts: [] } }] },
    { candidates: [{ finishReason: 'STOP', content: { parts: [{}] } }] },
  ])('no picture at all (%j) is blocked', async (body) => {
    expect((await failureOf(imageModelWith(() => json(body)))).kind).toBe('blocked');
  });

  it('a body that is not the model’s shape is permanent, never trusted', async () => {
    expect((await failureOf(imageModelWith(() => json({ candidates: 'nope' })))).kind).toBe(
      'permanent',
    );
  });
});
