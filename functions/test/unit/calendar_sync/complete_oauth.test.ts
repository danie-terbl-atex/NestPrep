import { beforeEach, describe, expect, it } from 'vitest';

import { callbackCopy, callbackPage } from '../../../src/calendar_sync/callback_page';
import type {
  AuthorizationRequest,
  CodeExchange,
  ExchangedAccount,
  FetchOutcome,
  OAuthCalendar,
} from '../../../src/calendar_sync/calendar_source';
import { completeOAuth, type OAuthCompletionDeps } from '../../../src/calendar_sync/complete_oauth';
import type { NewConnection } from '../../../src/calendar_sync/new_connection';
import type { PendingConnection } from '../../../src/calendar_sync/oauth_state';

/**
 * The second half of connecting Google or Outlook (calendar ADR-0003): every
 * way back from the provider, each ending in words (FE-09).
 */
class FakeConnector implements OAuthCalendar {
  account: ExchangedAccount | null = { refreshToken: 'refresh-1', accountLabel: 'sam@example.com' };
  exchanges: CodeExchange[] = [];
  revoked: string[] = [];

  authorizationUrl(request: AuthorizationRequest): string {
    return `https://provider.test/?state=${request.state}`;
  }

  exchangeCode(exchange: CodeExchange): Promise<ExchangedAccount | null> {
    this.exchanges.push(exchange);
    return Promise.resolve(this.account);
  }

  fetchOccurrences(): Promise<FetchOutcome> {
    return Promise.resolve({ kind: 'ok', occurrences: [], refreshedCredential: null });
  }

  revoke(credential: string): Promise<void> {
    this.revoked.push(credential);
    return Promise.resolve();
  }
}

const PENDING: PendingConnection = {
  uid: 'uid-sam',
  householdId: 'h1',
  memberId: 'm-sam',
  provider: 'google',
  codeVerifier: 'verifier-1',
};

let connector: FakeConnector;
let created: NewConnection[];
let synced: string[];
let pending: PendingConnection | null;
let member: boolean;
let deps: OAuthCompletionDeps;

beforeEach(() => {
  connector = new FakeConnector();
  created = [];
  synced = [];
  pending = PENDING;
  member = true;
  deps = {
    consumePending: (): Promise<PendingConnection | null> => Promise.resolve(pending),
    connector: (): OAuthCalendar => connector,
    isStillMember: (): Promise<boolean> => Promise.resolve(member),
    createConnection: (connection): Promise<string> => {
      created.push(connection);
      return Promise.resolve('c-new');
    },
    firstSync: (_householdId, connectionId): Promise<void> => {
      synced.push(connectionId);
      return Promise.resolve();
    },
    redirectUri: 'https://functions.test/calendarOAuthCallback',
  };
});

const query = { code: 'code-1', state: 'state-123456789012', error: null };

describe('coming back from the provider', () => {
  it('files the connection under the member who started it, and syncs it', async () => {
    expect(await completeOAuth(deps, query)).toEqual({ kind: 'connected', provider: 'google' });
    expect(created).toEqual([
      {
        householdId: 'h1',
        provider: 'google',
        memberId: 'm-sam',
        ownerUid: 'uid-sam',
        accountLabel: 'sam@example.com',
        credential: 'refresh-1',
      },
    ]);
    expect(synced).toEqual(['c-new']);
    expect(connector.exchanges[0]).toEqual({
      code: 'code-1',
      codeVerifier: 'verifier-1',
      redirectUri: 'https://functions.test/calendarOAuthCallback',
    });
  });

  it('with no state, or a state already spent, has expired', async () => {
    expect(await completeOAuth(deps, { ...query, state: null })).toEqual({ kind: 'expired' });
    pending = null;
    expect(await completeOAuth(deps, query)).toEqual({ kind: 'expired' });
    expect(created).toEqual([]);
  });

  it('declined on the consent page connects nothing', async () => {
    expect(
      await completeOAuth(deps, { code: null, state: query.state, error: 'access_denied' }),
    ).toEqual({
      kind: 'declined',
    });
    expect(connector.exchanges).toEqual([]);
  });

  it('when the provider will not exchange the code, says so', async () => {
    connector.account = null;
    expect(await completeOAuth(deps, query)).toEqual({ kind: 'failed', provider: 'google' });
    expect(created).toEqual([]);
  });

  it('when the provider is no longer configured, says not set up', async () => {
    deps = { ...deps, connector: (): null => null };
    expect(await completeOAuth(deps, query)).toEqual({ kind: 'notConfigured' });
  });

  it('for somebody removed from the household meanwhile, gives the token straight back', async () => {
    member = false;
    expect(await completeOAuth(deps, query)).toEqual({ kind: 'expired' });
    expect(connector.revoked).toEqual(['refresh-1']);
    expect(created).toEqual([]);
  });
});

describe('the page it answers with', () => {
  it('is words for every outcome, never a code or a token', () => {
    const outcomes = [
      { kind: 'connected', provider: 'microsoft' },
      { kind: 'declined' },
      { kind: 'expired' },
      { kind: 'failed', provider: 'google' },
      { kind: 'notConfigured' },
    ] as const;
    for (const outcome of outcomes) {
      const page = callbackPage(outcome);
      expect(page).toContain(callbackCopy(outcome).title);
      expect(page).not.toMatch(/invalid_grant|refresh|access_denied|<script/i);
    }
    expect(callbackCopy({ kind: 'connected', provider: 'microsoft' }).title).toBe(
      'Outlook is connected',
    );
  });
});
