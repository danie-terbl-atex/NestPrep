import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { issueVouchers } from './issue_vouchers';
import { premiumPepper } from './premium_config';
import { issueVouchersInput } from './schemas';
import { storeEndpoint } from './store_endpoint';

export const issuePremiumVouchers = storeEndpoint(
  'issuePremiumVouchers',
  issueVouchersInput,
  async (input) => {
    const results = await issueVouchers(db(), premiumPepper(), input, new Date());
    logger.info('premium vouchers issued', {
      issued: results.filter((result) => result.outcome === 'issued').length,
      existed: results.filter((result) => result.outcome === 'exists').length,
    });
    return { results };
  },
);
