import { hash, randomBytes, timingSafeEqual } from 'node:crypto';

import { type DocumentReference, type Firestore, Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';

import { ASSISTANT_SCOPES } from '../assistant_scopes';
import { storedConnection } from '../connections/connection_documents';
import { ASSISTANT_VIAS } from '../principal';

/**
 * The authorization server's own records (assistants ADR-0002): root
 * collections no client may read or write, each keyed by a SHA-256 so a
 * leaked database holds no usable credential, and each carrying `expiresAt`
 * for a TTL policy to remove.
 */
export const ASSISTANT_CLIENTS = 'assistantClients';
export const ASSISTANT_AUTH_REQUESTS = 'assistantAuthRequests';
export const ASSISTANT_CODES = 'assistantCodes';
export const ASSISTANT_TOKENS = 'assistantTokens';

export const AUTH_REQUEST_LIFETIME_MS = 10 * 60 * 1000;
export const CODE_LIFETIME_MS = 60 * 1000;
/** How long a redeemed code is kept, so presenting it again is caught (RFC 6749 §4.1.2). */
export const REDEEMED_CODE_WATCH_MS = 10 * 60 * 1000;
/**
 * A rotated refresh token presented this soon after its rotation is a retry,
 * and gets back the pair its rotation issued; later, it is theft.
 */
export const REFRESH_REUSE_GRACE_MS = 60 * 1000;
export const ACCESS_TOKEN_LIFETIME_MS = 60 * 60 * 1000;
export const REFRESH_TOKEN_LIFETIME_MS = 30 * 24 * 60 * 60 * 1000;
export const CLIENT_DOCUMENT_CACHE_MS = 24 * 60 * 60 * 1000;
export const REGISTERED_CLIENT_LIFETIME_MS = 365 * 24 * 60 * 60 * 1000;

export const ACCESS_TOKEN_PREFIX = 'npa_';
export const REFRESH_TOKEN_PREFIX = 'npr_';
export const REGISTERED_CLIENT_PREFIX = 'npc_';

/** 32 random bytes, base64url: what every code, token and session cookie is. */
export function newSecret(): string {
  return randomBytes(32).toString('base64url');
}

export function sha256Hex(value: string): string {
  return hash('sha256', value, 'hex');
}

/** RFC 7636 S256: whether the verifier hashes to the challenge, compared in constant time. */
export function pkceMatches(verifier: string, challenge: string): boolean {
  const derived = Buffer.from(hash('sha256', verifier, 'base64url'));
  const expected = Buffer.from(challenge);
  return derived.length === expected.length && timingSafeEqual(derived, expected);
}

const timestamp = z.instanceof(Timestamp);
const scopes = z.array(z.enum(ASSISTANT_SCOPES));
const via = z.enum(ASSISTANT_VIAS);

export const storedClient = z.object({
  kind: z.enum(['cimd', 'dcr']),
  clientId: z.string(),
  clientName: z.string(),
  host: z.string(),
  redirectUris: z.array(z.string()),
  via,
  fetchedAt: timestamp,
  expiresAt: timestamp,
});
export type StoredClient = z.infer<typeof storedClient>;

/**
 * A pending authorize. The client's name, host and `via` are copied from the
 * client record when the request is made, so what the consent page shows is
 * what was checked, even if the cached document expires meanwhile.
 */
export const storedAuthRequest = z.object({
  clientId: z.string(),
  clientName: z.string(),
  host: z.string(),
  via,
  redirectUri: z.string(),
  codeChallenge: z.string(),
  state: z.string(),
  resource: z.string(),
  scopes,
  sessionHash: z.string(),
  createdAt: timestamp,
  expiresAt: timestamp,
});
export type StoredAuthRequest = z.infer<typeof storedAuthRequest>;

/**
 * An authorization code (assistants ADR-0002, ADR-0003). It carries
 * everything the member decided on the consent page — the grant's own fields
 * — because the grant is written only when the code is redeemed: a sign-in
 * abandoned after consent leaves no connection behind. A redeemed code is
 * kept, with `redeemedAt`, the `grantId` it became and a later `expiresAt`, so
 * that presenting it again is recognised and ends that grant (RFC 6749
 * §4.1.2).
 */
export const storedCode = storedConnection
  .pick({
    uid: true,
    memberId: true,
    clientId: true,
    clientName: true,
    host: true,
    via: true,
    scopes: true,
    consent: true,
  })
  .extend({
    householdId: z.string(),
    redirectUri: z.string(),
    codeChallenge: z.string(),
    resource: z.string(),
    expiresAt: timestamp,
    redeemedAt: timestamp.nullable(),
    grantId: z.string().nullable(),
  });
export type StoredCode = z.infer<typeof storedCode>;

/**
 * An access or refresh token, for the one `resource` it was minted for.
 * `scopes` is what this token may do — a refresh may narrow it, never widen
 * it. `rotatedAt` marks a refresh token that has been spent, kept until it
 * would have expired so that presenting it again is recognised as theft;
 * `successor` is the pair its rotation issued, sealed under
 * `ASSISTANTS_TOKEN_KEY` for `REFRESH_REUSE_GRACE_MS`, so a retry gets that
 * same pair back and never a second chain. `predecessor` is the spent token
 * whose `successor` this one is, wiped when this one is rotated in turn.
 */
export const storedToken = z.object({
  kind: z.enum(['access', 'refresh']),
  grantId: z.string(),
  householdId: z.string(),
  clientId: z.string(),
  resource: z.string(),
  scopes,
  expiresAt: timestamp,
  rotatedAt: timestamp.nullable().optional(),
  successor: z.object({ sealed: z.string(), expiresAt: timestamp }).nullable().optional(),
  predecessor: z.string().nullable().optional(),
});
export type StoredToken = z.infer<typeof storedToken>;

export function clientRef(store: Firestore, clientId: string): DocumentReference {
  return store.collection(ASSISTANT_CLIENTS).doc(sha256Hex(clientId));
}

export function authRequestRef(store: Firestore, requestId: string): DocumentReference {
  return store.collection(ASSISTANT_AUTH_REQUESTS).doc(requestId);
}

export function codeRef(store: Firestore, code: string): DocumentReference {
  return store.collection(ASSISTANT_CODES).doc(sha256Hex(code));
}

export function tokenRef(store: Firestore, token: string): DocumentReference {
  return store.collection(ASSISTANT_TOKENS).doc(sha256Hex(token));
}

export function later(now: Date, ms: number): Timestamp {
  return Timestamp.fromMillis(now.getTime() + ms);
}

export function hasExpired(expiresAt: Timestamp, now: Date): boolean {
  return expiresAt.toMillis() <= now.getTime();
}
