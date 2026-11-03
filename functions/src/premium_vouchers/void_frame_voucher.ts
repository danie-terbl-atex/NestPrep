import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { voidVoucherInput } from './schemas';
import { storeEndpoint } from './store_endpoint';
import { voidVoucher } from './void_voucher';

export const voidFrameVoucher = storeEndpoint(
  'voidFrameVoucher',
  voidVoucherInput,
  async (input) => {
    const outcome = await voidVoucher(db(), input, new Date());
    logger.info('frame voucher void asked', { voucherId: input.voucherId, outcome });
    return { outcome };
  },
);
