import { onCall } from 'firebase-functions/v2/https';

import { db } from '../shared/firestore';
import { parseInput, requireUid } from '../household/parse_input';
import { callerIn } from './caller_access';
import { householdInput } from './schemas';
import { oauthClients } from './sync_config';

/**
 * Which calendars this deployment can connect, so the screen can say "not set
 * up yet" before anybody taps, rather than after (calendar ADR-0003, FE-09).
 * A calendar link and the household feed need no credentials and are always
 * there.
 */
export const listCalendarProviders = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(householdInput, request.data);
  await callerIn(db(), input.householdId, uid);
  const clients = oauthClients(false);
  return { google: clients.google !== undefined, microsoft: clients.microsoft !== undefined };
});
