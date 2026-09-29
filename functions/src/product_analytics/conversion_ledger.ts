import { hash } from 'node:crypto';

import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { householdRef } from '../household/documents';
import { conversionRef, expiryFor, stringField } from './analytics_documents';
import { countingZoneFor, weekKeyOf } from './iso_week';

/**
 * Free-to-premium conversion by the feature that prompted it — V2 on the plan
 * map, so nothing calls this in V1 because nothing is sold in V1. The shape is
 * fixed now so that subscriptions has one call to make and the weekly totals
 * already have a column for it (product-analytics ADR-0001).
 *
 * **The contract for subscriptions:** once a store receipt is verified on the
 * server, call `recordPremiumConversion` with the household, the store's own
 * transaction id as the idempotency key, and the trigger the paywall was opened
 * from. Never from the client — a conversion a client can write is a number
 * anybody can move (`BE-20`).
 */

/**
 * What opened the paywall. A closed set: free text here would become a
 * sentence somebody typed about a child. `direct` is the paywall opened from
 * settings rather than by bumping into a limit.
 */
export const CONVERSION_TRIGGERS = [
  'additionalChild',
  'lunchLearning',
  'prepList',
  'aiPlanning',
  'budgetMode',
  'direct',
] as const;
export type ConversionTrigger = (typeof CONVERSION_TRIGGERS)[number];

export const premiumConversionInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  /**
   * The store transaction id, or anything else unique per purchase. Only its
   * hash is stored, as the document id that makes a retry a no-op.
   */
  conversionId: z
    .string()
    .trim()
    .min(1)
    .max(128)
    .regex(/^[A-Za-z0-9._:-]+$/),
  trigger: z.enum(CONVERSION_TRIGGERS),
  convertedAt: z.date(),
});
export type PremiumConversion = z.infer<typeof premiumConversionInput>;

/**
 * Records one conversion, once. Returns false when this purchase was already
 * recorded or its household no longer exists, true when it was new.
 */
export async function recordPremiumConversion(
  store: Firestore,
  input: PremiumConversion,
): Promise<boolean> {
  const conversion = premiumConversionInput.parse(input);
  return store.runTransaction(async (transaction) => {
    const household = await transaction.get(householdRef(store, conversion.householdId));
    if (!household.exists) return false;
    const ref = conversionRef(store, hashedId(conversion.conversionId));
    if ((await transaction.get(ref)).exists) return false;

    const zone = countingZoneFor(stringField(household.get('timeZone')));
    transaction.create(ref, {
      householdId: conversion.householdId,
      week: weekKeyOf(conversion.convertedAt, zone),
      trigger: conversion.trigger,
      convertedAt: Timestamp.fromDate(conversion.convertedAt),
      expireAt: expiryFor(conversion.convertedAt),
    });
    return true;
  });
}

function hashedId(conversionId: string): string {
  return hash('sha256', conversionId, 'hex');
}

/** A conversion as read back by the rollup. */
export const storedConversion = z.object({
  week: z.string(),
  trigger: z.enum(CONVERSION_TRIGGERS),
});
