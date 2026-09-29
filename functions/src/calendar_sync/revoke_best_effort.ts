import { logger } from 'firebase-functions/v2';

import type { CalendarSource } from './calendar_source';
import { HttpUnreachable } from '../shared/http_client';

/**
 * Tells the provider NestPrep has let go of a credential, without letting a
 * provider that is down stop the disconnect that asked (BE-09). The failure is
 * logged, not lost (ENG-10): the credential is deleted either way, and an
 * unrevoked Google grant expires unused after six months.
 */
export async function revokeBestEffort(
  source: CalendarSource,
  credential: string,
  provider: string,
): Promise<void> {
  try {
    await source.revoke(credential);
  } catch (error) {
    if (!(error instanceof HttpUnreachable)) throw error;
    logger.warn('calendar revoke did not reach the provider', { provider, reason: error.reason });
  }
}
