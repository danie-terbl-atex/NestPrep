import { logger } from 'firebase-functions/v2';

import { WoolworthsRejected, WoolworthsUnavailable } from './woolworths_api';
import { refuseWoolworths } from './woolworths_errors';

export async function asWoolworths<T>(call: () => Promise<T>, what: string): Promise<T> {
  try {
    return await call();
  } catch (error) {
    if (error instanceof WoolworthsUnavailable) {
      logger.warn(`woolworths ${what}`, { reason: error.reason });
      throw refuseWoolworths('woolworths-unavailable');
    }
    if (error instanceof WoolworthsRejected) {
      logger.warn(`woolworths ${what}`, { status: error.status });
      throw refuseWoolworths('woolworths-rejected');
    }
    throw error;
  }
}
