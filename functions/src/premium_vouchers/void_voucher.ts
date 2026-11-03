import { type Firestore, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import type { VoidVoucherInput } from './schemas';
import { storedVoucher, voucherRef } from './voucher_documents';

export type VoidOutcome = 'voided' | 'alreadyVoid' | 'alreadyClaimed' | 'notFound';

export async function voidVoucher(
  store: Firestore,
  input: VoidVoucherInput,
  now: Date,
): Promise<VoidOutcome> {
  return store.runTransaction(async (transaction) => {
    const ref = voucherRef(store, input.voucherId);
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) return 'notFound';
    const parsed = storedVoucher.safeParse(snapshot.data());
    if (!parsed.success) {
      logger.error('premium voucher unreadable', { voucherId: input.voucherId });
      throw new Error('premium voucher unreadable');
    }
    if (parsed.data.kind !== 'frame') return 'notFound';
    if (parsed.data.status === 'void') return 'alreadyVoid';
    if (parsed.data.status === 'claimed') return 'alreadyClaimed';
    transaction.update(ref, {
      status: 'void',
      voidedAt: Timestamp.fromDate(now),
      voidReason: input.reason,
    });
    return 'voided';
  });
}
