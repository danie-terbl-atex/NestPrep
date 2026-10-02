import { describe, expect, it } from 'vitest';

import { ModelCallError } from '../../../src/ai/generative_model';
import type { ImageRequest } from '../../../src/ai/image_model';
import { ImagenModel, imagenBody } from '../../../src/ai/imagen_model';

/**
 * The Imagen adapter against canned responses (BE-09): what it sends, where,
 * as whom, and how every way Imagen answers becomes a picture or a typed
 * failure the retry policy can act on (lunch-box ADR-0015).
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

function imagenWith(respond: () => Promise<Response>, sent: Sent[] = []): ImagenModel {
  return new ImagenModel({
    project: 'nestprep-test',
    location: 'europe-west4',
    model: 'imagen-4.0-generate-001',
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
  predictions: [{ bytesBase64Encoded: JPEG.toString('base64'), mimeType: 'image/jpeg' }],
});

async function failureOf(
  model: ImagenModel,
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
  it('goes to the regional predict endpoint, as the service account, and nowhere else', async () => {
    const sent: Sent[] = [];
    await imagenWith(() => json(pictured()), sent).generate(request, new AbortController().signal);
    expect(sent).toHaveLength(1);
    expect(sent[0]?.url).toBe(
      'https://europe-west4-aiplatform.googleapis.com/v1/projects/nestprep-test/locations/' +
        'europe-west4/publishers/google/models/imagen-4.0-generate-001:predict',
    );
    expect(sent[0]?.init.method).toBe('POST');
    expect(new Headers(sent[0]?.init.headers).get('Authorization')).toBe('Bearer token-abc');
    expect(JSON.parse(sent[0]?.init.body as string)).toEqual(imagenBody(request));
  });

  it('asks for one JPEG with no people and no watermark, and sends no labels', () => {
    expect(imagenBody(request)).toEqual({
      instances: [{ prompt: 'An open lunch box holding: Banana' }],
      parameters: {
        sampleCount: 1,
        aspectRatio: '4:3',
        personGeneration: 'dont_allow',
        addWatermark: false,
        outputOptions: { mimeType: 'image/jpeg', compressionQuality: 82 },
      },
    });
  });
});

describe('an answer', () => {
  it('is the decoded bytes, their type and the model', async () => {
    const reply = await imagenWith(() => json(pictured())).generate(
      request,
      new AbortController().signal,
    );
    expect(reply).toEqual({
      bytes: JPEG,
      mimeType: 'image/jpeg',
      modelVersion: 'imagen-4.0-generate-001',
    });
  });
});

describe('a failure', () => {
  it.each([429, 500, 502, 503, 504])('HTTP %i is transient', async (status) => {
    expect((await failureOf(imagenWith(() => json({}, status)))).kind).toBe('transient');
  });

  it.each([400, 401, 403, 404])('HTTP %i is permanent', async (status) => {
    expect((await failureOf(imagenWith(() => json({}, status)))).kind).toBe('permanent');
  });

  it('a network error is transient', async () => {
    const model = imagenWith(() => Promise.reject(new TypeError('fetch failed')));
    expect((await failureOf(model)).kind).toBe('transient');
  });

  it('an aborted attempt is a timeout', async () => {
    const controller = new AbortController();
    controller.abort();
    const model = imagenWith(() => Promise.reject(new DOMException('aborted', 'AbortError')));
    expect((await failureOf(model, controller.signal)).kind).toBe('timeout');
  });

  it('a picture the safety filter removed is blocked', async () => {
    const body = { predictions: [{ raiFilteredReason: 'Filtered for safety.' }] };
    expect((await failureOf(imagenWith(() => json(body)))).kind).toBe('blocked');
  });

  it.each([{}, { predictions: [] }, { predictions: [{ mimeType: 'image/jpeg' }] }])(
    'no picture at all (%j) is blocked',
    async (body) => {
      expect((await failureOf(imagenWith(() => json(body)))).kind).toBe('blocked');
    },
  );

  it('a body that is not Imagen’s shape is permanent, never trusted', async () => {
    expect((await failureOf(imagenWith(() => json({ predictions: 'nope' })))).kind).toBe(
      'permanent',
    );
  });
});
