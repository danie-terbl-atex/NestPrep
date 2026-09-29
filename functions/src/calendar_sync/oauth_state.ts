import { hash, randomBytes } from 'node:crypto';

import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { OAUTH_PROVIDERS, type OAuthProvider, oauthStateRef } from './sync_documents';

/**
 * A connection in flight: the `state` that ties the provider's redirect back
 * to the member who started it, and the PKCE verifier only the server knows
 * (calendar ADR-0003). It lives ten minutes and works once.
 */
export const STATE_LIFETIME_MS = 10 * 60 * 1000;

export interface PendingConnection {
  readonly uid: string;
  readonly householdId: string;
  readonly memberId: string;
  readonly provider: OAuthProvider;
  readonly codeVerifier: string;
}

const pendingShape = z.object({
  uid: z.string(),
  householdId: z.string(),
  memberId: z.string(),
  provider: z.enum(OAUTH_PROVIDERS),
  codeVerifier: z.string(),
  expiresAt: z.instanceof(Timestamp),
});

export interface StateAndChallenge {
  readonly state: string;
  readonly codeVerifier: string;
  readonly codeChallenge: string;
}

export function newStateAndChallenge(): StateAndChallenge {
  const codeVerifier = randomBytes(32).toString('base64url');
  return {
    state: randomBytes(24).toString('base64url'),
    codeVerifier,
    codeChallenge: hash('sha256', codeVerifier, 'base64url'),
  };
}

export async function savePending(
  store: Firestore,
  state: string,
  pending: PendingConnection,
  now: Date,
): Promise<void> {
  const batch = store.batch();
  batch.set(oauthStateRef(store, state), {
    ...pending,
    expiresAt: Timestamp.fromMillis(now.getTime() + STATE_LIFETIME_MS),
  });
  await batch.commit();
}

/**
 * The pending connection for [state], deleted in the same transaction it is
 * read in so a replayed redirect finds nothing. Null when it never existed,
 * was used, or expired.
 */
export async function consumePending(
  store: Firestore,
  state: string,
  now: Date,
): Promise<PendingConnection | null> {
  if (!/^[A-Za-z0-9_-]{16,64}$/.test(state)) return null;
  return store.runTransaction(async (transaction) => {
    const ref = oauthStateRef(store, state);
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) return null;
    transaction.delete(ref);
    const parsed = pendingShape.safeParse(snapshot.data());
    if (!parsed.success || parsed.data.expiresAt.toMillis() < now.getTime()) return null;
    const { uid, householdId, memberId, provider, codeVerifier } = parsed.data;
    return { uid, householdId, memberId, provider, codeVerifier };
  });
}
