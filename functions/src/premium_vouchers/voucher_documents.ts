import { type DocumentReference, type Firestore, Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';

import { householdRef, userRef } from '../household/documents';

export const PREMIUM_VOUCHERS = 'premiumVouchers';
export const PREMIUM_CODES = 'premiumCodes';
export const CODE_CLAIMS = 'claims';
export const CODE_REDEMPTIONS = 'redemptions';
export const PREMIUM_EMAIL_CHALLENGES = 'premiumEmailChallenges';
export const PRIVATE = 'private';
export const VERIFIED_EMAILS = 'verifiedEmails';
export const ACQUISITION = 'acquisition';

export const VOUCHER_KINDS = ['frame', 'code'] as const;
export const VOUCHER_STATUSES = ['waiting', 'claimed', 'void'] as const;
export const CODE_SHAPES = ['shared', 'unique'] as const;
export const CODE_STATUSES = ['active', 'paused', 'archived'] as const;
export const CODE_ELIGIBILITIES = ['any', 'newToPremium'] as const;
export const VOID_REASONS = ['refund', 'cancelled'] as const;

export type VoucherKind = (typeof VOUCHER_KINDS)[number];

const timestamp = z.instanceof(Timestamp).transform((value) => value.toDate());

export const voucherAttribution = z.object({ code: z.string(), partnerId: z.string() });
export type VoucherAttribution = z.infer<typeof voucherAttribution>;

export const storedVoucher = z.object({
  kind: z.enum(VOUCHER_KINDS),
  orderId: z.string().nullable().default(null),
  sku: z.string().nullable().default(null),
  codeId: z.string().nullable().default(null),
  days: z.number().int().positive(),
  emailHash: z.string().min(1),
  emailMasked: z.string(),
  claimTokenHash: z.string().nullable().default(null),
  status: z.enum(VOUCHER_STATUSES),
  isTest: z.boolean(),
  attribution: voucherAttribution.nullable().default(null),
  claimBy: timestamp.nullable().default(null),
  reassignCount: z.number().int().nonnegative().default(0),
});
export type StoredVoucher = z.infer<typeof storedVoucher>;

export const storedCode = z.object({
  shape: z.enum(CODE_SHAPES),
  display: z.string().nullable().default(null),
  label: z.string(),
  batchId: z.string().nullable().default(null),
  days: z.number().int().positive(),
  maxClaims: z.number().int().positive().nullable().default(null),
  claimCount: z.number().int().nonnegative().default(0),
  validFrom: timestamp,
  validUntil: timestamp.nullable().default(null),
  status: z.enum(CODE_STATUSES),
  eligibility: z.enum(CODE_ELIGIBILITIES).default('newToPremium'),
  attribution: z.object({ partnerId: z.string() }).nullable().default(null),
  isTest: z.boolean().default(false),
});
export type StoredCode = z.infer<typeof storedCode>;

export const storedChallenge = z.object({
  emailHash: z.string(),
  codeHash: z.string(),
  expiresAt: timestamp,
  tries: z.number().int().nonnegative(),
  sentCount: z.number().int().nonnegative(),
  windowStart: timestamp,
});
export type StoredChallenge = z.infer<typeof storedChallenge>;

export const verifiedEmailsDocument = z.object({
  emails: z.record(z.string(), z.unknown()).default({}),
});

export function voucherRef(store: Firestore, voucherId: string): DocumentReference {
  return store.collection(PREMIUM_VOUCHERS).doc(voucherId);
}

export function codeRef(store: Firestore, codeHash: string): DocumentReference {
  return store.collection(PREMIUM_CODES).doc(codeHash);
}

export function codeClaimRef(
  store: Firestore,
  codeHash: string,
  householdId: string,
): DocumentReference {
  return codeRef(store, codeHash).collection(CODE_CLAIMS).doc(householdId);
}

export function codeRedemptionRef(
  store: Firestore,
  codeHash: string,
  emailHash: string,
): DocumentReference {
  return codeRef(store, codeHash).collection(CODE_REDEMPTIONS).doc(emailHash);
}

export function emailChallengeRef(store: Firestore, uid: string): DocumentReference {
  return store.collection(PREMIUM_EMAIL_CHALLENGES).doc(uid);
}

export function verifiedEmailsRef(store: Firestore, uid: string): DocumentReference {
  return userRef(store, uid).collection(PRIVATE).doc(VERIFIED_EMAILS);
}

export function acquisitionRef(store: Firestore, householdId: string): DocumentReference {
  return householdRef(store, householdId).collection(PRIVATE).doc(ACQUISITION);
}

export function voucherGrantId(voucherId: string): string {
  return `voucher-${voucherId}`;
}
