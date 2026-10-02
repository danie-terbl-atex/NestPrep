import type { z } from 'zod';

import { HttpUnreachable, jsonOf, type HttpClient, type HttpRequest } from '../shared/http_client';
import { CheckersUnavailable } from './checkers_api';

/** The Sixty60 services, as the Android app reaches them. */
export const CHECKERS_HOSTS = {
  /** The app's backend-for-frontend: the free app token and the BFF login. */
  bff: 'https://dc-app-backend-for-frontend.sixty60.co.za/api/v1',
  /** Shoprite's identity service: the DSL login and the customer's ids. */
  dsl: 'https://api.shopritegroup.co.za/dsl/brands/checkers/countries/ZA',
  auth: 'https://auth.sixty60.co.za',
  catalog: 'https://catalog.sixty60.co.za',
  orders: 'https://orders-api.sixty60.co.za',
} as const;

export interface CheckersReply {
  readonly status: number;
  readonly body: unknown;
}

/**
 * One request to Checkers through the one HTTP client with its timeout and no
 * silent redirects (BE-09, BE-19). Busy, failing, redirecting or unreachable
 * is `CheckersUnavailable`; anything else comes back for the caller to read,
 * because only the caller knows what a 4xx means for its call.
 */
export async function askCheckers(
  http: HttpClient,
  url: string,
  request: HttpRequest,
): Promise<CheckersReply> {
  let response;
  try {
    response = await http.send(url, request);
  } catch (error) {
    if (error instanceof HttpUnreachable) {
      throw new CheckersUnavailable(`network: ${error.reason}`);
    }
    throw error;
  }
  const { status } = response;
  if (status === 429 || status >= 500) throw new CheckersUnavailable(`status ${String(status)}`);
  if (status >= 300 && status < 400) throw new CheckersUnavailable('redirect');
  return { status, body: jsonOf(response.body) };
}

export function isSuccess(reply: CheckersReply): boolean {
  return reply.status >= 200 && reply.status < 300;
}

/** A 2xx body read into its schema; anything else Checkers answered is unreadable (ENG-09). */
export function readReply<T extends z.ZodType>(schema: T, reply: CheckersReply): z.infer<T> {
  if (!isSuccess(reply)) throw new CheckersUnavailable(`status ${String(reply.status)}`);
  const parsed = schema.safeParse(reply.body);
  if (!parsed.success) throw new CheckersUnavailable('unreadable');
  return parsed.data;
}
