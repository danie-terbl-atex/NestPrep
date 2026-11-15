import type { Firestore } from 'firebase-admin/firestore';

import type { ConversionTrigger } from '../product_analytics/conversion_ledger';
import { tierFrom } from '../ai/usage_rules';
import { premiumRequired } from './errors';
import { entitlementRef } from './subscription_documents';

export async function requirePremium(
  store: Firestore,
  householdId: string,
  feature: ConversionTrigger,
  now: Date = new Date(),
): Promise<void> {
  const entitlement = await entitlementRef(store, householdId).get();
  if (tierFrom(entitlement.data(), now) !== 'premium') throw premiumRequired(feature);
}
