import { type Firestore, Timestamp } from 'firebase-admin/firestore';

import { db } from '../../shared/firestore';
import { consumeRateLimit } from '../../shared/rate_limit';
import { connectionRef, storedConnection } from '../connections/connection_documents';
import { type Authenticate, AssistantRefusal } from '../principal';
import { authorizationServer } from './assistants_config';
import { hasExpired, storedToken, tokenRef } from './auth_documents';
import { CALLS_PER_GRANT } from './auth_rate_limits';

/** `lastUsedAt` is written at most this often, so a busy connection is not a write per call. */
export const LAST_USED_GRANULARITY_MS = 15 * 60 * 1000;

const BEARER = /^Bearer +(npa_[A-Za-z0-9_-]{43})$/i;

/**
 * Turns `Authorization: Bearer npa_…` into the connection it acts for
 * (assistants ADR-0002, ADR-0003), against `store`. Only an access token this
 * server issued is accepted — a Firebase ID token, a refresh token or
 * anything else is `invalidToken` — only for `resource`, the one this
 * origin serves (a token minted under another origin is refused, RFC 8707),
 * and only while the grant it names still exists; a token outliving its
 * grant is deleted on sight. Each connection
 * may make 300 calls an hour. The live member check is `requireAccess`'s,
 * on every tool call, not this.
 */
export function bearerAuthenticator(
  store: Firestore,
  resource: string = authorizationServer().resource,
): Authenticate {
  return async (authorization, now) => {
    const token = BEARER.exec(authorization ?? '')?.[1];
    if (token === undefined) throw invalidToken('malformed');
    const ref = tokenRef(store, token);
    const parsed = storedToken.safeParse((await ref.get()).data());
    if (!parsed.success || parsed.data.kind !== 'access') throw invalidToken('unknown');
    const held = parsed.data;
    if (held.resource !== resource) throw invalidToken('otherResource');
    if (hasExpired(held.expiresAt, now)) {
      await deleteToken(store, ref);
      throw invalidToken('expired');
    }

    const grantRef = connectionRef(store, held.householdId, held.grantId);
    const grant = storedConnection.safeParse((await grantRef.get()).data());
    if (!grant.success || grant.data.clientId !== held.clientId) {
      await deleteToken(store, ref);
      throw invalidToken('grantGone');
    }

    if (!(await consumeRateLimit(store, CALLS_PER_GRANT, held.grantId, now))) {
      throw new AssistantRefusal(
        'rateLimited',
        'callsPerHour',
        'This connection has made a lot of requests this hour. Try again later.',
      );
    }
    const lastUsed = grant.data.lastUsedAt?.toMillis() ?? 0;
    if (now.getTime() - lastUsed >= LAST_USED_GRANULARITY_MS) {
      const batch = store.batch();
      batch.update(grantRef, { lastUsedAt: Timestamp.fromDate(now) });
      await batch.commit();
    }

    return {
      grantId: held.grantId,
      uid: grant.data.uid,
      householdId: held.householdId,
      via: grant.data.via,
      scopes: held.scopes.filter((scope) => grant.data.scopes.includes(scope)),
    };
  };
}

/** The `Authenticate` the MCP endpoint is wired with: `bearerAuthenticator` on the shared store. */
export const authenticateBearer: Authenticate = (authorization, now) =>
  bearerAuthenticator(db())(authorization, now);

function invalidToken(reason: string): AssistantRefusal {
  return new AssistantRefusal('invalidToken', reason, 'Sign in to NestPrep again.');
}

async function deleteToken(
  store: Firestore,
  ref: FirebaseFirestore.DocumentReference,
): Promise<void> {
  const batch = store.batch();
  batch.delete(ref);
  await batch.commit();
}
