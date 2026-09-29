import { hash } from 'node:crypto';

import { type DocumentReference, type Firestore, Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';

import { householdRef } from '../household/documents';

/**
 * Where referrals keep what they know (subscriptions ADR-0002):
 *
 * - `referralCodes/{code}` — which household a code is; server-only, so a code
 *   cannot be looked up or listed from a phone.
 * - `referrals/{referredHouseholdId}` — the ledger: one per household that
 *   ever redeemed, which is what makes "once per household" hold. Server-only.
 * - `households/{h}/referral/current` — this household's own code, and until
 *   when it may still enter somebody else's. Family reads it.
 * - `households/{h}/referralHistory/{entryId}` — one line per referral this
 *   household took part in, on either side, holding nothing about the other
 *   household. Family reads it.
 */
export const REFERRAL_CODES = 'referralCodes';
export const REFERRALS = 'referrals';
export const REFERRAL = 'referral';
export const CURRENT = 'current';
export const REFERRAL_HISTORY = 'referralHistory';

export const REFERRAL_STATUSES = ['pending', 'qualified', 'expired'] as const;
export type ReferralStatus = (typeof REFERRAL_STATUSES)[number];

/** How a referral qualified: two adults used the new household, or it bought premium. */
export const QUALIFIED_BY = ['twoAdults', 'premiumPurchase'] as const;
export type QualifiedBy = (typeof QUALIFIED_BY)[number];

/** What one side got: its month, or nothing because it had reached the yearly cap. */
export const REFERRAL_REWARDS = ['month', 'capped'] as const;
export type ReferralReward = (typeof REFERRAL_REWARDS)[number];

/** Which side of a referral a history line is: the household that shared, or the one that joined. */
export const REFERRAL_SIDES = ['referrer', 'referred'] as const;
export type ReferralSide = (typeof REFERRAL_SIDES)[number];

export function referralCodeRef(store: Firestore, code: string): DocumentReference {
  return store.collection(REFERRAL_CODES).doc(code);
}

export function referralRef(store: Firestore, referredHouseholdId: string): DocumentReference {
  return store.collection(REFERRALS).doc(referredHouseholdId);
}

export function householdReferralRef(store: Firestore, householdId: string): DocumentReference {
  return householdRef(store, householdId).collection(REFERRAL).doc(CURRENT);
}

/**
 * A history line's id: derived, so a retry writes the same line, and hashed,
 * so the household that shared its code never learns the other one's id.
 */
export function historyEntryId(referredHouseholdId: string, side: ReferralSide): string {
  return hash('sha256', `referral:${side}:${referredHouseholdId}`, 'hex').slice(0, 24);
}

export function historyRef(
  store: Firestore,
  householdId: string,
  entryId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(REFERRAL_HISTORY).doc(entryId);
}

/** The premium grant a referral gives one side, by the same derived id. */
export function referralGrantId(entryId: string): string {
  return `referral-${entryId}`;
}

const timestamp = z.instanceof(Timestamp).transform((value) => value.toDate());

/** A `referrals` ledger document as read back — parsed, never cast (`ENG-09`). */
export const storedReferral = z.object({
  referrerHouseholdId: z.string().min(1),
  referredHouseholdId: z.string().min(1),
  redeemedAt: timestamp,
  qualifyBy: timestamp,
  status: z.enum(REFERRAL_STATUSES),
  activeUids: z.array(z.string()).default([]),
  qualifiedAt: timestamp.nullable().default(null),
  qualifiedBy: z.enum(QUALIFIED_BY).nullable().default(null),
  referrerReward: z.enum(REFERRAL_REWARDS).nullable().default(null),
  referredReward: z.enum(REFERRAL_REWARDS).nullable().default(null),
});
export type StoredReferral = z.infer<typeof storedReferral>;

/** A household's `members` map, as far as referrals need it: uid → role. */
export const householdMembers = z.object({
  members: z.record(z.string(), z.string()).default({}),
  createdAt: timestamp.optional(),
  timeZone: z.string().optional(),
});
export type HouseholdMembers = z.infer<typeof householdMembers>;
