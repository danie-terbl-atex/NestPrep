import { FieldValue, type Firestore, Timestamp, type Transaction } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { isFamilyRole } from '../../household/access';
import { householdRef } from '../../household/documents';
import { consumeRateLimit } from '../../shared/rate_limit';
import { openJson, sealJson } from '../../shared/sealed_json';
import { ASSISTANT_SCOPES, type AssistantScope, parseScopes } from '../assistant_scopes';
import {
  ASSISTANT_CONNECTIONS,
  type StoredConnection,
  connectionRef,
  storedConnection,
} from '../connections/connection_documents';
import { deleteGrants } from '../connections/delete_grants';
import type { AuthorizationServer } from './assistants_config';
import {
  ACCESS_TOKEN_LIFETIME_MS,
  ACCESS_TOKEN_PREFIX,
  REDEEMED_CODE_WATCH_MS,
  REFRESH_REUSE_GRACE_MS,
  REFRESH_TOKEN_LIFETIME_MS,
  REFRESH_TOKEN_PREFIX,
  ASSISTANT_TOKENS,
  type StoredToken,
  codeRef,
  sha256Hex,
  hasExpired,
  later,
  newSecret,
  pkceMatches,
  storedCode,
  storedToken,
  tokenRef,
} from './auth_documents';
import { TOKEN_OVERALL, TOKEN_PER_GRANT, tokenRateSubject } from './auth_rate_limits';
import { type AuthReply, json, oauthError } from './auth_reply';

export interface TokenContext {
  readonly store: Firestore;
  readonly server: AuthorizationServer;
  readonly now: Date;
  /** `ASSISTANTS_TOKEN_KEY`, read only when a refresh needs it. */
  readonly tokenKey: () => Buffer;
}

const VERIFIER = /^[A-Za-z0-9._~-]{43,128}$/;
const secret = z.string().min(1).max(512);
const clientId = z.string().min(1).max(2048);

const codeGrant = z.object({
  grant_type: z.literal('authorization_code'),
  code: secret,
  client_id: clientId,
  redirect_uri: z.string().min(1).max(2048),
  code_verifier: z.string().max(256).optional(),
  resource: z.string().max(2048).optional(),
});

const refreshGrant = z.object({
  grant_type: z.literal('refresh_token'),
  refresh_token: secret,
  client_id: clientId,
  scope: z.string().max(1000).optional(),
  resource: z.string().max(2048).optional(),
});

const grantType = z.object({ grant_type: z.string() });

/** What a rotation seals onto the spent token: the very pair it issued. */
const sealedPair = z.object({
  access: z.string(),
  refresh: z.string(),
  scopes: z.array(z.enum(ASSISTANT_SCOPES)),
});

type Issued =
  | {
      readonly kind: 'issued';
      readonly grantId: string;
      readonly access: string;
      readonly refresh: string;
      readonly scopes: readonly AssistantScope[];
      readonly expiresInSeconds: number;
    }
  | { readonly kind: 'refused'; readonly error: string; readonly description: string }
  | {
      readonly kind: 'reused';
      readonly presented: 'code' | 'refreshToken';
      readonly householdId: string;
      readonly grantId: string;
    };

/**
 * `POST /oauth/token` (assistants ADR-0002, ADR-0003). Redeeming a code
 * writes the grant the member consented to and its first token pair in one
 * transaction, and keeps the code marked redeemed; a code that fails any
 * check is deleted, so a wrong verifier burns it rather than inviting another
 * guess, and a redeemed code presented again ends the grant it became (RFC
 * 6749 §4.1.2). A refresh token is rotated: the old one is marked spent, a
 * new pair issued for the same scopes or fewer, and that pair sealed onto the
 * spent token for `REFRESH_REUSE_GRACE_MS`. A spent one presented again in
 * that window — a client's retry, or a second refresh racing the first — gets
 * that same pair back, so there is only ever one chain; presented later, or
 * once its successor has itself been rotated, it means two parties hold it,
 * so the whole grant goes, every token with it. Each grant's requests are
 * counted for its client (the callers are the assistants' servers, one
 * address for all their members), under an overall ceiling. Errors are RFC
 * 6749's.
 */
