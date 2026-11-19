import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { EmailNotSent, type EmailSender } from '../shared/email_sender';
import type { RateLimitRule } from '../shared/rate_limit';
import { firstNameOf, verifyPageLink, welcomeMessage } from './welcome_email';

export const WELCOMES_PER_ACCOUNT: RateLimitRule = {
  name: 'welcomeEmail:account',
  limit: 1,
  windowSeconds: 30 * 24 * 60 * 60,
};

export const WELCOMES_OVERALL: RateLimitRule = {
  name: 'welcomeEmail:all',
  limit: 500,
  windowSeconds: 60 * 60,
};

export const WELCOME_REFUSALS = {
  tooManyAttempts: ['resource-exhausted', 'Too many welcome emails just now.'],
  unavailable: ['unavailable', 'The welcome email could not be sent right now.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type WelcomeRefusal = keyof typeof WELCOME_REFUSALS;

export function refuseWelcome(reason: WelcomeRefusal): HttpsError {
  const [code, message] = WELCOME_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}

export interface WelcomeAccount {
  readonly email: string | undefined;
  readonly displayName: string | undefined;
  readonly disabled: boolean;
  readonly needsConfirming: boolean;
}

export interface WelcomeDeps {
  readonly consume: (rule: RateLimitRule, subject: string) => Promise<boolean>;
  readonly account: (uid: string) => Promise<WelcomeAccount>;
  readonly verifyLink: (email: string) => Promise<string | null>;
  readonly sender: EmailSender;
}

/**
 * Per account before overall, so an account calling in a loop spends only its
 * own single welcome and never the budget every new account shares.
 */
export async function sendWelcome(deps: WelcomeDeps, uid: string): Promise<{ sent: boolean }> {
  const account = await deps.account(uid);
  if (account.email === undefined || account.email === '' || account.disabled) {
    logger.info('welcome email skipped: no address to send to');
    return { sent: false };
  }
  if (!(await deps.consume(WELCOMES_PER_ACCOUNT, uid))) {
    logger.info('welcome email skipped: already sent');
    return { sent: false };
  }
  if (!(await deps.consume(WELCOMES_OVERALL, 'all'))) {
    logger.warn('welcome email refused by the overall rate limit');
    throw refuseWelcome('tooManyAttempts');
  }

  const firebaseLink = account.needsConfirming ? await deps.verifyLink(account.email) : null;
  const confirmLink = firebaseLink === null ? null : verifyPageLink(firebaseLink);
  if (account.needsConfirming && confirmLink === null) {
    logger.error('welcome email goes without its confirm link');
  }

  try {
    await deps.sender.send(
      welcomeMessage(account.email, firstNameOf(account.displayName), confirmLink),
    );
  } catch (error) {
    logger.error('welcome email not sent', {
      why: error instanceof EmailNotSent ? error.why : 'unexpected',
    });
    throw refuseWelcome('unavailable');
  }
  logger.info('welcome email sent', { withConfirmLink: confirmLink !== null });
  return { sent: true };
}
