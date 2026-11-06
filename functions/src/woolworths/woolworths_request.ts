import type { z } from 'zod';

import { HttpUnreachable, jsonOf, type HttpClient, type HttpRequest } from '../shared/http_client';
import { WoolworthsUnavailable } from './woolworths_api';

export const WFS_BASE = 'https://wfs-appserver.wigroup.co/wfs/app/v4';

export function cognitoEndpoint(region: string): string {
  return `https://cognito-idp.${region}.amazonaws.com/`;
}

export interface WoolworthsReply {
  readonly status: number;
  readonly body: unknown;
}

export async function askWoolworths(
  http: HttpClient,
  url: string,
  request: HttpRequest,
): Promise<WoolworthsReply> {
  let response;
  try {
    response = await http.send(url, request);
  } catch (error) {
    if (error instanceof HttpUnreachable) {
      throw new WoolworthsUnavailable(`network: ${error.reason}`);
    }
    throw error;
  }
  const { status } = response;
  if (status === 429 || status >= 500) throw new WoolworthsUnavailable(`status ${String(status)}`);
  if (status >= 300 && status < 400) throw new WoolworthsUnavailable('redirect');
  return { status, body: jsonOf(response.body) };
}

export function readWoolworthsReply<T extends z.ZodType>(
  schema: T,
  reply: WoolworthsReply,
): z.infer<T> {
  if (reply.status < 200 || reply.status >= 300) {
    throw new WoolworthsUnavailable(`status ${String(reply.status)}`);
  }
  const parsed = schema.safeParse(reply.body);
  if (!parsed.success) throw new WoolworthsUnavailable('unreadable');
  return parsed.data;
}
