import { onCall } from 'firebase-functions/v2/https';

import { parseInput, requireUid } from '../household/parse_input';
import { claimVoucher } from './claim_voucher';
import { premiumEmailPepper } from './premium_config';
import { claimPremiumVoucherInput } from './schemas';
import { liveVoucherDeps } from './voucher_runtime';

export const claimPremiumVoucher = onCall({ secrets: [premiumEmailPepper] }, async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(claimPremiumVoucherInput, request.data);
  return claimVoucher(liveVoucherDeps(), uid, input);
});
