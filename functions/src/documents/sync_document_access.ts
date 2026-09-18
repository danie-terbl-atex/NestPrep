import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { auth } from '../shared/auth';
import { db } from '../shared/firestore';
import { requireUid } from '../household/parse_input';
import { CLAIM_NAME, householdClaimFor } from './household_claim';

/**
 * Puts the caller's household memberships onto their own ID token, so Storage
 * Security Rules can see them (documents ADR-0001).
 *
 * There is no input: the subject is whoever is calling, and their memberships
 * are re-derived from Firestore rather than taken from the request (BE-03). It
 * is safe to call twice and it refuses nobody — an account in no household
 * gets an empty claim, which is the correct answer and the one that takes
 * access away again after a removal.
 *
 * The client force-refreshes its ID token afterwards; until it does, the token
 * in hand still carries the old claim. That window is up to an hour if nothing
 * calls this, which is the staleness the ADR accepts.
 */
export const syncDocumentAccess = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const claim = await householdClaimFor(db(), uid);

  // Custom claims are written whole, so anything else on the token would be
  // lost by writing only ours. There is nothing else today; there will be.
  const existing = (await auth().getUser(uid)).customClaims ?? {};
  await auth().setCustomUserClaims(uid, { ...existing, [CLAIM_NAME]: claim });

  logger.info('document access synced', { households: Object.keys(claim).length });
  return { households: Object.keys(claim).length };
});
