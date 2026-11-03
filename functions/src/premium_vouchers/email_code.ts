import { randomInt } from 'node:crypto';

import { type Firestore, Timestamp, type Transaction } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import type { RateLimitRule } from '../shared/rate_limit';
import { type SubscriptionRefusal, refuseSubscription } from '../subscriptions/errors';
import { type UserDirectory, callerEmailHashes } from './caller_emails';
import { type EmailSender, EmailNotSent, emailCodeMessage } from './email_sender';
import { emailHashOf, includesHash, maskEmail, otpHashOf, sameHash } from './premium_hashes';
import {
  type StoredChallenge,
  emailChallengeRef,
  storedChallenge,
  verifiedEmailsRef,
} from './voucher_documents';

const MINUTE_MS = 60 * 1000;

export const EMAIL_CODE_LIFETIME_MS = 10 * MINUTE_MS;
export const EMAIL_CODES_PER_HOUR = 3;
export const EMAIL_CODE_WINDOW_MS = 60 * MINUTE_MS;
export const EMAIL_CODE_TRIES = 5;

export const EMAIL_CODES_PER_ADDRESS: RateLimitRule = {
  name: 'voucherEmailCode:email',
  limit: 5,
  windowSeconds: 60 * 60,
};

export interface EmailCodeDeps {
  readonly store: Firestore;
  readonly users: UserDirectory;
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
  const { store, pepper, now } = deps;
  const emailHash = await emailHashOf(pepper, email);
  if (includesHash(await callerEmailHashes(deps, uid), emailHash)) {
    throw refuseSubscription('emailAlreadyVerified');
  }
  const code = deps.newCode();
  const codeHash = await otpHashOf(pepper, uid, code);
  const sendable = await store.runTransaction(async (transaction) => {
    const ref = emailChallengeRef(store, uid);
    const previous = await readChallenge(transaction, store, uid);
    const inWindow =
      previous !== null && now.getTime() - previous.windowStart.getTime() < EMAIL_CODE_WINDOW_MS;
    const sentCount = inWindow ? previous.sentCount : 0;
    if (sentCount >= EMAIL_CODES_PER_HOUR) return false;
    transaction.set(ref, {
      emailHash,
      codeHash,
      expiresAt: Timestamp.fromMillis(now.getTime() + EMAIL_CODE_LIFETIME_MS),
      tries: 0,
      sentCount: sentCount + 1,
      windowStart: inWindow ? Timestamp.fromDate(previous.windowStart) : Timestamp.fromDate(now),
    });
    return true;
  });
  if (!sendable || !(await deps.consume(EMAIL_CODES_PER_ADDRESS, emailHash))) {
    throw refuseSubscription('tooManyCodes');
  }
  try {
    await deps.sender.send(emailCodeMessage(email, code));
  } catch (error) {
    logger.error('voucher email code not sent', {
      why: error instanceof EmailNotSent ? error.why : 'unexpected',
    });
    throw new HttpsError('unavailable', 'The email could not be sent.');
  }
  logger.info('voucher email code sent', { uid });
  return { sent: true, emailMasked: maskEmail(email) };
}

type VerifyOutcome =
  | 'verified'
  | Extract<SubscriptionRefusal, 'emailCodeWrong' | 'emailCodeExpired' | 'emailCodeTooManyTries'>;

export async function verifyEmailCode(
  deps: Pick<EmailCodeDeps, 'store' | 'pepper' | 'now'>,
  uid: string,
  input: { readonly email: string; readonly code: string },
): Promise<{ verified: true; emailMasked: string }> {
  const { store, pepper, now } = deps;
  const emailHash = await emailHashOf(pepper, input.email);
  const triedHash = await otpHashOf(pepper, uid, input.code);
  const emailMasked = maskEmail(input.email);
  const outcome = await store.runTransaction(async (transaction): Promise<VerifyOutcome> => {
    const challenge = await readChallenge(transaction, store, uid);
    if (challenge === null) return 'emailCodeExpired';
    if (challenge.tries >= EMAIL_CODE_TRIES) return 'emailCodeTooManyTries';
    if (now.getTime() >= challenge.expiresAt.getTime()) return 'emailCodeExpired';
    const codeMatches = sameHash(challenge.codeHash, triedHash);
    const emailMatches = sameHash(challenge.emailHash, emailHash);
    if (!codeMatches || !emailMatches) {
      transaction.update(emailChallengeRef(store, uid), { tries: challenge.tries + 1 });
      return 'emailCodeWrong';
    }
    transaction.set(
      verifiedEmailsRef(store, uid),
      {
        emails: { [emailHash]: { emailMasked, verifiedAt: Timestamp.fromDate(now), via: 'code' } },
      },
      { merge: true },
    );
    transaction.delete(emailChallengeRef(store, uid));
    return 'verified';
  });
  if (outcome !== 'verified') throw refuseSubscription(outcome);
  logger.info('voucher email verified', { uid });
  return { verified: true, emailMasked };
}

async function readChallenge(
  transaction: Transaction,
  store: Firestore,
  uid: string,
): Promise<StoredChallenge | null> {
  const snapshot = await transaction.get(emailChallengeRef(store, uid));
  if (!snapshot.exists) return null;
  const parsed = storedChallenge.safeParse(snapshot.data());
  return parsed.success ? parsed.data : null;
}
