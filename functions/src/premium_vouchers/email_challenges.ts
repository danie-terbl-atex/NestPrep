import { type Firestore, Timestamp, type Transaction } from 'firebase-admin/firestore';

import { type RateLimitRule, readRateLimitIn } from '../shared/rate_limit';
import { sameHash } from './premium_hashes';
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

export const EMAIL_CODE_TRIES_PER_ADDRESS: RateLimitRule = {
  name: 'voucherEmailCode:tries:email',
  limit: 10,
  windowSeconds: 60 * 60,
};

export type AttemptOutcome =
  'verified' | 'emailCodeWrong' | 'emailCodeExpired' | 'emailCodeTooManyTries';

export interface Attempt {
  readonly emailHash: string;
  readonly codeHash: string;
  readonly emailMasked: string;
}

export interface ChallengeStore {
  sentThisHour(uid: string, now: Date): Promise<number>;
  record(uid: string, sent: { emailHash: string; codeHash: string }, now: Date): Promise<void>;
  attempt(uid: string, attempt: Attempt, now: Date): Promise<AttemptOutcome>;
}

export function sentInWindow(challenge: StoredChallenge | null, now: Date): number {
  if (challenge === null) return 0;
  const inWindow = now.getTime() - challenge.windowStart.getTime() < EMAIL_CODE_WINDOW_MS;
  return inWindow ? challenge.sentCount : 0;
}

export function judgeAttempt(
  challenge: StoredChallenge | null,
  attempt: Pick<Attempt, 'emailHash' | 'codeHash'>,
  now: Date,
): AttemptOutcome {
  if (challenge === null) return 'emailCodeExpired';
  if (challenge.tries >= EMAIL_CODE_TRIES) return 'emailCodeTooManyTries';
  if (now.getTime() >= challenge.expiresAt.getTime()) return 'emailCodeExpired';
  const codeMatches = sameHash(challenge.codeHash, attempt.codeHash);
  const emailMatches = sameHash(challenge.emailHash, attempt.emailHash);
  return codeMatches && emailMatches ? 'verified' : 'emailCodeWrong';
}

export interface AttemptDecision {
  readonly outcome: AttemptOutcome;
  readonly addsChallengeTry: boolean;
  readonly spendsAddressTry: boolean;
}

export function decideAttempt(
  challenge: StoredChallenge | null,
  addressHasTries: boolean,
  attempt: Pick<Attempt, 'emailHash' | 'codeHash'>,
  now: Date,
): AttemptDecision {
  if (!addressHasTries) {
    return { outcome: 'emailCodeTooManyTries', addsChallengeTry: false, spendsAddressTry: false };
  }
  const outcome = judgeAttempt(challenge, attempt, now);
  const wrong = outcome === 'emailCodeWrong' && challenge !== null;
  return {
    outcome,
    addsChallengeTry: wrong,
    spendsAddressTry: wrong && sameHash(challenge.emailHash, attempt.emailHash),
  };
}

export function firestoreChallenges(store: Firestore): ChallengeStore {
  return {
    async sentThisHour(uid: string, now: Date): Promise<number> {
      return sentInWindow(await readChallenge(store, uid), now);
    },
    async record(
      uid: string,
      sent: { emailHash: string; codeHash: string },
      now: Date,
    ): Promise<void> {
      await store.runTransaction(async (transaction) => {
        const previous = await readChallenge(store, uid, transaction);
        const inWindow = sentInWindow(previous, now) > 0;
        transaction.set(emailChallengeRef(store, uid), {
          emailHash: sent.emailHash,
          codeHash: sent.codeHash,
          expiresAt: Timestamp.fromMillis(now.getTime() + EMAIL_CODE_LIFETIME_MS),
          tries: 0,
          sentCount: (inWindow ? (previous?.sentCount ?? 0) : 0) + 1,
          windowStart: Timestamp.fromDate(
            inWindow && previous !== null ? previous.windowStart : now,
          ),
        });
      });
    },
    async attempt(uid: string, attempt: Attempt, now: Date): Promise<AttemptOutcome> {
      return store.runTransaction(async (transaction) => {
        const challenge = await readChallenge(store, uid, transaction);
        const budget = await readRateLimitIn(
          transaction,
          store,
          EMAIL_CODE_TRIES_PER_ADDRESS,
          attempt.emailHash,
          now,
        );
        const { outcome, addsChallengeTry, spendsAddressTry } = decideAttempt(
          challenge,
          budget.allowed,
          attempt,
          now,
        );
        if (addsChallengeTry && challenge !== null) {
          transaction.update(emailChallengeRef(store, uid), { tries: challenge.tries + 1 });
        }
        if (spendsAddressTry) budget.stage();
        if (outcome === 'verified') {
          transaction.set(
            verifiedEmailsRef(store, uid),
            {
              emails: {
                [attempt.emailHash]: {
                  emailMasked: attempt.emailMasked,
                  verifiedAt: Timestamp.fromDate(now),
                  via: 'code',
                },
              },
            },
            { merge: true },
          );
          transaction.delete(emailChallengeRef(store, uid));
        }
        return outcome;
      });
    },
  };
}

async function readChallenge(
  store: Firestore,
  uid: string,
  transaction?: Transaction,
): Promise<StoredChallenge | null> {
  const ref = emailChallengeRef(store, uid);
  const snapshot = await (transaction === undefined ? ref.get() : transaction.get(ref));
  if (!snapshot.exists) return null;
  const parsed = storedChallenge.safeParse(snapshot.data());
  return parsed.success ? parsed.data : null;
}
