import type { AddressedRequest } from '../../shared/client_address';
import type { RateLimitRule } from '../../shared/rate_limit';

/**
 * The limits on the authorization server's public endpoints (assistants
 * ADR-0002). A browser's endpoints — authorize and consent — are counted per
 * address (`callerAddress`), with an overall ceiling no header changes. The
 * token endpoint is called from the assistants' own servers, where one
 * address is every member on that assistant at once, so it is counted per
 * client and grant instead, under its own overall ceiling.
 */
const FIFTEEN_MINUTES = 15 * 60;
const HOUR = 60 * 60;

export const AUTHORIZE_PER_ADDRESS: RateLimitRule = {
  name: 'assistantAuthorize',
  limit: 30,
  windowSeconds: FIFTEEN_MINUTES,
};

export const AUTHORIZE_OVERALL: RateLimitRule = {
  name: 'assistantAuthorizeAll',
  limit: 1_000,
  windowSeconds: FIFTEEN_MINUTES,
};

export const CONSENT_PER_ADDRESS: RateLimitRule = {
  name: 'assistantConsent',
  limit: 60,
  windowSeconds: FIFTEEN_MINUTES,
};

export const CONSENT_OVERALL: RateLimitRule = {
  name: 'assistantConsentAll',
  limit: 2_000,
  windowSeconds: FIFTEEN_MINUTES,
};

/**
 * Token requests for one client and one grant — or, before a code becomes a
 * grant, one code — in fifteen minutes: a connection refreshes about hourly.
 */
export const TOKEN_PER_GRANT: RateLimitRule = {
  name: 'assistantTokenGrant',
  limit: 30,
  windowSeconds: FIFTEEN_MINUTES,
};

export const TOKEN_OVERALL: RateLimitRule = {
  name: 'assistantTokenAll',
  limit: 10_000,
  windowSeconds: FIFTEEN_MINUTES,
};

/** What `TOKEN_PER_GRANT` counts by: the client and the grant (or code hash) presented. */
export function tokenRateSubject(clientId: string, grantOrCode: string): string {
  return `${clientId} ${grantOrCode}`;
}

export const REGISTER_PER_ADDRESS: RateLimitRule = {
  name: 'assistantRegister',
  limit: 30,
  windowSeconds: HOUR,
};

/**
 * Registrations write a document each, so they have a ceiling no address
 * changes — a generous one, because Claude registers once per connection.
 */
export const REGISTER_OVERALL: RateLimitRule = {
  name: 'assistantRegisterAll',
  limit: 5_000,
  windowSeconds: 24 * HOUR,
};

/** Calls one connection may make to the MCP endpoint (assistants ADR-0003). */
export const CALLS_PER_GRANT: RateLimitRule = {
  name: 'assistantCalls',
  limit: 300,
  windowSeconds: HOUR,
};

/**
 * The address an assistants endpoint counts a browser by: the hop left of the
 * right-most `X-Forwarded-For` hop. Measured in the cloud on 2026-10-29,
 * Hosting replaces whatever the caller sent with `client, proxy`, where the
 * proxy is one of a rotating pool of Google addresses, so the right-most hop
 * would pool every member behind whichever proxy carried them. A call made
 * straight to the Function's own URL, which cannot be closed while Hosting
 * rewrites to it, keeps the caller's header with the real address appended,
 * so there the hop counted can be forged; the overall ceilings hold either
 * way. `req.ip` is not used: the Functions Framework enables Express's
 * `trust proxy`, which makes it the left-most hop. Only ever used hashed,
 * never stored or logged (ENG-22).
 */
export function callerAddress(request: AddressedRequest): string {
  const forwarded = request.headers['x-forwarded-for'];
  const hops = (Array.isArray(forwarded) ? forwarded.join(',') : (forwarded ?? ''))
    .split(',')
    .map((hop) => hop.trim())
    .filter((hop) => hop !== '');
  return hops.at(-2) ?? hops.at(-1) ?? request.ip ?? 'unknown';
}
