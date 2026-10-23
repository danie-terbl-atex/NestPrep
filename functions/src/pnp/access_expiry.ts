import type { PnpTokens } from './pnp_api';

/** The access token is treated as lapsed this long before PnP says it is. */
export const ACCESS_SKEW_SECONDS = 60;

/** When to refresh: a little before PnP says the access token lapses. */
export function accessExpiryOf(tokens: PnpTokens, now: Date): Date {
  const seconds = Math.max(0, tokens.expiresInSeconds - ACCESS_SKEW_SECONDS);
  return new Date(now.getTime() + seconds * 1000);
}
