import { z } from 'zod';

import { MAX_EMAIL_LENGTH } from './premium_hashes';
import { VOID_REASONS } from './voucher_documents';

const id = z.string().trim().min(1).max(64);
const voucherId = z
  .string()
  .min(1)
  .max(160)
  .regex(/^[A-Za-z0-9_-]+$/);
const rawEmail = z.string().max(MAX_EMAIL_LENGTH + 64);

export const MAX_VOUCHERS_PER_ISSUE = 20;
export const MAX_VOUCHER_DAYS = 3650;

const orderLineVoucher = z
  .object({
    voucherId,
    orderId: z
      .string()
      .min(1)
      .max(128)
      .regex(/^[A-Za-z0-9_-]+$/),
    sku: z.string().trim().min(1).max(64),
    days: z.number().int().min(1).max(MAX_VOUCHER_DAYS),
    email: rawEmail,
    claimTokenHash: z.string().regex(/^[0-9a-f]{64}$/),
    isTest: z.boolean(),
    attribution: z
      .object({
        code: z.string().trim().min(1).max(40),
        partnerId: z.string().trim().min(1).max(128),
      })
      .nullable(),
  })
  .refine((voucher) =>
    /^[1-9][0-9]{0,2}$/.test(voucher.voucherId.slice(voucher.orderId.length + 1)),
  )
  .refine((voucher) => voucher.voucherId.startsWith(`${voucher.orderId}_`));

export const issueVouchersInput = z.object({
  vouchers: z
    .array(orderLineVoucher)
    .min(1)
    .max(MAX_VOUCHERS_PER_ISSUE)
    .refine(
      (vouchers) => new Set(vouchers.map((voucher) => voucher.voucherId)).size === vouchers.length,
    ),
});
export type IssueVouchersInput = z.infer<typeof issueVouchersInput>;

export const voidVoucherInput = z.object({ voucherId, reason: z.enum(VOID_REASONS) });
export type VoidVoucherInput = z.infer<typeof voidVoucherInput>;

export const giftLookupInput = z.object({ token: z.string().max(64) });
export const giftReassignInput = z.object({ token: z.string().max(64), email: rawEmail });
export const redeemCodeInput = z.object({ code: z.string().max(64), email: rawEmail });

const provableEmail = z.string().trim().toLowerCase().max(MAX_EMAIL_LENGTH).pipe(z.email());

export const premiumVouchersForMeInput = z.object({}).nullish();
export const claimPremiumVoucherInput = z.object({ voucherId, householdId: id });
export type ClaimPremiumVoucherInput = z.infer<typeof claimPremiumVoucherInput>;
export const sendVoucherEmailCodeInput = z.object({ email: provableEmail });
export const verifyVoucherEmailCodeInput = z.object({
  email: provableEmail,
  code: z.string().regex(/^[0-9]{6}$/),
});
