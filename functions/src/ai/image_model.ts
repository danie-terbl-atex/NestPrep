/**
 * The one interface every image-making feature talks to (lunch-box ADR-0015),
 * as `GenerativeModel` is for text: a feature never sees Vertex, HTTP or a
 * token, so the unit tests substitute a fake and the emulator a canned one.
 * A failure is a `ModelCallError`, with the same kinds and the same retry
 * policy as a text call.
 */
export interface ImageRequest {
  readonly prompt: string;
  readonly aspectRatio: '4:3';
  /** Billing labels, as on a text request: which feature spent it. */
  readonly labels: Readonly<Record<string, string>>;
}

export interface ImageReply {
  readonly bytes: Buffer;
  readonly mimeType: string;
  /** The model that actually answered, for the ledger. */
  readonly modelVersion: string;
}

export interface ImageModel {
  /** The configured model id, for the ledger and the logs. */
  readonly name: string;
  /**
   * One attempt. Resolves with the image or rejects with a `ModelCallError`;
   * [signal] aborts it when the attempt's time is up.
   */
  generate(request: ImageRequest, signal: AbortSignal): Promise<ImageReply>;
}
