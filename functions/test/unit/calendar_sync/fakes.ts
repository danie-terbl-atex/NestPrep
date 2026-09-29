import type { HttpClient, HttpRequest, HttpResponse } from '../../../src/calendar_sync/http_client';
import { syncWindow, type SyncWindow } from '../../../src/calendar_sync/external_occurrence';

/**
 * A provider that answers from a script, and remembers what it was asked
 * (BE-09: every adapter is tested against canned responses, never the network).
 */
export class ScriptedHttp implements HttpClient {
  readonly requests: { url: string; request: HttpRequest }[] = [];

  constructor(private readonly answer: (url: string, request: HttpRequest) => HttpResponse) {}

  send(url: string, request: HttpRequest): Promise<HttpResponse> {
    this.requests.push({ url, request });
    return Promise.resolve(this.answer(url, request));
  }
}

export function json(status: number, body: unknown): HttpResponse {
  return { status, body: JSON.stringify(body), location: null };
}

export function text(status: number, body: string, location: string | null = null): HttpResponse {
  return { status, body, location };
}

/** The window a sync on 29 September 2026 at noon, Johannesburg, reads. */
export function windowIn(zone = 'Africa/Johannesburg', now = '2026-09-29T10:00:00Z'): SyncWindow {
  return syncWindow(zone, new Date(now));
}

/** A form body back as fields, to assert what a token request carried. */
export function formFields(body: string | undefined): Record<string, string> {
  return Object.fromEntries(new URLSearchParams(body ?? ''));
}

export const CLIENT = { clientId: 'client-id', clientSecret: 'client-secret' };
