import { isIP } from 'node:net';

import { type Firestore, Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';

import { isLoopbackAddress } from '../../calendar_sync/link_guard';
import { jsonOf } from '../../shared/http_client';
import {
  CLIENT_DOCUMENT_CACHE_MS,
  type StoredClient,
  clientRef,
  hasExpired,
  later,
  storedClient,
} from './auth_documents';
import { type ClientDocumentFetch, ClientDocumentUnavailable } from './client_document_fetch';
import { isAllowedRedirect, viaOfRedirect } from './redirect_policy';

/**
 * Who is asking (assistants ADR-0002). A `client_id` that is a URL is a
 * Client ID Metadata Document — the client describes itself at that address,
 * which NestPrep fetches and caches for a day; anything else must be a client
 * NestPrep registered itself (`/oauth/register`). Either way only the
 * redirects the allowlist trusts are kept, and a client left with none is no
 * client at all.
 */
export interface ClientLookup {
  readonly store: Firestore;
  readonly fetchDocument: ClientDocumentFetch;
  readonly allowLoopbackRedirects: boolean;
  /** The emulator suite's escape: a plain-http client document on this machine. */
  readonly allowLocalDocuments: boolean;
  readonly now: Date;
}

export type ClientResolution =
  | { readonly kind: 'client'; readonly client: StoredClient }
  | { readonly kind: 'unknown'; readonly reason: string };

/**
 * A client may list grant and response types NestPrep never issues — Claude's
 * own document adds `urn:ietf:params:oauth:grant-type:jwt-bearer` — so a list
 * only has to include the code flow; the token endpoint refuses the rest.
 */
export const clientGrantTypes = z
  .array(z.string().max(200))
  .max(10)
  .refine((types) => types.includes('authorization_code'));
export const clientResponseTypes = z
  .array(z.string().max(200))
  .max(10)
  .refine((types) => types.includes('code'));

const clientDocument = z.object({
  client_id: z.string(),
  client_name: z.string().trim().min(1).max(100).optional(),
  redirect_uris: z.array(z.string().max(2048)).min(1).max(20),
  token_endpoint_auth_method: z.literal('none').optional(),
  grant_types: clientGrantTypes.optional(),
  response_types: clientResponseTypes.optional(),
});

export async function resolveClient(
  lookup: ClientLookup,
  clientId: string,
): Promise<ClientResolution> {
  const url = clientDocumentUrl(clientId, lookup.allowLocalDocuments);
  const cached = storedClient.safeParse((await clientRef(lookup.store, clientId).get()).data());
  if (cached.success && !hasExpired(cached.data.expiresAt, lookup.now)) {
    const expectedKind = url === null ? 'dcr' : 'cimd';
    return cached.data.kind === expectedKind && cached.data.clientId === clientId
      ? { kind: 'client', client: cached.data }
      : { kind: 'unknown', reason: 'kindMismatch' };
  }
  if (url === null) return { kind: 'unknown', reason: 'notRegistered' };
  return fetchClient(lookup, clientId, url);
}

async function fetchClient(
  lookup: ClientLookup,
  clientId: string,
  url: URL,
): Promise<ClientResolution> {
  let body: string;
  try {
    body = await lookup.fetchDocument(url);
  } catch (error) {
    if (error instanceof ClientDocumentUnavailable) {
      return { kind: 'unknown', reason: `document ${error.reason}` };
    }
    throw error;
  }
  const parsed = clientDocument.safeParse(jsonOf(body));
  if (!parsed.success) return { kind: 'unknown', reason: 'documentShape' };
  if (parsed.data.client_id !== clientId) return { kind: 'unknown', reason: 'documentIdMismatch' };

  const redirectUris = parsed.data.redirect_uris.filter((uri) =>
    isAllowedRedirect(uri, lookup.allowLoopbackRedirects),
  );
  const first = redirectUris[0];
  if (first === undefined) return { kind: 'unknown', reason: 'noAllowedRedirect' };

  const client: StoredClient = {
    kind: 'cimd',
    clientId,
    clientName: parsed.data.client_name ?? url.host,
    host: url.host,
    redirectUris,
    via: viaOfRedirect(first),
    fetchedAt: Timestamp.fromDate(lookup.now),
    expiresAt: later(lookup.now, CLIENT_DOCUMENT_CACHE_MS),
  };
  const batch = lookup.store.batch();
  batch.set(clientRef(lookup.store, clientId), client);
  await batch.commit();
  return { kind: 'client', client };
}

/**
 * The URL a metadata-document client id names, or null when the id is not
 * one. The draft's rules: https, a path, no fragment, no credentials, no dot
 * segments — so one document has exactly one spelling — and a domain, never
 * an IP address, except loopback under the emulator escape.
 */
export function clientDocumentUrl(clientId: string, allowLocal: boolean): URL | null {
  if (!/^https?:\/\//.test(clientId) || clientId.length > 2048) return null;
  let url: URL;
  try {
    url = new URL(clientId);
  } catch (error) {
    if (error instanceof TypeError) return null;
    throw error;
  }
  const schemeOk = url.protocol === 'https:' || (allowLocal && url.protocol === 'http:');
  const dotSegment = clientId
    .split(/[?#]/)[0]
    ?.split('/')
    .some((part) => /^\.\.?$/.test(part));
  if (
    !schemeOk ||
    url.hash !== '' ||
    url.username !== '' ||
    url.password !== '' ||
    url.pathname === '/' ||
    dotSegment === true ||
    url.href !== clientId ||
    (isIP(url.hostname.replace(/^\[|\]$/g, '')) !== 0 &&
      !(allowLocal && isLoopbackAddress(url.hostname)))
  ) {
    return null;
  }
  return url;
}
