import { z } from 'zod';

import { openJson, sealJson } from '../shared/sealed_json';

export interface WoolworthsSessionTokens {
  readonly refreshToken: string;
  readonly idToken: string;
}

export function sessionOwner(uid: string): string {
  return `woolworths:session:${uid}`;
}

const tokensShape = z.object({ refreshToken: z.string(), idToken: z.string() });

export function sealSessionTokens(
  key: Buffer,
  uid: string,
  tokens: WoolworthsSessionTokens,
): Promise<string> {
  return sealJson(key, sessionOwner(uid), tokens);
}

export function openSessionTokens(
  key: Buffer,
  uid: string,
  sealed: string,
): Promise<WoolworthsSessionTokens | null> {
  return openJson(tokensShape, key, sessionOwner(uid), sealed);
}
