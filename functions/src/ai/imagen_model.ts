import { z } from 'zod';

import type { AccessTokenSource } from './access_token';
import { ModelCallError } from './generative_model';
import type { ImageModel, ImageReply, ImageRequest } from './image_model';
import { errorName, failureKindForStatus, readJson, vertexEndpoint } from './vertex_model';

/**
 * Imagen on Vertex AI, over its REST `predict` (lunch-box ADR-0015). The one
 * file that knows Imagen exists; reached as the Functions' own service
 * account, like Gemini — no key anywhere (ENG-18).
 */
export interface ImagenModelOptions {
  readonly project: string;
  readonly location: string;
  readonly model: string;
  readonly tokens: AccessTokenSource;
  /** Injected so a test can answer for Vertex; `fetch` otherwise. */
  readonly fetcher?: typeof fetch;
}

const imagenReply = z.object({
  predictions: z
    .array(
      z.object({
        bytesBase64Encoded: z.string().optional(),
        mimeType: z.string().optional(),
        raiFilteredReason: z.string().optional(),
      }),
    )
    .optional(),
});
type ImagenReply = z.infer<typeof imagenReply>;

export class ImagenModel implements ImageModel {
  constructor(private readonly options: ImagenModelOptions) {}

  get name(): string {
    return this.options.model;
  }

  get endpoint(): string {
    const { project, location, model } = this.options;
    return vertexEndpoint(project, location, model, 'predict');
  }

  async generate(request: ImageRequest, signal: AbortSignal): Promise<ImageReply> {
    const token = await this.options.tokens.token();
    const fetcher = this.options.fetcher ?? fetch;
    let response: Response;
    try {
      response = await fetcher(this.endpoint, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(imagenBody(request)),
        signal,
      });
    } catch (error) {
      if (signal.aborted) throw new ModelCallError('timeout', 'no answer in time');
      throw new ModelCallError('transient', `network: ${errorName(error)}`);
    }
    if (!response.ok) {
      throw new ModelCallError(
        failureKindForStatus(response.status),
        `http ${String(response.status)}`,
      );
    }
    const parsed = imagenReply.safeParse(await readJson(response, signal));
    if (!parsed.success) throw new ModelCallError('permanent', 'reply was not Imagen shaped');
    return replyFrom(parsed.data, this.options.model);
  }
}

/** The request as Imagen spells it. */
export function imagenBody(request: ImageRequest): Record<string, unknown> {
  return {
    instances: [{ prompt: request.prompt }],
    parameters: {
      sampleCount: 1,
      aspectRatio: request.aspectRatio,
      personGeneration: 'dont_allow',
      addWatermark: false,
      outputOptions: { mimeType: 'image/jpeg', compressionQuality: 82 },
    },
  };
}

/** Imagen drops a filtered image from `predictions` rather than failing the call. */
function replyFrom(reply: ImagenReply, model: string): ImageReply {
  const prediction = reply.predictions?.[0];
  if (prediction?.raiFilteredReason !== undefined) {
    throw new ModelCallError('blocked', 'filtered by responsible-AI settings');
  }
  const encoded = prediction?.bytesBase64Encoded;
  if (encoded === undefined || encoded === '') {
    throw new ModelCallError('blocked', 'no image came back');
  }
  return {
    bytes: Buffer.from(encoded, 'base64'),
    mimeType: prediction?.mimeType ?? 'image/jpeg',
    modelVersion: model,
  };
}
