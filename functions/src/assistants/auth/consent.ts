import { type Firestore, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { isFamilyRole } from '../../household/access';
import { HOUSEHOLDS, userRef } from '../../household/documents';
import { consumeRateLimit } from '../../shared/rate_limit';
import { requireAccess, requireSwitchedOn } from '../assistant_access';
import { ASSISTANT_SCOPES } from '../assistant_scopes';
import { AssistantRefusal } from '../principal';
import { ASSISTANT_CONSENT_VERSION } from '../connections/connection_documents';
import type { AuthorizationServer } from './assistants_config';
import {
  CODE_LIFETIME_MS,
  type StoredAuthRequest,
  type StoredCode,
  authRequestRef,
  codeRef,
  hasExpired,
  later,
  newSecret,
  sha256Hex,
  storedAuthRequest,
} from './auth_documents';
import { CONSENT_OVERALL, CONSENT_PER_ADDRESS } from './auth_rate_limits';
import { type AuthReply, json } from './auth_reply';
import { clientRedirect } from './authorize';
import { type IdTokenVerifier, checkFreshSignIn } from './fresh_sign_in';

export interface ConsentContext {
  readonly store: Firestore;
  readonly server: AuthorizationServer;
  readonly verify: IdTokenVerifier;
  readonly address: string;
  readonly session: string | null;
  readonly now: Date;
}

/** Households a consent page lists, at most. */
const HOUSEHOLD_LIMIT = 20;

const requestId = z.string().regex(/^[A-Za-z0-9_-]{43}$/);
const idToken = z.string().min(1).max(8192);
const describeInput = z.object({ requestId });
const householdsInput = z.object({ requestId, idToken });
const decideInput = z.discriminatedUnion('decision', [
  z.object({
    requestId,
    idToken,
    decision: z.literal('allow'),
    householdId: z.string().regex(/^[A-Za-z0-9_-]{1,128}$/),
    scopes: z.array(z.enum(ASSISTANT_SCOPES)).min(1).max(ASSISTANT_SCOPES.length),
  }),
  z.object({ requestId, decision: z.literal('deny') }),
]);

/**
 * The consent page's three calls (assistants ADR-0002, ADR-0003), each only
 * for the browser that started the authorize: `describe` says who is asking
 * and for what, `households` lists where the signed-in member is family, and
 * `decide` either refuses or — after the same live check every tool call
 * makes — spends the request for a one-minute code carrying the member's
 * decision, and hands back where to send the browser. The grant itself is
 * written when the code is redeemed, so a sign-in abandoned here leaves no
 * connection. Answers are words the page knows, never internals.
 */
export async function answerConsent(
  context: ConsentContext,
  action: string,
  body: unknown,
): Promise<AuthReply> {
  if (
    !(await consumeRateLimit(context.store, CONSENT_OVERALL, 'all', context.now)) ||
    !(await consumeRateLimit(context.store, CONSENT_PER_ADDRESS, context.address, context.now))
  ) {
    return json(429, { error: 'tooMany' });
  }
  switch (action) {
    case 'describe':
      return describe(context, body);
    case 'households':
      return households(context, body);
    case 'decide':
      return decide(context, body);
    default:
      return json(404, { error: 'notFound' });
  }
}

async function describe(context: ConsentContext, body: unknown): Promise<AuthReply> {
  const input = describeInput.safeParse(body);
  if (!input.success) return json(400, { error: 'invalidRequest' });
  const pending = await liveRequest(context, input.data.requestId);
  if (pending === null) return json(404, { error: 'requestNotFound' });
  const off = await switchedOff(context.store);
  if (off !== null) return off;
  return json(200, {
    clientName: pending.clientName,
    host: pending.host,
    via: pending.via,
    scopes: pending.scopes,
  });
}

async function households(context: ConsentContext, body: unknown): Promise<AuthReply> {
  const input = householdsInput.safeParse(body);
  if (!input.success) return json(400, { error: 'invalidRequest' });
  if ((await liveRequest(context, input.data.requestId)) === null) {
    return json(404, { error: 'requestNotFound' });
  }
  const signIn = await checkFreshSignIn(context.verify, input.data.idToken, context.now);
  if (signIn.kind === 'refused') return json(401, { error: signIn.reason });
  const off = await switchedOff(context.store);
  if (off !== null) return off;

  const listed: unknown = (await userRef(context.store, signIn.uid).get()).get('householdIds');
  const ids = Array.isArray(listed)
    ? listed.filter((id): id is string => typeof id === 'string').slice(0, HOUSEHOLD_LIMIT)
    : [];
  const snapshots =
    ids.length === 0
      ? []
      : await context.store.getAll(
          ...ids.map((id) => context.store.collection(HOUSEHOLDS).doc(id)),
        );
  const family = snapshots.flatMap((snapshot) => {
    const role: unknown = snapshot.get(`members.${signIn.uid}`);
    const name: unknown = snapshot.get('name');
    return typeof role === 'string' && isFamilyRole(role) && typeof name === 'string'
      ? [{ id: snapshot.id, name }]
      : [];
  });
  return json(200, { households: family });
}

async function decide(context: ConsentContext, body: unknown): Promise<AuthReply> {
  const input = decideInput.safeParse(body);
  if (!input.success) return json(400, { error: 'invalidRequest' });
  const pending = await liveRequest(context, input.data.requestId);
  if (pending === null) return json(404, { error: 'requestNotFound' });
  const { store, server, now } = context;

  if (input.data.decision === 'deny') {
    const batch = store.batch();
    batch.delete(authRequestRef(store, input.data.requestId));
    await batch.commit();
    return json(200, {
      redirect: clientRedirect(server, pending.redirectUri, {
        error: 'access_denied',
        state: pending.state,
      }),
    });
  }

  const { householdId, scopes } = input.data;
  if (!scopes.every((scope) => pending.scopes.includes(scope))) {
    return json(400, { error: 'invalidScopes' });
  }
  const signIn = await checkFreshSignIn(context.verify, input.data.idToken, now);
  if (signIn.kind === 'refused') return json(401, { error: signIn.reason });

  let memberId: string;
  try {
    ({ memberId } = await requireAccess(
      store,
      { grantId: '', uid: signIn.uid, householdId, via: pending.via, scopes: ['household:read'] },
      'household:read',
      now,
    ));
  } catch (error) {
    if (error instanceof AssistantRefusal) {
      return json(error.kind === 'switchedOff' ? 503 : 403, { error: error.reason });
    }
    throw error;
  }

  const code = newSecret();
  const granted = ASSISTANT_SCOPES.filter((scope) => scopes.includes(scope));
  const spent = await store.runTransaction(async (transaction) => {
    const requestRef = authRequestRef(store, input.data.requestId);
    const live = parseLive((await transaction.get(requestRef)).data(), context);
    if (live === null) return true;
    const decided: StoredCode = {
      uid: signIn.uid,
      householdId,
      memberId,
      clientId: live.clientId,
      clientName: live.clientName,
      host: live.host,
      via: live.via,
      scopes: granted,
      consent: { version: ASSISTANT_CONSENT_VERSION, at: Timestamp.fromDate(now) },
      redirectUri: live.redirectUri,
      codeChallenge: live.codeChallenge,
      resource: live.resource,
      expiresAt: later(now, CODE_LIFETIME_MS),
      redeemedAt: null,
      grantId: null,
    };
    transaction.delete(requestRef);
    transaction.create(codeRef(store, code), decided);
    return false;
  });
  if (spent) return json(404, { error: 'requestNotFound' });

  logger.info('assistant consent given', {
    householdId,
    via: pending.via,
    scopes: granted.length,
  });
  return json(200, {
    redirect: clientRedirect(server, pending.redirectUri, { code, state: pending.state }),
  });
}

async function liveRequest(context: ConsentContext, id: string): Promise<StoredAuthRequest | null> {
  return parseLive((await authRequestRef(context.store, id).get()).data(), context);
}

/** The request, if it is unexpired and was started by this browser. */
function parseLive(data: unknown, context: ConsentContext): StoredAuthRequest | null {
  const parsed = storedAuthRequest.safeParse(data);
  if (!parsed.success || context.session === null) return null;
  if (parsed.data.sessionHash !== sha256Hex(context.session)) return null;
  if (hasExpired(parsed.data.expiresAt, context.now)) return null;
  return parsed.data;
}

async function switchedOff(store: Firestore): Promise<AuthReply | null> {
  try {
    await requireSwitchedOn(store);
    return null;
  } catch (error) {
    if (error instanceof AssistantRefusal) return json(503, { error: error.reason });
    throw error;
  }
}
