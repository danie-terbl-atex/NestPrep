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
export const REASSIGNS_PER_GIFT = 5;

export const GIFT_LOOKUP_REFUSALS = ['voucherNotFound'] as const;
export const GIFT_REASSIGN_REFUSALS = [
  'voucherNotFound',
  'voucherClaimed',
  'voucherVoid',
  'voucherReassignLimit',
] as const;

export type GiftLookup =
  | {
      readonly status: (typeof VOUCHER_STATUSES)[number];
      readonly days: number;
      readonly sku: string | null;
      readonly emailMasked: string;
    }
  | { readonly error: (typeof GIFT_LOOKUP_REFUSALS)[number] };

export type GiftReassign =
  | { readonly ok: true; readonly emailMasked: string }
  | { readonly error: (typeof GIFT_REASSIGN_REFUSALS)[number] };

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
    if (found.voucher.reassignCount >= REASSIGNS_PER_GIFT) {
      return { error: 'voucherReassignLimit' };
    }
    transaction.update(store.collection(PREMIUM_VOUCHERS).doc(found.id), {
      emailHash: change.emailHash,
      emailMasked: change.emailMasked,
      reassignedAt: Timestamp.fromDate(now),
      reassignCount: found.voucher.reassignCount + 1,
    });
    return { ok: true, emailMasked: change.emailMasked };
  });
}
