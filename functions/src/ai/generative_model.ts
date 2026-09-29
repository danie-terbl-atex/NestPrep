/**
 * The one interface every AI feature talks to (foundation ADR-0015). A feature
 * never sees Vertex, HTTP or a token: it hands a request to a
 * `GenerativeModel` and gets text back, so the unit tests substitute a fake
 * and the emulator a canned one (BE-09).
 */

/** One piece of what the model is asked about. */
export type ModelPart =
  | { readonly kind: 'text'; readonly text: string }
  | { readonly kind: 'inline'; readonly mimeType: string; readonly base64: string };

/**
 * The OpenAPI subset Vertex accepts as a `responseSchema` — what makes the
 * model answer in JSON of a known shape rather than in prose. The reply is
 * still parsed with zod afterwards: a schema the model was *asked* to follow
 * is not one it is proven to have followed (ENG-09).
 */
export type ResponseSchema =
  | {
      readonly type: 'OBJECT';
      readonly properties: Readonly<Record<string, ResponseSchema>>;
      readonly required?: readonly string[];
      readonly nullable?: boolean;
      readonly description?: string;
    }
  | {
      readonly type: 'ARRAY';
      readonly items: ResponseSchema;
      readonly nullable?: boolean;
      readonly description?: string;
    }
  | {
      readonly type: 'STRING' | 'INTEGER' | 'NUMBER' | 'BOOLEAN';
      readonly enum?: readonly string[];
      readonly nullable?: boolean;
      readonly description?: string;
    };

export interface ModelRequest {
  /** What the model is for; never anything about a family. */
  readonly system: string;
  readonly parts: readonly ModelPart[];
  readonly responseSchema: ResponseSchema;
  readonly maxOutputTokens: number;
  readonly temperature: number;
  /**
   * Billing labels Vertex attaches to the call — which feature spent it.
   * Lower-case letters, digits, `_` and `-` only.
   */
  readonly labels: Readonly<Record<string, string>>;
}

export interface ModelUsage {
  readonly inputTokens: number;
  readonly outputTokens: number;
}

export const NO_USAGE: ModelUsage = { inputTokens: 0, outputTokens: 0 };

export function addUsage(a: ModelUsage, b: ModelUsage): ModelUsage {
  return {
    inputTokens: a.inputTokens + b.inputTokens,
    outputTokens: a.outputTokens + b.outputTokens,
  };
}

export interface ModelReply {
  /** The model's answer, which should be JSON of the requested shape. */
  readonly text: string;
  readonly usage: ModelUsage;
  /** The model version that actually answered, for the ledger. */
  readonly modelVersion: string;
}

/**
 * Why a call to the model did not produce a reply.
 *
 * - `transient`: rate-limited or a server error — worth another attempt.
 * - `timeout`: no answer within the attempt's limit — also worth one.
 * - `blocked`: the model refused the content; asking again gets the same.
 * - `permanent`: the request itself is wrong (bad model id, no access,
 *   truncated reply) — asking again gets the same.
 */
export type ModelFailureKind = 'transient' | 'timeout' | 'blocked' | 'permanent';

export class ModelCallError extends Error {
  constructor(
    readonly kind: ModelFailureKind,
    /** For a log; never shown to a person, never holds the request. */
    readonly detail: string,
    readonly usage: ModelUsage = NO_USAGE,
  ) {
    super(`${kind}: ${detail}`);
    this.name = 'ModelCallError';
  }

  get isWorthRetrying(): boolean {
    return this.kind === 'transient' || this.kind === 'timeout';
  }
}

export interface GenerativeModel {
  /** The configured model id, for the ledger and the logs. */
  readonly name: string;
  /**
   * One attempt. Resolves with the reply or rejects with a `ModelCallError`;
   * [signal] aborts it when the attempt's time is up.
   */
  generate(request: ModelRequest, signal: AbortSignal): Promise<ModelReply>;
}
