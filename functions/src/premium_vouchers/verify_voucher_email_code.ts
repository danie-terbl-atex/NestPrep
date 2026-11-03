import { onCall } from 'firebase-functions/v2/https';

import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { verifyEmailCode } from './email_code';
import { premiumEmailPepper, premiumPepper } from './premium_config';
import { verifyVoucherEmailCodeInput } from './schemas';

export const verifyVoucherEmailCode = onCall({ secrets: [premiumEmailPepper] }, async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(verifyVoucherEmailCodeInput, request.data);
  return verifyEmailCode({ store: db(), pepper: premiumPepper(), now: new Date() }, uid, input);
});
