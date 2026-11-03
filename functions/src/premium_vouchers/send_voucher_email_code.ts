import { onCall } from 'firebase-functions/v2/https';

import { parseInput, requireUid } from '../household/parse_input';
import { sendEmailCode } from './email_code';
import { premiumEmailPepper, resendApiKey } from './premium_config';
import { sendVoucherEmailCodeInput } from './schemas';
import { liveEmailCodeDeps } from './voucher_runtime';

export const sendVoucherEmailCode = onCall(
  { secrets: [premiumEmailPepper, resendApiKey] },
  async (request) => {
    const uid = requireUid(request.auth);
    const input = parseInput(sendVoucherEmailCodeInput, request.data);
    return sendEmailCode(liveEmailCodeDeps(), uid, input.email);
  },
);
