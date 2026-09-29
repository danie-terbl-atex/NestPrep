import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { parseInput, requireUid } from '../household/parse_input';
import { liveCalendarSources } from './calendar_sources';
import { callerIn } from './caller_access';
import { refuseCalendarSync } from './errors';
import { newStateAndChallenge, savePending } from './oauth_state';
import { startCalendarConnectionInput } from './schemas';
import { functionUrl } from './sync_config';

/** The HTTP Function the provider sends the browser back to. */
export const OAUTH_CALLBACK_NAME = 'calendarOAuthCallback';

/**
 * The first half of connecting Google or Outlook: a one-time `state`, a PKCE
 * challenge, and the provider's consent page to open in the browser
 * (calendar ADR-0003). The second half is `calendarOAuthCallback`; the phone
 * never sees a code or a token.
 */
export const startCalendarConnection = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(startCalendarConnectionInput, request.data);
  const store = db();
  const caller = await callerIn(store, input.householdId, uid, 'edit');

  const connector = liveCalendarSources(false).oauth(input.provider);
  if (connector === null) throw refuseCalendarSync('providerNotConfigured');

  const { state, codeVerifier, codeChallenge } = newStateAndChallenge();
  await savePending(
    store,
    state,
    {
      uid,
      householdId: input.householdId,
      memberId: caller.memberId,
      provider: input.provider,
      codeVerifier,
    },
    new Date(),
  );

  logger.info('calendar connection started', { provider: input.provider });
  return {
    authorizationUrl: connector.authorizationUrl({
      state,
      codeChallenge,
      redirectUri: functionUrl(OAUTH_CALLBACK_NAME),
    }),
  };
});
