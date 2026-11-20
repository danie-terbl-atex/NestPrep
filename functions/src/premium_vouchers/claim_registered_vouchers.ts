import { logger } from 'firebase-functions/v2';
import { HttpsError } from 'firebase-functions/v2/https';

import { userRef } from '../household/documents';
import { registeredUserDirectory } from './caller_emails';
import { claimVoucher } from './claim_voucher';
import type { VoucherDeps } from './voucher_deps';
import { liveVoucherDeps } from './voucher_runtime';
import { vouchersWaitingFor } from './vouchers_for_me';

export async function claimRegisteredVouchers(
  deps: VoucherDeps,
  uid: string,
  householdId: string,
): Promise<string[]> {
  const account = await userRef(deps.store, uid).get();
  const householdIds: unknown = account.get('householdIds');
  if (!Array.isArray(householdIds) || householdIds.length !== 1) return [];
  if (householdIds[0] !== householdId) return [];

  const { vouchers } = await vouchersWaitingFor(deps, uid);
  const claimed: string[] = [];
  for (const voucher of vouchers) {
    if (voucher.kind !== 'frame') continue;
    await claimVoucher(deps, uid, { voucherId: voucher.voucherId, householdId });
    claimed.push(voucher.voucherId);
  }
  return claimed;
}

export async function claimRegisteredVouchersAfter(
  uid: string,
  householdId: string,
): Promise<void> {
  try {
    const deps = { ...liveVoucherDeps(), users: registeredUserDirectory };
    const claimed = await claimRegisteredVouchers(deps, uid, householdId);
    if (claimed.length > 0) {
      logger.info('frame premium added on opening the app', { householdId, vouchers: claimed });
    }
  } catch (error) {
    if (error instanceof HttpsError) {
      logger.info('frame premium left waiting', { householdId, reason: error.message });
      return;
    }
    logger.error('frame premium not added; asked again on the next open', {
      householdId,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}
