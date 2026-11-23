import type { Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { HttpsError } from 'firebase-functions/v2/https';

import { userRef } from '../household/documents';
import { auth } from '../shared/auth';
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
  if ((await onlyHouseholdOf(deps.store, uid)) !== householdId) return [];

  const { vouchers } = await vouchersWaitingFor(deps, uid);
  const claimed: string[] = [];
  for (const voucher of vouchers) {
    if (voucher.kind !== 'frame') continue;
    await claimVoucher(deps, uid, { voucherId: voucher.voucherId, householdId });
    claimed.push(voucher.voucherId);
  }
  return claimed;
}

async function onlyHouseholdOf(store: Firestore, uid: string): Promise<string | null> {
  const account = await userRef(store, uid).get();
  const householdIds: unknown = account.get('householdIds');
  if (!Array.isArray(householdIds) || householdIds.length !== 1) return null;
  const only: unknown = householdIds[0];
  return typeof only === 'string' ? only : null;
}

export type AccountLookup = (email: string) => Promise<string | null>;

export const registeredAccountOf: AccountLookup = async (email) => {
  try {
    return (await auth().getUserByEmail(email)).uid;
  } catch (error) {
    if ((error as { code?: unknown }).code === 'auth/user-not-found') return null;
    throw error;
  }
};

export async function claimIssuedVouchers(
  deps: VoucherDeps,
  accountOf: AccountLookup,
  email: string,
): Promise<{ householdId: string; claimed: string[] } | null> {
  const uid = await accountOf(email);
  if (uid === null) return null;
  const householdId = await onlyHouseholdOf(deps.store, uid);
  if (householdId === null) return null;
  return { householdId, claimed: await claimRegisteredVouchers(deps, uid, householdId) };
}

// A voucher issued after the day's app open would wait a day for the next one
// (subscriptions ADR-0013), so the store's push claims it too.
export async function claimIssuedVouchersAfter(emails: readonly string[]): Promise<void> {
  const deps = { ...liveVoucherDeps(), users: registeredUserDirectory };
  for (const email of new Set(emails)) {
    try {
      const result = await claimIssuedVouchers(deps, registeredAccountOf, email);
      if (result !== null && result.claimed.length > 0) {
        logger.info('frame premium added when the store issued it', {
          householdId: result.householdId,
          vouchers: result.claimed,
        });
      }
    } catch (error) {
      if (error instanceof HttpsError) {
        logger.info('issued frame premium left waiting', { reason: error.message });
        continue;
      }
      logger.error('issued frame premium not added; asked again on the next open', {
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }
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
