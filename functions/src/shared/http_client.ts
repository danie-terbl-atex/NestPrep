/**
 * The one way a Function talks to the outside world (BE-09, BE-19): a request
 * with a timeout, a size cap, and no redirects followed silently. Behind an
 * interface so every adapter — calendar providers, the two app stores — is
 * tested against canned responses and never the network. Calendar sync wrote
 * it; subscriptions is its second user, which is why it lives here (`ENG-02`).
 */
export interface HttpRequest {
  readonly method: 'GET' | 'POST';
  readonly headers?: Readonly<Record<string, string>>;
  readonly body?: string;
}

export interface HttpResponse {
  readonly status: number;
  readonly body: string;
  /** Where a 3xx points, when it does. */
  readonly location: string | null;
}

export interface HttpClient {
  send(url: string, request: HttpRequest): Promise<HttpResponse>;
}

/** Thrown when the other end could not be reached or would not finish. */
export class HttpUnreachable extends Error {
  constructor(readonly reason: string) {
    super(`unreachable: ${reason}`);
    this.name = 'HttpUnreachable';
  }
}

export const REQUEST_TIMEOUT_MS = 8_000;
export const MAX_BODY_BYTES = 5 * 1024 * 1024;

export const fetchHttpClient: HttpClient = {
  async send(url, request) {
    let response: Response;
    try {
      response = await fetch(url, {
        method: request.method,
        headers: request.headers ?? {},
        body: request.body ?? null,
        redirect: 'manual',
        signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      });
    } catch (error) {
      throw new HttpUnreachable(error instanceof Error ? error.name : 'unknown');
    }
    const declared = Number(response.headers.get('content-length') ?? '0');
    if (declared > MAX_BODY_BYTES) throw new HttpUnreachable('too large');
    let body: string;
    try {
      body = await response.text();
    } catch (error) {
      throw new HttpUnreachable(error instanceof Error ? error.name : 'unreadable');
    }
    if (body.length > MAX_BODY_BYTES) throw new HttpUnreachable('too large');
    return { status: response.status, body, location: response.headers.get('location') };
  },
};

/** A form-encoded POST body, as every OAuth token endpoint wants it. */
export function formBody(fields: Record<string, string>): string {
  return new URLSearchParams(fields).toString();
}

export const FORM_HEADERS = { 'Content-Type': 'application/x-www-form-urlencoded' } as const;

/** Parses a JSON body, or returns null when it is not JSON at all. */
export function jsonOf(body: string): unknown {
  try {
    return JSON.parse(body) as unknown;
  } catch (error) {
    if (error instanceof SyntaxError) return null;
    throw error;
  }
}
