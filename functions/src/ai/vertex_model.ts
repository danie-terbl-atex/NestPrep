import { z } from 'zod';

import type { AccessTokenSource } from './access_token';
import {
  ModelCallError,
  type GenerativeModel,
  type ModelPart,
  type ModelReply,
  type ModelRequest,
  type ModelUsage,
} from './generative_model';

/**
 * Gemini on Vertex AI, over its REST `generateContent` (foundation ADR-0015).
 *
 * The one file that knows Vertex exists. It is called only from Cloud
 * Functions, authenticated as the Functions' own service account — there is
 * no API key anywhere, in the app or here (ENG-18). The endpoint is regional,
 * so the request is processed where [location] says and nowhere else.
 *
 * No SDK: the call is one POST, and the reply is parsed with zod rather than
 * trusted (ENG-09, ENG-17).
 */
export interface VertexModelOptions {
  readonly project: string;
  readonly location: string;
  readonly model: string;
  readonly tokens: AccessTokenSource;
  /** Injected so a test can answer for Vertex; `fetch` otherwise. */
  readonly fetcher?: typeof fetch;
}

const vertexReply = z.object({
  candidates: z
    .array(
      z.object({
        content: z
          .object({
            parts: z
              .array(z.object({ text: z.string().optional(), thought: z.boolean().optional() }))
              .optional(),
          })
          .optional(),
        finishReason: z.string().optional(),
      }),
    )
    .optional(),
  promptFeedback: z.object({ blockReason: z.string().optional() }).optional(),
  usageMetadata: z
    .object({
      promptTokenCount: z.number().optional(),
      candidatesTokenCount: z.number().optional(),
      thoughtsTokenCount: z.number().optional(),
    })
    .optional(),
  modelVersion: z.string().optional(),
});
type VertexReply = z.infer<typeof vertexReply>;

/** Finish reasons that mean the model declined, not that it failed. */
const BLOCKED_FINISHES = new Set([
  'SAFETY',
  'RECITATION',
  'BLOCKLIST',
  'PROHIBITED_CONTENT',
  'SPII',
  'IMAGE_SAFETY',
]);

/** HTTP statuses where asking again later can succeed. */
const TRANSIENT_STATUSES = new Set([408, 429, 500, 502, 503, 504]);

export class VertexModel implements GenerativeModel {
  constructor(private readonly options: VertexModelOptions) {}

  get name(): string {
    return this.options.model;
  }

  get endpoint(): string {
    const { project, location, model } = this.options;
    const host =
      location === 'global' ? 'aiplatform.googleapis.com' : `${location}-aiplatform.googleapis.com`;
    return `https://${host}/v1/projects/${project}/locations/${location}/publishers/google/models/${model}:generateContent`;
  }

  async generate(request: ModelRequest, signal: AbortSignal): Promise<ModelReply> {
    const token = await this.options.tokens.token();
    const fetcher = this.options.fetcher ?? fetch;
    let response: Response;
    try {
      response = await fetcher(this.endpoint, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(vertexBody(request)),
        signal,
      });
    } catch (error) {
      if (signal.aborted) throw new ModelCallError('timeout', 'no answer in time');
      throw new ModelCallError('transient', `network: ${describe(error)}`);
    }
    if (!response.ok) {
      const kind = TRANSIENT_STATUSES.has(response.status) ? 'transient' : 'permanent';
      throw new ModelCallError(kind, `http ${String(response.status)}`);
    }
    const parsed = vertexReply.safeParse(await readJson(response, signal));
    if (!parsed.success) throw new ModelCallError('permanent', 'reply was not Vertex shaped');
    return replyFrom(parsed.data, this.options.model);
  }
}

/** The request as Vertex spells it. */
export function vertexBody(request: ModelRequest): Record<string, unknown> {
  return {
    systemInstruction: { parts: [{ text: request.system }] },
    contents: [{ role: 'user', parts: request.parts.map(vertexPart) }],
    generationConfig: {
      temperature: request.temperature,
      maxOutputTokens: request.maxOutputTokens,
      responseMimeType: 'application/json',
      responseSchema: request.responseSchema,
      // Extraction needs reading, not reasoning; thinking tokens are billed as
      // output and would multiply the cost of every call (foundation ADR-0015).
      thinkingConfig: { thinkingBudget: 0 },
    },
    labels: request.labels,
  };
}

function vertexPart(part: ModelPart): Record<string, unknown> {
  return part.kind === 'text'
    ? { text: part.text }
    : { inlineData: { mimeType: part.mimeType, data: part.base64 } };
}

async function readJson(response: Response, signal: AbortSignal): Promise<unknown> {
  try {
    return await response.json();
  } catch (error) {
    if (signal.aborted) throw new ModelCallError('timeout', 'no answer in time');
    throw new ModelCallError('transient', `unreadable body: ${describe(error)}`);
  }
}

function replyFrom(reply: VertexReply, model: string): ModelReply {
  const usage = usageOf(reply);
  const blockReason = reply.promptFeedback?.blockReason;
  if (blockReason !== undefined) {
    throw new ModelCallError('blocked', `prompt blocked: ${blockReason}`, usage);
  }
  const candidate = reply.candidates?.[0];
  const finish = candidate?.finishReason ?? 'UNKNOWN';
  if (BLOCKED_FINISHES.has(finish)) {
    throw new ModelCallError('blocked', `finished: ${finish}`, usage);
  }
  const text = (candidate?.content?.parts ?? [])
    .filter((part) => part.thought !== true)
    .map((part) => part.text ?? '')
    .join('');
  if (finish === 'MAX_TOKENS') {
    throw new ModelCallError('permanent', 'reply cut off at the token limit', usage);
  }
  if (text.trim() === '') throw new ModelCallError('transient', `empty reply (${finish})`, usage);
  return { text, usage, modelVersion: reply.modelVersion ?? model };
}

function usageOf(reply: VertexReply): ModelUsage {
  const metadata = reply.usageMetadata;
  return {
    inputTokens: metadata?.promptTokenCount ?? 0,
    outputTokens: (metadata?.candidatesTokenCount ?? 0) + (metadata?.thoughtsTokenCount ?? 0),
  };
}

function describe(error: unknown): string {
  return error instanceof Error ? error.name : 'unknown';
}
