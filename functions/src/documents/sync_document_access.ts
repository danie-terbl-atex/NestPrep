import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { writeAccountClaims } from '../household/access_claim';
import { requireUid } from '../household/parse_input';

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
  // Both claims, `households` and the per-area `access` a kid, helper or carer
  // holds (household ADR-0003), written together and keeping any other claim.
  const households = await writeAccountClaims(db(), uid);

  logger.info('document access synced', { households });
  return { households };
});
