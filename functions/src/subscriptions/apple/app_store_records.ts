import { z } from 'zod';

import type { PurchaseState, PurchaseStatus } from '../purchase_state';

/**
 * The App Store's signed records, once their signature has been checked:
 * a transaction, its renewal info, and a Server Notification v2. Only the
 * fields NestPrep reads are declared; the rest pass through unread (`ENG-09`).
 * Dates are milliseconds since the epoch, as Apple sends them.
 */
const millis = z.number().int().nonnegative();

export const appStoreTransaction = z.object({
  transactionId: z.string().min(1),
  originalTransactionId: z.string().min(1),
  bundleId: z.string().min(1),
  productId: z.string().min(1),
  purchaseDate: millis,
  expiresDate: millis.optional(),
  revocationDate: millis.optional(),
  environment: z.string(),
});
export type AppStoreTransaction = z.infer<typeof appStoreTransaction>;

export const appStoreRenewal = z.object({
  originalTransactionId: z.string().min(1),
  autoRenewStatus: z.number().int().optional(),
  gracePeriodExpiresDate: millis.optional(),
  isInBillingRetryPeriod: z.boolean().optional(),
});
export type AppStoreRenewal = z.infer<typeof appStoreRenewal>;

export const appStoreNotification = z.object({
  notificationType: z.string().min(1),
  subtype: z.string().optional(),
  notificationUUID: z.string().min(1),
  data: z
    .object({
      appAppleId: z.number().int().optional(),
      bundleId: z.string().min(1),
      environment: z.string(),
      signedTransactionInfo: z.string().optional(),
      signedRenewalInfo: z.string().optional(),
      status: z.number().int().optional(),
    })
    .optional(),
});
export type AppStoreNotification = z.infer<typeof appStoreNotification>;

/**
 * Apple's subscription status numbers (the App Store Server API's `status`,
 * repeated in a v2 notification's `data.status`).
 */
const STATUS_BY_NUMBER: Readonly<Record<number, PurchaseStatus>> = {
  1: 'active',
  2: 'expired',
  3: 'onHold',
  4: 'inGracePeriod',
  5: 'revoked',
};

export interface AppleRecords {
  readonly transaction: AppStoreTransaction;
  readonly renewal: AppStoreRenewal | null;
  /** Apple's own status number, when the source carried one. */
  readonly status: number | null;
}

/**
 * One subscription as NestPrep understands it, from what Apple signed. With a
 * status number Apple has already decided; without one — a transaction the
 * phone handed over, and no API key to ask with — the dates decide.
 */
export function appleState(records: AppleRecords, now: Date): PurchaseState {
  const { transaction, renewal } = records;
  const willRenew = renewal?.autoRenewStatus === undefined ? null : renewal.autoRenewStatus === 1;
  const expires = dateOf(transaction.expiresDate);
  const grace = dateOf(renewal?.gracePeriodExpiresDate);
  const base = {
    productId: transaction.productId,
    isTest: transaction.environment !== 'Production',
    willRenew,
  };
  if (transaction.revocationDate !== undefined) {
    return { ...base, status: 'revoked', accessUntil: null, willRenew: false };
  }
  const status =
    records.status === null
      ? statusFromDates(expires, grace, renewal, now)
      : STATUS_BY_NUMBER[records.status];
  switch (status) {
    case 'active':
    case 'cancelled':
      return {
        ...base,
        status: willRenew === false ? 'cancelled' : 'active',
        accessUntil: expires,
      };
    case 'inGracePeriod':
      return { ...base, status, accessUntil: grace ?? expires };
    case undefined:
      return { ...base, status: 'expired', accessUntil: expires };
    default:
      return { ...base, status, accessUntil: expires };
  }
}

function statusFromDates(
  expires: Date | null,
  grace: Date | null,
  renewal: AppStoreRenewal | null,
  now: Date,
): PurchaseStatus {
  if (expires !== null && expires.getTime() > now.getTime()) return 'active';
  if (grace !== null && grace.getTime() > now.getTime()) return 'inGracePeriod';
  if (renewal?.isInBillingRetryPeriod === true) return 'onHold';
  return 'expired';
}

function dateOf(value: number | undefined): Date | null {
  return value === undefined ? null : new Date(value);
}
