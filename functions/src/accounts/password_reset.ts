import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { EmailNotSent, type EmailSender } from '../shared/email_sender';
import type { RateLimitRule } from '../shared/rate_limit';
import { passwordResetMessage, resetPageLink } from './password_reset_email';

const HOUR = 60 * 60;

export const PASSWORD_RESETS_PER_ADDRESS: RateLimitRule = {
  name: 'passwordReset:address',
  limit: 20,
  windowSeconds: HOUR,
};

export const PASSWORD_RESETS_PER_EMAIL: RateLimitRule = {
  name: 'passwordReset:email',
  limit: 3,
  windowSeconds: HOUR,
};

export const PASSWORD_RESETS_OVERALL: RateLimitRule = {
  name: 'passwordReset:all',
  limit: 500,
  windowSeconds: HOUR,
};

export const sendPasswordResetInput = z.object({
  email: z.string().trim().toLowerCase().max(254).pipe(z.email()),
});

export const PASSWORD_RESET_REFUSALS = {
  tooManyAttempts: ['resource-exhausted', 'Too many reset links asked for. Wait and try again.'],
  unavailable: ['unavailable', 'The reset email could not be sent right now.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type PasswordResetRefusal = keyof typeof PASSWORD_RESET_REFUSALS;

export function refusePasswordReset(reason: PasswordResetRefusal): HttpsError {
  const [code, message] = PASSWORD_RESET_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}

export interface PasswordResetDeps {
  readonly consume: (rule: RateLimitRule, subject: string) => Promise<boolean>;
  readonly resetLink: (email: string) => Promise<string | null>;
  readonly sender: EmailSender;
}

/**
 * Sends a reset link only to an address that has an account, but answers
 * `sent` either way: saying which addresses are registered is what Firebase's
 * enumeration protection exists to prevent (accounts ADR-0002).
 */
export async function sendPasswordResetLink(
  deps: PasswordResetDeps,
  email: string,
  callerAddress: string,
): Promise<{ sent: true }> {
  const allowed =
    (await deps.consume(PASSWORD_RESETS_PER_ADDRESS, callerAddress)) &&
    (await deps.consume(PASSWORD_RESETS_PER_EMAIL, email)) &&
    (await deps.consume(PASSWORD_RESETS_OVERALL, 'all'));
  if (!allowed) {
    logger.warn('password reset refused by the rate limit');
    throw refusePasswordReset('tooManyAttempts');
  }

  const firebaseLink = await deps.resetLink(email);
  if (firebaseLink === null) {
    logger.info('password reset asked for an address with no account');
    return { sent: true };
  }
  const link = resetPageLink(firebaseLink);
  if (link === null) {
    logger.error('password reset link carried no code');
    throw refusePasswordReset('unavailable');
  }

  try {
    await deps.sender.send(passwordResetMessage(email, link));
  } catch (error) {
    logger.error('password reset email not sent', {
      why: error instanceof EmailNotSent ? error.why : 'unexpected',
    });
    throw refusePasswordReset('unavailable');
  }
  logger.info('password reset email sent');
  return { sent: true };
}
