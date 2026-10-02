import { logger } from 'firebase-functions/v2';
import { onRequest } from 'firebase-functions/v2/https';

import { clientAddress } from '../shared/client_address';
import { db } from '../shared/firestore';
import { consumeRateLimit } from '../shared/rate_limit';
import { REQUESTS_PER_ADDRESS, REQUESTS_PER_DAY, recordDeletionRequest } from './deletion_requests';
import { accountDeletionRequestInput } from './schemas';
import { HOSTING_REGION } from '../shared/region';

/**
 * The public "request deletion" form's endpoint (accounts ADR-0006), reached
 * through Firebase Hosting's rewrite of `/api/account-deletion-request`, so the
 * page and the endpoint share an origin and no CORS is involved.
 *
 * Anybody can reach it, so it is rate-limited per address and in total, parses
 * a strict body, answers in four words the page knows — `received`, `invalid`,
 * `tooMany`, `unavailable` — and never says whether an account exists. The
 * address is never logged (ENG-22).
 */
export const requestAccountDeletion = onRequest({ region: HOSTING_REGION }, async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ status: 'invalid' });
    return;
  }
  const parsed = accountDeletionRequestInput.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ status: 'invalid' });
    return;
  }
  try {
    const store = db();
    const now = new Date();
    const allowed =
      (await consumeRateLimit(store, REQUESTS_PER_DAY, 'all', now)) &&
      (await consumeRateLimit(store, REQUESTS_PER_ADDRESS, clientAddress(req), now));
    if (!allowed) {
      logger.warn('account deletion request refused by the rate limit');
      res.status(429).json({ status: 'tooMany' });
      return;
    }
    const outcome = await recordDeletionRequest(store, parsed.data, now);
    logger.info('account deletion requested on the web', { outcome });
    res.status(202).json({ status: 'received' });
  } catch (error: unknown) {
    logger.error('account deletion request could not be recorded', {
      error: error instanceof Error ? error.message : String(error),
    });
    res.status(500).json({ status: 'unavailable' });
  }
});
