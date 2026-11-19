import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { requireUid } from '../household/parse_input';
import { resendApiKey } from '../premium_vouchers/premium_config';
import { auth } from '../shared/auth';
import { configured } from '../shared/configured_value';
import { resendEmailSender, silentEmailSender } from '../shared/email_sender';
import { runsInEmulator } from '../shared/feature_flags';
import { db } from '../shared/firestore';
import { consumeRateLimit } from '../shared/rate_limit';
import { accountEmailFrom } from './send_password_reset';
import { sendWelcome, type WelcomeAccount } from './welcome';

async function welcomeAccount(uid: string): Promise<WelcomeAccount> {
  const user = await auth().getUser(uid);
  return {
    email: user.email,
    displayName: user.displayName,
    disabled: user.disabled,
    needsConfirming:
      !user.emailVerified &&
      user.providerData.some((provider) => provider.providerId === 'password'),
  };
}

async function firebaseVerifyLink(email: string): Promise<string | null> {
  try {
    return await auth().generateEmailVerificationLink(email);
  } catch (error: unknown) {
    logger.error('verification link could not be made', {
      authError: String((error as { code?: unknown }).code),
    });
    return null;
  }
}

/**
 * A new account's welcome, sent once, with a confirm button for a password
 * account; replaces Firebase's stock verification email (accounts ADR-0015).
 */
export const sendWelcomeEmail = onCall({ secrets: [resendApiKey] }, async (request) => {
  const uid = requireUid(request.auth);
  const store = db();
  const now = new Date();
  return sendWelcome(
    {
      consume: (rule, subject) => consumeRateLimit(store, rule, subject, now),
      account: welcomeAccount,
      verifyLink: firebaseVerifyLink,
      sender: runsInEmulator()
        ? silentEmailSender
        : resendEmailSender({
            apiKey: configured(resendApiKey.value()),
            from: configured(accountEmailFrom.value()),
          }),
    },
    uid,
  );
});
