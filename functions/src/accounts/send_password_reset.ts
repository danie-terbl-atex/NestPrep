import { getAuth } from 'firebase-admin/auth';
import { defineString } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { parseInput } from '../household/parse_input';
import { resendApiKey } from '../premium_vouchers/premium_config';
import { clientAddress } from '../shared/client_address';
import { configured } from '../shared/configured_value';
import { resendEmailSender, silentEmailSender } from '../shared/email_sender';
import { runsInEmulator } from '../shared/feature_flags';
import { db } from '../shared/firestore';
import { consumeRateLimit } from '../shared/rate_limit';
import {
  refusePasswordReset,
  sendPasswordResetInput,
  sendPasswordResetLink,
} from './password_reset';

export const accountEmailFrom = defineString('ACCOUNT_EMAIL_FROM', { default: '' });

const NO_RESET_FOR = new Set(['auth/user-not-found', 'auth/email-not-found', 'auth/user-disabled']);

async function firebaseResetLink(email: string): Promise<string | null> {
  try {
    return await getAuth().generatePasswordResetLink(email);
  } catch (error: unknown) {
    const code = (error as { code?: unknown }).code;
    if (NO_RESET_FOR.has(String(code))) return null;
    logger.error('password reset link could not be made', { authError: String(code) });
    throw refusePasswordReset('unavailable');
  }
}

/**
 * The link to set a new password, sent by us through Resend as a branded
 * email that opens on `app.nestprep.io/reset-password`, instead of Firebase's
 * stock email from a `firebaseapp.com` address (accounts ADR-0012).
 *
 * **Unauthenticated on purpose**: the person cannot sign in, which is the
 * point. Rate limited per caller, per address and overall.
 */
export const sendPasswordReset = onCall({ secrets: [resendApiKey] }, async (request) => {
  const { email } = parseInput(sendPasswordResetInput, request.data);
  const store = db();
  const now = new Date();
  return sendPasswordResetLink(
    {
      consume: (rule, subject) => consumeRateLimit(store, rule, subject, now),
      resetLink: firebaseResetLink,
      sender: runsInEmulator()
        ? silentEmailSender
        : resendEmailSender({
            apiKey: configured(resendApiKey.value()),
            from: configured(accountEmailFrom.value()),
          }),
    },
    email,
    clientAddress(request.rawRequest),
  );
});
