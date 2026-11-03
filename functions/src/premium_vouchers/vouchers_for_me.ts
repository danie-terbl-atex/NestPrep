import { logger } from 'firebase-functions/v2';

import { callerEmailHashes } from './caller_emails';
import { isPastClaimBy } from './code_policy';
import type { VoucherDeps } from './voucher_deps';
import { type VoucherKind, PREMIUM_VOUCHERS, storedVoucher } from './voucher_documents';

export interface WaitingVoucher {
  readonly voucherId: string;
  readonly kind: VoucherKind;
  readonly days: number;
  readonly sku: string | null;
  readonly emailMasked: string;
  readonly isTest: boolean;
}

const HASHES_PER_QUERY = 30;
const VOUCHERS_PER_QUERY = 50;

export async function vouchersWaitingFor(
  deps: VoucherDeps,
  uid: string,
): Promise<{ vouchers: WaitingVoucher[] }> {
  const hashes = await callerEmailHashes(deps, uid);
  const isTester = deps.testers.includes(uid);
  const vouchers: WaitingVoucher[] = [];
  for (let start = 0; start < hashes.length; start += HASHES_PER_QUERY) {
    const found = await deps.store
      .collection(PREMIUM_VOUCHERS)
      .where('emailHash', 'in', hashes.slice(start, start + HASHES_PER_QUERY))
      .where('status', '==', 'waiting')
      .limit(VOUCHERS_PER_QUERY)
      .get();
    for (const doc of found.docs) {
      const parsed = storedVoucher.safeParse(doc.data());
      if (!parsed.success) {
        logger.error('premium voucher unreadable', { voucherId: doc.id });
        continue;
      }
      const voucher = parsed.data;
      if (voucher.isTest && !isTester) continue;
      if (voucher.kind === 'code' && isPastClaimBy(voucher, deps.now)) continue;
      vouchers.push({
        voucherId: doc.id,
        kind: voucher.kind,
        days: voucher.days,
        sku: voucher.sku,
        emailMasked: voucher.emailMasked,
        isTest: voucher.isTest,
      });
    }
  }
  vouchers.sort((a, b) => a.voucherId.localeCompare(b.voucherId));
  return { vouchers };
}
