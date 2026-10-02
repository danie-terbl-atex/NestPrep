import { onCall } from 'firebase-functions/v2/https';

import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { CHECKERS_SECRETS } from './checkers_config';
import { checkersHere, requireAddToCheckers, sessionKeyHere } from './checkers_runtime';
import { FirestoreLinkStore } from './firestore_link_store';
import { verifyLinkOtp } from './otp_link';
import { checkersVerifyOtpInput } from './schemas';

/**
 * Verifies the SMS code and links the member's Checkers account for the hour
 * Checkers gives (the Checkers build contract). Five codes per sent code, each
 * counted before Checkers is asked.
 */
export const checkersVerifyOtp = onCall(
  { secrets: CHECKERS_SECRETS, timeoutSeconds: 60 },
  async (request) => {
    const uid = requireUid(request.auth);
    const input = parseInput(checkersVerifyOtpInput, request.data);
    const store = db();
    await requireAddToCheckers(store);
    return verifyLinkOtp(
      {
        links: new FirestoreLinkStore(store),
        login: checkersHere().login,
        key: sessionKeyHere(),
        now: new Date(),
      },
      uid,
      input.code,
    );
  },
);
