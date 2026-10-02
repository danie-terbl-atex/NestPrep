import { onCall } from 'firebase-functions/v2/https';

import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { CHECKERS_SECRETS } from './checkers_config';
import { checkersHere, requireAddToCheckers, sessionKeyHere } from './checkers_runtime';
import { FirestoreLinkStore } from './firestore_link_store';
import { requestLinkOtp } from './otp_link';
import { allowCode } from './otp_rate_limit';
import { checkersRequestOtpInput } from './schemas';

/**
 * Sends a Checkers login code by SMS to the number the member typed — only
 * ever on their explicit ask (the Checkers build contract). A Function rather
 * than the phone because the session the code leads to is held by the server,
 * sealed, and never reaches a client.
 */
export const checkersRequestOtp = onCall({ secrets: CHECKERS_SECRETS }, async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(checkersRequestOtpInput, request.data);
  const store = db();
  await requireAddToCheckers(store);
  return requestLinkOtp(
    {
      links: new FirestoreLinkStore(store),
      login: checkersHere().login,
      key: sessionKeyHere(),
      now: new Date(),
      allowCode: (subject, mobile) => allowCode(store, subject, mobile),
    },
    uid,
    input.mobile,
  );
});
