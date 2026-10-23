import { z } from 'zod';

import { PnpUnavailable, type CartWriteShortfall } from './pnp_api';
import type { PnpReply } from './pnp_request';
import { occErrors } from './pnp_wire';

/**
 * A cart write as PnP answered it (add-to-pnp ADR-0004). Hybris answers an
 * add or an update with a cart modification whose `statusCode` says whether
 * the line holds what was asked; an HTTP status alone does not. A 4xx is a
 * refusal of this one line — deterministic, so the rest of the push carries
 * on — and only a 2xx PnP did not explain, or no answer at all, is
 * `PnpUnavailable`.
 */
const cartModification = z.object({ statusCode: z.string().optional() });

const SHORTFALLS: Readonly<Record<string, CartWriteShortfall>> = {
  noStock: 'out-of-stock',
  lowStock: 'low-stock',
  maxOrderQuantityExceeded: 'max-quantity',
};

export function cartWriteShortfallOf(reply: PnpReply): CartWriteShortfall | null {
  if (reply.status >= 400 && reply.status < 500) return 'shop-refused';
  if (reply.status < 200 || reply.status >= 300) {
    throw new PnpUnavailable(`cart write ${String(reply.status)}`);
  }
  // An update may answer with no body: the line holds what was asked.
  if (reply.body === null) return null;
  const parsed = cartModification.safeParse(reply.body);
  if (!parsed.success) throw new PnpUnavailable('cart write unreadable');
  const status = parsed.data.statusCode;
  if (status === undefined || status === 'success') return null;
  return SHORTFALLS[status] ?? 'shop-refused';
}

/**
 * A 401 is always an expired token; a 403 only when PnP says the token is
 * the reason — any other 403 is a refusal of the call, not of the member.
 */
export function isExpiredToken(reply: PnpReply): boolean {
  if (reply.status === 401) return true;
  if (reply.status !== 403) return false;
  const parsed = occErrors.safeParse(reply.body);
  return (
    parsed.success &&
    parsed.data.errors.some((error) => /InvalidToken|InvalidGrant|Unauthorized/i.test(error.type))
  );
}
