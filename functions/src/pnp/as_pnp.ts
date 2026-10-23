import { logger } from 'firebase-functions/v2';

import { PnpUnavailable } from './pnp_api';
import { refusePnp } from './pnp_errors';

/**
 * A PnP call whose unavailability is the member's `pnp-down`, logged with its
 * reason (never a token or a body) — the one translation every PnP callable
 * shares (BE-04).
 */
export async function asPnp<T>(call: () => Promise<T>, what: string): Promise<T> {
  try {
    return await call();
  } catch (error) {
    if (error instanceof PnpUnavailable) {
      logger.warn(`pnp ${what}`, { reason: error.reason });
      throw refusePnp('pnp-down');
    }
    throw error;
  }
}
