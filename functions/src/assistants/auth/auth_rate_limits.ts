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
