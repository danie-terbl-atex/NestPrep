import { z } from 'zod';

import type { AccessTokenSource } from './access_token';
import { ModelCallError } from './generative_model';
import type { ImageModel, ImageReply, ImageRequest } from './image_model';
import { errorName, failureKindForStatus, readJson, vertexEndpoint } from './vertex_model';

/**
 * A Gemini image model on Vertex AI, over `generateContent` with an image
 * answer (lunch-box ADR-0016). Reached as the Functions' own service account,
 * like the text model — no key anywhere (ENG-18).
 */
export interface GeminiImageModelOptions {
  readonly project: string;
  readonly location: string;
  readonly model: string;
  readonly tokens: AccessTokenSource;
  /** Injected so a test can answer for Vertex; `fetch` otherwise. */
  readonly fetcher?: typeof fetch;
}

const imageReply = z.object({
  candidates: z
    .array(
      z.object({
        finishReason: z.string().optional(),
        content: z
          .object({
            parts: z
              .array(
                z.object({
                  inlineData: z.object({ mimeType: z.string(), data: z.string() }).optional(),
                }),
              )
              .optional(),
          })
          .optional(),
      }),
    )
    .optional(),
  promptFeedback: z.object({ blockReason: z.string().optional() }).optional(),
});
type GeminiImageReply = z.infer<typeof imageReply>;

export class GeminiImageModel implements ImageModel {
  constructor(private readonly options: GeminiImageModelOptions) {}

  get name(): string {
    return this.options.model;
  }

  get endpoint(): string {
    const { project, location, model } = this.options;
    return vertexEndpoint(project, location, model, 'generateContent');
  }

  async generate(request: ImageRequest, signal: AbortSignal): Promise<ImageReply> {
    const token = await this.options.tokens.token();
    const fetcher = this.options.fetcher ?? fetch;
    let response: Response;
    try {
      response = await fetcher(this.endpoint, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(geminiImageBody(request)),
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
    const parsed = imageReply.safeParse(await readJson(response, signal));
    if (!parsed.success) throw new ModelCallError('permanent', 'reply was not image shaped');
    return replyFrom(parsed.data, this.options.model);
  }
}

/** The request as a Gemini image model spells it: one JPEG, no people. */
export function geminiImageBody(request: ImageRequest): Record<string, unknown> {
  return {
    contents: [{ role: 'user', parts: [{ text: request.prompt }] }],
    generationConfig: {
      responseModalities: ['IMAGE'],
      imageConfig: {
        aspectRatio: request.aspectRatio,
        personGeneration: 'ALLOW_NONE',
        imageOutputOptions: { mimeType: 'image/jpeg', compressionQuality: 82 },
      },
    },
  };
}

/** A refused or filtered picture comes back as a reply with no image in it. */
function replyFrom(reply: GeminiImageReply, model: string): ImageReply {
  if (reply.promptFeedback?.blockReason !== undefined) {
    throw new ModelCallError('blocked', `prompt blocked: ${reply.promptFeedback.blockReason}`);
  }
  const candidate = reply.candidates?.[0];
  const image = candidate?.content?.parts?.find(
    (part) => part.inlineData !== undefined,
  )?.inlineData;
  if (image === undefined || image.data === '') {
    throw new ModelCallError('blocked', `no image came back: ${candidate?.finishReason ?? 'none'}`);
  }
  return {
    bytes: Buffer.from(image.data, 'base64'),
    mimeType: image.mimeType,
    modelVersion: model,
  };
}
