import { type Firestore, Timestamp } from 'firebase-admin/firestore';

import { emailHashOf, maskEmail, normEmail } from './premium_hashes';
import type { IssueVouchersInput } from './schemas';
import { voucherRef } from './voucher_documents';

export type IssueOutcome = 'issued' | 'exists';

export interface IssueResult {
  readonly voucherId: string;
  readonly outcome: IssueOutcome;
}

export class UnusableEmail extends Error {
  constructor() {
    super('a voucher email is not an email address');
    this.name = 'UnusableEmail';
  }
}

export async function issueVouchers(
  store: Firestore,
  pepper: string,
  input: IssueVouchersInput,
  now: Date,
): Promise<IssueResult[]> {
  const prepared = await Promise.all(
    input.vouchers.map(async (voucher) => {
      const email = normEmail(voucher.email);
      if (email === null) throw new UnusableEmail();
      return {
        voucher,
        emailHash: await emailHashOf(pepper, email),
        emailMasked: maskEmail(email),
      };
    }),
  );
  return store.runTransaction(async (transaction) => {
    const refs = prepared.map(({ voucher }) => voucherRef(store, voucher.voucherId));
    const existing = await transaction.getAll(...refs);
    return prepared.map(({ voucher, emailHash, emailMasked }, index): IssueResult => {
      if (existing[index]?.exists === true)
        return { voucherId: voucher.voucherId, outcome: 'exists' };
      transaction.create(voucherRef(store, voucher.voucherId), {
        kind: 'frame',
        orderId: voucher.orderId,
        sku: voucher.sku,
        codeId: null,
        days: voucher.days,
        emailHash,
        emailMasked,
        claimTokenHash: voucher.claimTokenHash,
        status: 'waiting',
        isTest: voucher.isTest,
        attribution: voucher.attribution,
        householdId: null,
        claimedByUid: null,
        claimedAt: null,
        grantId: null,
        reassignedAt: null,
        voidedAt: null,
        voidReason: null,
        claimBy: null,
        createdAt: Timestamp.fromDate(now),
      });
      return { voucherId: voucher.voucherId, outcome: 'issued' };
    });
  });
}
