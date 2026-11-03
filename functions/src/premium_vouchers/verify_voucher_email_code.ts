import { onCall } from 'firebase-functions/v2/https';

import { parseInput, requireUid } from '../household/parse_input';
import { verifyEmailCode } from './email_code';
import { premiumEmailPepper } from './premium_config';
import { verifyVoucherEmailCodeInput } from './schemas';
import { liveVerifyDeps } from './voucher_runtime';

export const verifyVoucherEmailCode = onCall({ secrets: [premiumEmailPepper] }, async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(verifyVoucherEmailCodeInput, request.data);
  return verifyEmailCode(liveVerifyDeps(), uid, input);
});
