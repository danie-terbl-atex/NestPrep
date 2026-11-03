import { randomInt } from 'node:crypto';

import { HttpsError } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import type { RateLimitRule } from '../shared/rate_limit';
import { refuseSubscription } from '../subscriptions/errors';
import { type ChallengeStore, EMAIL_CODES_PER_HOUR } from './email_challenges';
import { type EmailSender, EmailNotSent, emailCodeMessage } from './email_sender';
import { emailHashOf, includesHash, maskEmail, otpHashOf } from './premium_hashes';

const HOUR = 60 * 60;

export const EMAIL_CODES_PER_ADDRESS: RateLimitRule = {
  name: 'voucherEmailCode:email',
  limit: 5,
  windowSeconds: HOUR,
};

export const EMAIL_CODES_PER_ACCOUNT_DAY: RateLimitRule = {
  name: 'voucherEmailCode:account:day',
  limit: 10,
  windowSeconds: 24 * HOUR,
};

export interface EmailCodeDeps {
  readonly challenges: ChallengeStore;
  readonly provenHashes: (uid: string) => Promise<readonly string[]>;
  readonly pepper: string;
  readonly sender: EmailSender;
  readonly newCode: () => string;
  readonly consume: (rule: RateLimitRule, subject: string) => Promise<boolean>;
  readonly now: Date;
}

export function randomEmailCode(): string {
  return randomInt(0, 1_000_000).toString().padStart(6, '0');
}

export async function sendEmailCode(
  deps: EmailCodeDeps,
  uid: string,
  email: string,
): Promise<{ sent: true; emailMasked: string }> {
  const { pepper, now } = deps;
  const emailHash = await emailHashOf(pepper, email);
  if (includesHash(await deps.provenHashes(uid), emailHash)) {
    throw refuseSubscription('emailAlreadyVerified');
  }
  if ((await deps.challenges.sentThisHour(uid, now)) >= EMAIL_CODES_PER_HOUR) {
    throw refuseSubscription('tooManyCodes');
  }
  if (!(await deps.consume(EMAIL_CODES_PER_ACCOUNT_DAY, uid))) {
    throw refuseSubscription('tooManyCodes');
  }
  if (!(await deps.consume(EMAIL_CODES_PER_ADDRESS, emailHash))) {
    throw refuseSubscription('tooManyCodes');
  }
  const code = deps.newCode();
  try {
    await deps.sender.send(emailCodeMessage(email, code));
  } catch (error) {
    logger.error('voucher email code not sent', {
      why: error instanceof EmailNotSent ? error.why : 'unexpected',
    });
    throw new HttpsError('unavailable', 'The email could not be sent.');
  }
  await deps.challenges.record(
    uid,
    { emailHash, codeHash: await otpHashOf(pepper, uid, code) },
    now,
  );
  logger.info('voucher email code sent', { uid });
  return { sent: true, emailMasked: maskEmail(email) };
}

export async function verifyEmailCode(
  deps: Pick<EmailCodeDeps, 'challenges' | 'pepper' | 'now'>,
  uid: string,
  input: { readonly email: string; readonly code: string },
): Promise<{ verified: true; emailMasked: string }> {
  const { pepper, now } = deps;
  const emailHash = await emailHashOf(pepper, input.email);
  const emailMasked = maskEmail(input.email);
  const outcome = await deps.challenges.attempt(
    uid,
    { emailHash, codeHash: await otpHashOf(pepper, uid, input.code), emailMasked },
    now,
  );
  if (outcome !== 'verified') throw refuseSubscription(outcome);
  logger.info('voucher email verified', { uid });
  return { verified: true, emailMasked };
}
