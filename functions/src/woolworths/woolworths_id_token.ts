import { z } from 'zod';

import type { WoolworthsTokens } from './woolworths_api';

export const ID_SKEW_SECONDS = 300;

const claimsShape = z.object({
  email: z.string().optional(),
  exp: z.number().optional(),
  'custom:AtgId': z.union([z.string(), z.number()]).optional(),
});

export type IdTokenClaims = z.infer<typeof claimsShape>;

export function idTokenClaims(idToken: string): IdTokenClaims | null {
  const payload = idToken.split('.')[1];
  if (payload === undefined || payload === '') return null;
  let value: unknown;
  try {
    value = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
  } catch (error) {
    if (error instanceof SyntaxError) return null;
    throw error;
  }
  const parsed = claimsShape.safeParse(value);
  return parsed.success ? parsed.data : null;
}

export function dynUserIdOf(idToken: string): string | null {
  const id = idTokenClaims(idToken)?.['custom:AtgId'];
  return id === undefined ? null : String(id);
}

export function maskedEmail(email: string | undefined): string | null {
  const match = /^([^@\s])[^@\s]*@([^@.\s])[^@.\s]*((?:\.[^@.\s]+)*)$/.exec(email?.trim() ?? '');
  if (match === null) return null;
  const [, first = '', domainFirst = '', rest = ''] = match;
  return `${first}***@${domainFirst}***${rest}`;
}

export function idExpiryOf(tokens: WoolworthsTokens, now: Date): Date {
  const exp = idTokenClaims(tokens.idToken)?.exp;
  const expiresAt = exp === undefined ? now.getTime() + tokens.expiresInSeconds * 1000 : exp * 1000;
  return new Date(Math.max(now.getTime(), expiresAt - ID_SKEW_SECONDS * 1000));
}
