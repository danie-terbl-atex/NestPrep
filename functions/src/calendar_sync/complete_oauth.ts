import { logger } from 'firebase-functions/v2';

import type { CallbackOutcome } from './callback_page';
import type { OAuthCalendar } from './calendar_source';
import type { NewConnection } from './new_connection';
import type { PendingConnection } from './oauth_state';
import { revokeBestEffort } from './revoke_best_effort';
import type { OAuthProvider } from './sync_documents';

/**
 * The second half of connecting Google or Outlook, as a rule with its
 * collaborators handed in so every branch is tested without a browser or a
 * provider (BE-01, BE-14). `calendarOAuthCallback` is the transport around it.
 */
export interface OAuthCompletionDeps {
  consumePending(state: string): Promise<PendingConnection | null>;
  connector(provider: OAuthProvider): OAuthCalendar | null;
  isStillMember(householdId: string, uid: string): Promise<boolean>;
  createConnection(connection: NewConnection): Promise<string>;
  /** The first sync. Its failure is recorded on the connection, not thrown here. */
  firstSync(householdId: string, connectionId: string): Promise<void>;
  readonly redirectUri: string;
}

export interface CallbackQuery {
  readonly code: string | null;
  readonly state: string | null;
  readonly error: string | null;
}

export async function completeOAuth(
  deps: OAuthCompletionDeps,
  query: CallbackQuery,
): Promise<CallbackOutcome> {
  if (query.state === null) return { kind: 'expired' };
  // The state is spent whatever happens next, so a replayed or declined
  // redirect cannot be finished later by somebody else.
  const pending = await deps.consumePending(query.state);
  if (pending === null) return { kind: 'expired' };
  if (query.error !== null || query.code === null) return { kind: 'declined' };

  const connector = deps.connector(pending.provider);
  if (connector === null) return { kind: 'notConfigured' };

  const account = await connector.exchangeCode({
    code: query.code,
    codeVerifier: pending.codeVerifier,
    redirectUri: deps.redirectUri,
  });
  if (account === null) {
    logger.warn('calendar code exchange refused', { provider: pending.provider });
    return { kind: 'failed', provider: pending.provider };
  }
  // Ten minutes is long enough to have been removed from the household.
  if (!(await deps.isStillMember(pending.householdId, pending.uid))) {
    await revokeBestEffort(connector, account.refreshToken, pending.provider);
    return { kind: 'expired' };
  }

  const connectionId = await deps.createConnection({
    householdId: pending.householdId,
    provider: pending.provider,
    memberId: pending.memberId,
    ownerUid: pending.uid,
    accountLabel: account.accountLabel,
    credential: account.refreshToken,
  });
  await deps.firstSync(pending.householdId, connectionId);
  logger.info('calendar connected', { provider: pending.provider, connectionId });
  return { kind: 'connected', provider: pending.provider };
}
