import type { z } from 'zod';

import { HttpUnreachable, jsonOf, type HttpClient, type HttpRequest } from '../shared/http_client';
import { PnpUnavailable } from './pnp_api';

/** The website's commerce API for site `pnp-spa`, and the OIDC server (add-to-pnp ADR-0001). */
export const PNP_OCC = 'https://www.pnp.co.za/pnphybris/v2/pnp-spa';
export const PNP_LOGIN = 'https://login.pnp.co.za';

/** Every OCC call names its language and currency, as the website does. */
export const OCC_LOCALE = 'lang=en&curr=ZAR';

export interface PnpReply {
  readonly status: number;
  readonly body: unknown;
}

/**
 * One request to PnP through the one HTTP client with its timeout and no
 * silent redirects (BE-09, BE-19). Busy, failing, redirecting or unreachable
 * is `PnpUnavailable`; anything else comes back for the caller to read,
 * because only the caller knows what a 4xx means for its call.
 */
export async function askPnp(
  http: HttpClient,
  url: string,
  request: HttpRequest,
): Promise<PnpReply> {
  let response;
  try {
    response = await http.send(url, request);
  } catch (error) {
    if (error instanceof HttpUnreachable) throw new PnpUnavailable(`network: ${error.reason}`);
    throw error;
  }
  const { status } = response;
  if (status === 429 || status >= 500) throw new PnpUnavailable(`status ${String(status)}`);
  if (status >= 300 && status < 400) throw new PnpUnavailable('redirect');
  return { status, body: jsonOf(response.body) };
}

/** A 2xx body read into its schema; anything else PnP answered is unreadable (ENG-09). */
export function readPnpReply<T extends z.ZodType>(schema: T, reply: PnpReply): z.infer<T> {
  if (reply.status < 200 || reply.status >= 300) {
    throw new PnpUnavailable(`status ${String(reply.status)}`);
  }
  const parsed = schema.safeParse(reply.body);
  if (!parsed.success) throw new PnpUnavailable('unreadable');
  return parsed.data;
}