export async function exchangeToken(context: TokenContext, body: unknown): Promise<AuthReply> {
  const { store, now } = context;
  if (!(await consumeRateLimit(store, TOKEN_OVERALL, 'all', now))) {
    return tooMany();
  }
  const kind = grantType.safeParse(body);
  if (!kind.success) return oauthError(400, 'invalid_request', 'grant_type is required');

  let issued: Issued;
  if (kind.data.grant_type === 'authorization_code') {
    const input = codeGrant.safeParse(body);
    if (!input.success)
      return oauthError(400, 'invalid_request', 'code, client_id and redirect_uri are required');
    const code = storedCode.safeParse((await codeRef(store, input.data.code).get()).data());
    const counted = code.success ? (code.data.grantId ?? sha256Hex(input.data.code)) : 'unknown';
    if (!(await withinGrantLimit(context, input.data.client_id, counted))) return tooMany();
    issued = await redeemCode(context, input.data);
  } else if (kind.data.grant_type === 'refresh_token') {
    const input = refreshGrant.safeParse(body);
    if (!input.success)
      return oauthError(400, 'invalid_request', 'refresh_token and client_id are required');
    const token = storedToken.safeParse(
      (await tokenRef(store, input.data.refresh_token).get()).data(),
    );
    const counted = token.success ? token.data.grantId : 'unknown';
    if (!(await withinGrantLimit(context, input.data.client_id, counted))) return tooMany();
    issued = await rotateRefresh(context, input.data);
  } else {
    return oauthError(400, 'unsupported_grant_type');
  }

  if (issued.kind === 'reused') {
    await deleteGrants(context.store, issued.householdId, [issued.grantId]);
    logger.warn('assistant credential reused; grant revoked', {
      grantId: issued.grantId,
      presented: issued.presented,
    });
    return oauthError(
      400,
      'invalid_grant',
      issued.presented === 'code' ? 'code is no longer valid' : 'refresh token is no longer valid',
    );
  }
  if (issued.kind === 'refused') return oauthError(400, issued.error, issued.description);
  return json(200, {
    access_token: issued.access,
    token_type: 'Bearer',
    expires_in: issued.expiresInSeconds,
    refresh_token: issued.refresh,
    scope: issued.scopes.join(' '),
  });
}

function tooMany(): AuthReply {
  return oauthError(429, 'temporarily_unavailable', 'too many token requests');
}

function withinGrantLimit(
  context: TokenContext,
  clientId: string,
  grantOrCode: string,
): Promise<boolean> {
  return consumeRateLimit(
    context.store,
    TOKEN_PER_GRANT,
    tokenRateSubject(clientId, grantOrCode),
    context.now,
  );
}

async function redeemCode(
  context: TokenContext,
  input: z.infer<typeof codeGrant>,
): Promise<Issued> {
  const { store, server, now } = context;
  if (input.resource !== undefined && input.resource !== server.resource) {
    return refused('invalid_target', `resource must be ${server.resource}`);
  }
  const issued = await store.runTransaction(async (transaction): Promise<Issued> => {
    const ref = codeRef(store, input.code);
    const parsed = storedCode.safeParse((await transaction.get(ref)).data());
    if (!parsed.success) return refused('invalid_grant', 'code is not valid');
    const code = parsed.data;
    if (code.redeemedAt !== null && code.grantId !== null) {
      return {
        kind: 'reused',
        presented: 'code',
        householdId: code.householdId,
        grantId: code.grantId,
      };
    }
    const role: unknown = (await transaction.get(householdRef(store, code.householdId))).get(
      `members.${code.uid}`,
    );

    const verifier = input.code_verifier ?? '';
    if (
      hasExpired(code.expiresAt, now) ||
      code.clientId !== input.client_id ||
      code.redirectUri !== input.redirect_uri ||
      code.resource !== server.resource ||
      !VERIFIER.test(verifier) ||
      !pkceMatches(verifier, code.codeChallenge) ||
      typeof role !== 'string' ||
      !isFamilyRole(role)
    ) {
      transaction.delete(ref);
      return refused('invalid_grant', 'code is not valid');
    }

    const grantRef = householdRef(store, code.householdId).collection(ASSISTANT_CONNECTIONS).doc();
    const grant: StoredConnection = {
      uid: code.uid,
      memberId: code.memberId,
      clientId: code.clientId,
      clientName: code.clientName,
      host: code.host,
      via: code.via,
      scopes: code.scopes,
      consent: code.consent,
      createdAt: Timestamp.fromDate(now),
      lastUsedAt: null,
      refreshGeneration: 0,
    };
    transaction.create(grantRef, grant);
    transaction.update(ref, {
      redeemedAt: Timestamp.fromDate(now),
      grantId: grantRef.id,
      expiresAt: later(now, REDEEMED_CODE_WATCH_MS),
    });
    return issuePair(transaction, context, {
      grantId: grantRef.id,
      householdId: code.householdId,
      clientId: code.clientId,
      resource: code.resource,
      scopes: code.scopes,
    }).issued;
  });
  if (issued.kind === 'issued') {
    logger.info('assistant connected', { grantId: issued.grantId, scopes: issued.scopes.length });
  }
  return issued;
}

