import {
  type Firestore,
  type Query,
  type QuerySnapshot,
  Timestamp,
} from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import {
  type StoredVoucher,
  PREMIUM_VOUCHERS,
  VOUCHER_STATUSES,
  storedVoucher,
} from './voucher_documents';

export const GIFT_TOKEN = /^[A-Za-z0-9_-]{43}$/;

export type GiftLookup =
  | {
      readonly status: (typeof VOUCHER_STATUSES)[number];
      readonly days: number;
      readonly sku: string | null;
      readonly emailMasked: string;
    }
  | { readonly error: 'voucherNotFound' };

export type GiftReassign =
  | { readonly ok: true; readonly emailMasked: string }
  | { readonly error: 'voucherNotFound' | 'voucherClaimed' | 'voucherVoid' };

function byTokenHash(store: Firestore, claimTokenHash: string): Query {
  return store.collection(PREMIUM_VOUCHERS).where('claimTokenHash', '==', claimTokenHash).limit(1);
}

function frameVoucherOf(snapshot: QuerySnapshot): { id: string; voucher: StoredVoucher } | null {
  const doc = snapshot.docs[0];
  if (doc === undefined) return null;
  const parsed = storedVoucher.safeParse(doc.data());
  if (!parsed.success) {
    logger.error('premium voucher unreadable', { voucherId: doc.id });
    return null;
  }
  return parsed.data.kind === 'frame' ? { id: doc.id, voucher: parsed.data } : null;
}

export async function lookUpGift(store: Firestore, claimTokenHash: string): Promise<GiftLookup> {
  const found = frameVoucherOf(await byTokenHash(store, claimTokenHash).get());
  if (found === null) return { error: 'voucherNotFound' };
  const { voucher } = found;
  return {
    status: voucher.status,
    days: voucher.days,
    sku: voucher.sku,
    emailMasked: voucher.emailMasked,
  };
}

export async function reassignGift(
  store: Firestore,
  change: {
    readonly claimTokenHash: string;
    readonly emailHash: string;
    readonly emailMasked: string;
  },
  now: Date,
): Promise<GiftReassign> {
  return store.runTransaction(async (transaction): Promise<GiftReassign> => {
    const found = frameVoucherOf(await transaction.get(byTokenHash(store, change.claimTokenHash)));
    if (found === null) return { error: 'voucherNotFound' };
    if (found.voucher.status === 'claimed') return { error: 'voucherClaimed' };
    if (found.voucher.status === 'void') return { error: 'voucherVoid' };
    transaction.update(store.collection(PREMIUM_VOUCHERS).doc(found.id), {
      emailHash: change.emailHash,
      emailMasked: change.emailMasked,
      reassignedAt: Timestamp.fromDate(now),
    });
    return { ok: true, emailMasked: change.emailMasked };
  });
}
