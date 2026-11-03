import type { AssistantVia } from '../principal';

/**
 * Where an authorization code may be sent (assistants ADR-0002). v1 trusts
 * two assistants, so a code only ever goes back to Claude or ChatGPT — a
 * look-alike client can register whatever name it likes and still never
 * receive one. Loopback is for Claude Code and the MCP Inspector, behind
 * `ASSISTANTS_ALLOW_LOOPBACK`.
 */
const EXACT_REDIRECTS = [
  'https://claude.ai/api/mcp/auth_callback',
  'https://claude.com/api/mcp/auth_callback',
  'https://chatgpt.com/connector_platform_oauth_redirect',
];
const CHATGPT_CONNECTOR = /^https:\/\/chatgpt\.com\/connector\/oauth\/[A-Za-z0-9_-]{1,128}$/;
const LOOPBACK = /^http:\/\/(localhost|127\.0\.0\.1):(\d{1,5})\/callback$/;

export function isAllowedRedirect(uri: string, allowLoopback: boolean): boolean {
  return (
    EXACT_REDIRECTS.includes(uri) ||
    CHATGPT_CONNECTOR.test(uri) ||
    (allowLoopback && LOOPBACK.test(uri))
  );
}

/**
 * Whether a requested redirect is one the client registered: exactly, or —
 * for a loopback redirect, whose port a native client picks at sign-in
 * (RFC 8252 §7.3) — the same host and path on any port.
 */
export function redirectMatches(registered: readonly string[], requested: string): boolean {
  if (registered.includes(requested)) return true;
  const asked = LOOPBACK.exec(requested);
  if (asked === null) return false;
  return registered.some((uri) => LOOPBACK.exec(uri)?.[1] === asked[1]);
}

/** Which assistant a redirect belongs to, which is what the app's "via Claude" says. */
export function viaOfRedirect(uri: string): AssistantVia {
  const host = hostOf(uri);
  if (host === 'claude.ai' || host === 'claude.com') return 'claude';
  if (host === 'chatgpt.com') return 'chatgpt';
  return 'assistant';
}

export function hostOf(uri: string): string {
  try {
    return new URL(uri).host;
  } catch (error) {
    if (error instanceof TypeError) return '';
    throw error;
  }
}
