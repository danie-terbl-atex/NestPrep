import { z } from 'zod';

import { openJson, sealJson } from '../shared/sealed_json';

/** What a pending link seals: the PKCE verifier and the two values the redirect must echo. */
export interface PnpLinkSecrets {
  readonly verifier: string;
  readonly state: string;
  readonly nonce: string;
}

/** What a session seals: the member's two tokens. */
export interface PnpSessionTokens {
  readonly accessToken: string;
  readonly refreshToken: string;
}

/**
 * The additional authenticated data names what a value is for as well as
 * whose it is (add-to-pnp ADR-0003), so a sealed pending link can never be
 * opened as a session or the other way round. Checkers keeps its plain-uid
 * owner, because live Checkers links were sealed with it.
 */
export function pendingOwner(uid: string): string {
  return `pnp:pending:${uid}`;
}

export function sessionOwner(uid: string): string {
  return `pnp:session:${uid}`;
}

const linkSecretsShape = z.object({ verifier: z.string(), state: z.string(), nonce: z.string() });
const tokensShape = z.object({ accessToken: z.string(), refreshToken: z.string() });

export function sealLinkSecrets(
  key: Buffer,
  uid: string,
  secrets: PnpLinkSecrets,
): Promise<string> {
  return sealJson(key, pendingOwner(uid), secrets);
}

export function openLinkSecrets(
  key: Buffer,
  uid: string,
  sealed: string,
): Promise<PnpLinkSecrets | null> {
  return openJson(linkSecretsShape, key, pendingOwner(uid), sealed);
}

export function sealSessionTokens(
  key: Buffer,
  uid: string,
  tokens: PnpSessionTokens,
): Promise<string> {
  return sealJson(key, sessionOwner(uid), tokens);
}

export function openSessionTokens(
  key: Buffer,
  uid: string,
  sealed: string,
): Promise<PnpSessionTokens | null> {
  return openJson(tokensShape, key, sessionOwner(uid), sealed);
}
