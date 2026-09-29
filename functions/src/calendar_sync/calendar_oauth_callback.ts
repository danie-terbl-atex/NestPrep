import { HttpsError, onRequest } from 'firebase-functions/v2/https';

import { db } from '../shared/firestore';
import { callbackPage } from './callback_page';
import { liveCalendarSources } from './calendar_sources';
import { callerIn } from './caller_access';
import { completeOAuth } from './complete_oauth';
import { FirestoreSyncStore } from './firestore_sync_store';
import { createConnection } from './new_connection';
import { consumePending } from './oauth_state';
import { OAUTH_CALLBACK_NAME } from './start_calendar_connection';
import { PROVIDER_SECRETS, functionUrl } from './sync_config';
import { syncConnection } from './sync_engine';

/**
 * Where Google and Microsoft send the browser back with a code (calendar
 * ADR-0003). The code is exchanged here, with the client secret, and the
 * refresh token goes straight into the private collection — the phone never
 * holds it (ENG-18). The answer is a page in words, never a code.
 */
export const calendarOAuthCallback = onRequest({ secrets: PROVIDER_SECRETS }, async (req, res) => {
  const store = db();
  const sources = liveCalendarSources(true);
  const param = (name: string): string | null => {
    const value = req.query[name];
    return typeof value === 'string' && value !== '' ? value : null;
  };
  const outcome = await completeOAuth(
    {
      consumePending: (state) => consumePending(store, state, new Date()),
      connector: (provider) => sources.oauth(provider),
      isStillMember: async (householdId, uid) => {
        try {
          await callerIn(store, householdId, uid);
          return true;
        } catch (error) {
          // `callerIn` refuses with an HttpsError when the account is no
          // longer in the household; anything else is a real failure.
          if (error instanceof HttpsError) return false;
          throw error;
        }
      },
      createConnection: (connection) => createConnection(store, connection),
      firstSync: async (householdId, connectionId) => {
        await syncConnection(
          { store: new FirestoreSyncStore(store), sources, now: () => new Date() },
          householdId,
          connectionId,
        );
      },
      redirectUri: functionUrl(OAUTH_CALLBACK_NAME),
    },
    { code: param('code'), state: param('state'), error: param('error') },
  );
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'no-store');
  res.status(outcome.kind === 'connected' ? 200 : 400).send(callbackPage(outcome));
});