async function rotateRefresh(
  context: TokenContext,
  input: z.infer<typeof refreshGrant>,
): Promise<Issued> {
  const { store, server, now } = context;
  if (input.resource !== undefined && input.resource !== server.resource) {
    return refused('invalid_target', `resource must be ${server.resource}`);
  }
  if (!input.refresh_token.startsWith(REFRESH_TOKEN_PREFIX)) {
    return refused('invalid_grant', 'refresh token is not valid');
  }
  return store.runTransaction(async (transaction): Promise<Issued> => {
    const ref = tokenRef(store, input.refresh_token);
    const token = storedToken.safeParse((await transaction.get(ref)).data());
    if (!token.success || token.data.kind !== 'refresh') {
      return refused('invalid_grant', 'refresh token is not valid');
    }
    const held = token.data;
    if (held.resource !== server.resource) {
      return refused('invalid_grant', 'refresh token was issued for another resource');
    }
    const otherClient = refused('invalid_grant', 'refresh token was issued to another client');
    const theft: Issued = {
      kind: 'reused',
      presented: 'refreshToken',
      householdId: held.householdId,
      grantId: held.grantId,
    };
    const rotatedAt = held.rotatedAt ?? null;
    if (rotatedAt !== null) {
      const successor = held.successor ?? null;
      if (successor === null || hasExpired(successor.expiresAt, now)) return theft;
      if (held.clientId !== input.client_id) return otherClient;
      const pair = await openJson(sealedPair, context.tokenKey(), ref.id, successor.sealed);
      if (pair === null) return refused('invalid_grant', 'refresh token is not valid');
      const next = storedToken.safeParse(
        (await transaction.get(tokenRef(store, pair.refresh))).data(),
      );
      if (!next.success || (next.data.rotatedAt ?? null) !== null) return theft;
      const elapsed = now.getTime() - rotatedAt.toMillis();
      return {
        kind: 'issued',
        grantId: held.grantId,
        access: pair.access,
        refresh: pair.refresh,
        scopes: pair.scopes,
        expiresInSeconds: Math.floor((ACCESS_TOKEN_LIFETIME_MS - elapsed) / 1000),
      };
    }

    const grantRef = connectionRef(store, held.householdId, held.grantId);
    const grant = storedConnection.safeParse((await transaction.get(grantRef)).data());
    const predecessorRef =
      held.predecessor === undefined || held.predecessor === null
        ? null
        : store.collection(ASSISTANT_TOKENS).doc(held.predecessor);
    const predecessor = predecessorRef === null ? null : await transaction.get(predecessorRef);
    if (hasExpired(held.expiresAt, now) || !grant.success) {
      transaction.delete(ref);
      return refused('invalid_grant', 'refresh token is not valid');
    }
    if (held.clientId !== input.client_id) return otherClient;
    const asked = input.scope === undefined ? held.scopes : parseScopes(input.scope);
    if (asked.length === 0 || !asked.every((scope) => held.scopes.includes(scope))) {
      return refused('invalid_scope', 'a refresh may only keep or narrow the scopes');
    }

    const { issued, pair } = issuePair(transaction, context, {
      grantId: held.grantId,
      householdId: held.householdId,
      clientId: held.clientId,
      resource: held.resource,
      scopes: held.scopes,
      accessScopes: asked,
      predecessor: ref.id,
    });
    transaction.update(ref, {
      rotatedAt: Timestamp.fromDate(now),
      successor: {
        sealed: await sealJson(context.tokenKey(), ref.id, pair),
        expiresAt: later(now, REFRESH_REUSE_GRACE_MS),
      },
    });
    if (predecessorRef !== null && predecessor?.exists === true) {
      transaction.update(predecessorRef, { successor: null });
    }
    transaction.update(grantRef, { refreshGeneration: FieldValue.increment(1) });
    return issued;
  });
}

/**
 * A new access token and refresh token, stored only as their hashes. The
 * refresh keeps the scopes it was given (RFC 6749 §6); the access token may
 * carry fewer when the client asked for fewer.
 */
function issuePair(
  transaction: Transaction,
  context: TokenContext,
  grant: {
    grantId: string;
    householdId: string;
    clientId: string;
    resource: string;
    scopes: readonly AssistantScope[];
    accessScopes?: readonly AssistantScope[];
    predecessor?: string;
  },
): { issued: Issued; pair: z.infer<typeof sealedPair> } {
  const { store, now } = context;
  const access = `${ACCESS_TOKEN_PREFIX}${newSecret()}`;
  const refresh = `${REFRESH_TOKEN_PREFIX}${newSecret()}`;
  const accessScopes = [...(grant.accessScopes ?? grant.scopes)];
  const base = {
    grantId: grant.grantId,
    householdId: grant.householdId,
    clientId: grant.clientId,
    resource: grant.resource,
  };
  const accessToken: StoredToken = {
    ...base,
    kind: 'access',
    scopes: accessScopes,
    expiresAt: later(now, ACCESS_TOKEN_LIFETIME_MS),
    rotatedAt: null,
  };
  const refreshToken: StoredToken = {
    ...base,
    kind: 'refresh',
    scopes: [...grant.scopes],
    expiresAt: later(now, REFRESH_TOKEN_LIFETIME_MS),
    rotatedAt: null,
    predecessor: grant.predecessor ?? null,
  };
  transaction.create(tokenRef(store, access), accessToken);
  transaction.create(tokenRef(store, refresh), refreshToken);
  return {
    issued: {
      kind: 'issued',
      grantId: grant.grantId,
      access,
      refresh,
      scopes: accessScopes,
      expiresInSeconds: ACCESS_TOKEN_LIFETIME_MS / 1000,
    },
    pair: { access, refresh, scopes: accessScopes },
  };
}

function refused(error: string, description: string): Issued {
  return { kind: 'refused', error, description };
}
