import { type Firestore, Timestamp, type Transaction } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { type RateLimitRule, type StagedRateLimit, readRateLimitIn } from '../shared/rate_limit';
import { claimByOf, redeemRefusalOf, type RedeemRefusal } from './code_policy';
import {
  PREMIUM_WEB_PER_EMAIL,
  REDEEMED_PER_ADDRESS,
  REDEEM_MISSES_OVERALL,
  REDEEM_MISSES_PER_ADDRESS,
  REDEEM_PER_ADDRESS,
} from './premium_web_limits';
import {
  type StoredCode,
  PREMIUM_VOUCHERS,
  codeRedemptionRef,
  codeRef,
  storedCode,
  storedVoucher,
  voucherRef,
} from './voucher_documents';

export interface Redeemer {
  readonly codeHash: string;
  readonly emailHash: string;
  readonly emailMasked: string;
  readonly address: string;
}

export const REDEEM_REFUSALS = [
  'codeUnknown',
  'codePaused',
  'codeNotStarted',
  'codeExpired',
  'codeUsedUp',
] as const;

export type RedeemAnswer =
  | { readonly result: 'redeemed'; readonly days: number; readonly label: string }
  | { readonly error: 'codeUnknown' | 'tooManyTries' }
  | RedeemRefusal;

export interface RedeemOutcome {
  readonly answer: RedeemAnswer;
  readonly missCeilingTripped: boolean;
}

const TOO_MANY = { error: 'tooManyTries' } as const;

export async function redeemCode(
  store: Firestore,
  redeemer: Redeemer,
  now: Date,
): Promise<RedeemOutcome> {
  return store.runTransaction(async (transaction): Promise<RedeemOutcome> => {
    const limit = (rule: RateLimitRule, subject: string): Promise<StagedRateLimit> =>
      readRateLimitIn(transaction, store, rule, subject, now);
    const answered = (answer: RedeemAnswer): RedeemOutcome => ({
      answer,
      missCeilingTripped: false,
    });

    const request = await limit(REDEEM_PER_ADDRESS, redeemer.address);
    const misses = await limit(REDEEM_MISSES_PER_ADDRESS, redeemer.address);
    if (!request.allowed || !misses.allowed) return answered(TOO_MANY);

    const code = await readCode(transaction, store, redeemer.codeHash);
    if (code === null || code.status === 'archived') {
      const overall = await limit(REDEEM_MISSES_OVERALL, 'all');
      request.stage();
      misses.stage();
      if (!overall.allowed) return { answer: TOO_MANY, missCeilingTripped: true };
      overall.stage();
      return answered({ error: 'codeUnknown' });
    }

    const redemption = await transaction.get(
      codeRedemptionRef(store, redeemer.codeHash, redeemer.emailHash),
    );
    if (redemption.exists) {
      const voucherId: unknown = redemption.get('voucherId');
      const earlier =
        typeof voucherId === 'string'
          ? storedVoucher.safeParse((await transaction.get(voucherRef(store, voucherId))).data())
          : null;
      request.stage();
      return answered({
        result: 'redeemed',
        days: earlier?.success === true ? earlier.data.days : code.days,
        label: code.label,
      });
    }

    const refusal = redeemRefusalOf(code, now);
    if (refusal !== null) {
      const perEmail = await limit(PREMIUM_WEB_PER_EMAIL, redeemer.emailHash);
      request.stage();
      if (!perEmail.allowed) return answered(TOO_MANY);
      perEmail.stage();
      return answered(refusal);
    }

    const redeemed = await limit(REDEEMED_PER_ADDRESS, redeemer.address);
    request.stage();
    if (!redeemed.allowed) return answered(TOO_MANY);
    redeemed.stage();
    const voucher = store.collection(PREMIUM_VOUCHERS).doc();
    const at = Timestamp.fromDate(now);
    const claimBy = claimByOf(code);
    transaction.create(voucher, {
      kind: 'code',
      orderId: null,
      sku: null,
      codeId: redeemer.codeHash,
      days: code.days,
      emailHash: redeemer.emailHash,
      emailMasked: redeemer.emailMasked,
      claimTokenHash: null,
      status: 'waiting',
      isTest: code.isTest,
      attribution:
        code.attribution === null
          ? null
          : { code: code.display ?? code.label, partnerId: code.attribution.partnerId },
      householdId: null,
      claimedByUid: null,
      claimedAt: null,
      grantId: null,
      reassignedAt: null,
      reassignCount: 0,
      voidedAt: null,
      voidReason: null,
      claimBy: claimBy === null ? null : Timestamp.fromDate(claimBy),
      createdAt: at,
    });
    transaction.create(codeRedemptionRef(store, redeemer.codeHash, redeemer.emailHash), {
      voucherId: voucher.id,
      at,
    });
    return answered({ result: 'redeemed', days: code.days, label: code.label });
  });
}

async function readCode(
  transaction: Transaction,
  store: Firestore,
  codeHash: string,
): Promise<StoredCode | null> {
  const snapshot = await transaction.get(codeRef(store, codeHash));
  if (!snapshot.exists) return null;
  const parsed = storedCode.safeParse(snapshot.data());
  if (!parsed.success) {
    logger.error('premium code unreadable', { codeHash });
    return null;
  }
  return parsed.data;
}
