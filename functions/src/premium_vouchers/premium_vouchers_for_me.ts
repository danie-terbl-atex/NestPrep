import { onCall } from 'firebase-functions/v2/https';

import { parseInput, requireUid } from '../household/parse_input';
import { premiumEmailPepper } from './premium_config';
import { premiumVouchersForMeInput } from './schemas';
import { liveVoucherDeps } from './voucher_runtime';
import { vouchersWaitingFor } from './vouchers_for_me';

export const premiumVouchersForMe = onCall({ secrets: [premiumEmailPepper] }, async (request) => {
  const uid = requireUid(request.auth);
  parseInput(premiumVouchersForMeInput, request.data);
  return vouchersWaitingFor(liveVoucherDeps(), uid);
});
