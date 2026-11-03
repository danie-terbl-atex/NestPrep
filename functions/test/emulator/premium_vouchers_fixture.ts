import { randomBytes } from 'node:crypto';

import { Timestamp } from 'firebase-admin/firestore';

import { issueVouchers } from '../../src/premium_vouchers/issue_vouchers';
import { EMULATOR_PEPPER } from '../../src/premium_vouchers/premium_config';
import {
  codeHashOf,
  emailHashOf,
  normCode,
  tokenHashOf,
} from '../../src/premium_vouchers/premium_hashes';
import type { StoredCode } from '../../src/premium_vouchers/voucher_documents';
import { HOSTING_REGION } from '../../src/shared/region';
import { DAY_MS } from './referrals_fixture';
import { adminDb, callAs, httpFunctionUrl, type TestUser } from './emulator_harness';

let nextOrder = 0;

export interface FrameVoucher {
  readonly voucherId: string;
  readonly token: string;
}

export async function aFrameVoucher(
  email: string,
  options: { readonly isTest?: boolean; readonly days?: number; readonly partner?: boolean } = {},
): Promise<FrameVoucher> {
  nextOrder += 1;
  const orderId = `ord_${Date.now().toString(36)}_${String(nextOrder)}`;
  const voucherId = `${orderId}_1`;
  const token = randomBytes(32).toString('base64url');
  await issueVouchers(
    adminDb(),
    EMULATOR_PEPPER,
    {
      vouchers: [
        {
          voucherId,
          orderId,
          sku: 'frame-15',
          days: options.days ?? 93,
          email,
          claimTokenHash: tokenHashOf(token),
          isTest: options.isTest ?? false,
          attribution:
            options.partner === true ? { code: 'THANDI10', partnerId: 'p-thandi' } : null,
        },
      ],
    },
    new Date(),
  );
  return { voucherId, token };
}

export type CodeSetup = Partial<Omit<StoredCode, 'validFrom' | 'validUntil'>> & {
  readonly validFrom?: Date;
  readonly validUntil?: Date | null;
};

export async function aCode(plain: string, setup: CodeSetup = {}): Promise<string> {
  const codeHash = await codeHashOf(EMULATOR_PEPPER, normCode(plain) ?? '');
  const validUntil =
    setup.validUntil === undefined ? new Date(Date.now() + 30 * DAY_MS) : setup.validUntil;
  await adminDb()
    .doc(`premiumCodes/${codeHash}`)
    .set({
      shape: 'shared',
      display: plain,
      label: 'Launch readers',
      batchId: null,
      days: 30,
      maxClaims: null,
      claimCount: 0,
      status: 'active',
      eligibility: 'any',
      attribution: null,
      isTest: false,
      createdAt: Timestamp.now(),
      createdBy: 'tests',
      ...setup,
      validFrom: Timestamp.fromDate(setup.validFrom ?? new Date(Date.now() - DAY_MS)),
      validUntil: validUntil === null ? null : Timestamp.fromDate(validUntil),
    });
  return codeHash;
}

export interface WebAnswer {
  readonly status: number;
  readonly body: Record<string, unknown>;
  readonly cacheControl: string | null;
}

export async function onTheWeb(route: string, body: unknown): Promise<WebAnswer> {
  const response = await fetch(`${httpFunctionUrl('premiumWeb', HOSTING_REGION)}${route}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  return {
    status: response.status,
    body: (await response.json()) as Record<string, unknown>,
    cacheControl: response.headers.get('cache-control'),
  };
}

export async function redeemOnTheWeb(code: string, email: string): Promise<WebAnswer> {
  return onTheWeb('/redeem', { code, email });
}

export async function codeVoucherOf(codeHash: string, email: string): Promise<string> {
  const redemption = await adminDb()
    .doc(`premiumCodes/${codeHash}/redemptions/${await emailHashOf(EMULATOR_PEPPER, email)}`)
    .get();
  const voucherId: unknown = redemption.get('voucherId');
  if (typeof voucherId !== 'string') throw new Error('no voucher was redeemed for that email');
  return voucherId;
}

export interface ClaimAnswer {
  readonly grantId: string;
  readonly days: number;
  readonly startsAt: string | null;
  readonly queued: boolean;
}

export async function claim(
  user: TestUser,
  voucherId: string,
  householdId: string,
): Promise<ClaimAnswer> {
  return callAs<ClaimAnswer>(user, 'claimPremiumVoucher', { voucherId, householdId });
}

export interface ListedVoucher {
  readonly voucherId: string;
  readonly kind: string;
  readonly days: number;
  readonly sku: string | null;
  readonly emailMasked: string;
  readonly isTest: boolean;
}

export async function vouchersFor(user: TestUser): Promise<ListedVoucher[]> {
  const { vouchers } = await callAs<{ vouchers: ListedVoucher[] }>(
    user,
    'premiumVouchersForMe',
    {},
  );
  return vouchers;
}

export async function aGrantIn(
  householdId: string,
  grantId: string,
  grant: { source: string; days: number; grantedDaysAgo: number; started: boolean },
): Promise<void> {
  const at = Timestamp.fromMillis(Date.now() - grant.grantedDaysAgo * DAY_MS);
  await adminDb()
    .doc(`households/${householdId}/premiumGrants/${grantId}`)
    .set({
      source: grant.source,
      days: grant.days,
      grantedAt: at,
      startsAt: grant.started ? at : null,
    });
}

export async function aPaidSubscription(
  user: TestUser,
  householdId: string,
  paidUntil: Date,
): Promise<void> {
  await adminDb()
    .doc(`storePurchases/sub-${householdId}`)
    .set({
      store: 'playStore',
      storeRef: `token-${householdId}`,
      productId: 'nestprep_premium_monthly',
      plan: 'monthly',
      status: 'cancelled',
      accessUntil: Timestamp.fromDate(paidUntil),
      willRenew: false,
      isTest: true,
      householdId,
      linkedByUid: user.uid,
      linkedByMemberId: 'm-admin',
      supersededBy: null,
    });
  await adminDb()
    .doc(`households/${householdId}/entitlement/current`)
    .set({ premiumUntil: Timestamp.fromDate(paidUntil), status: 'cancelled' });
}
