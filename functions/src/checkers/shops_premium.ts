import type { Firestore } from 'firebase-admin/firestore';

import { tierFrom } from '../ai/usage_rules';
import { userRef } from '../household/documents';
import { premiumRequired } from '../subscriptions/errors';
import { requirePremium } from '../subscriptions/premium_gate';
import { entitlementRef } from '../subscriptions/subscription_documents';

const HOUSEHOLDS_READ = 20;

/** Refuses `premiumRequired` (`shops`) unless the household has Premium (subscriptions ADR-0008). */
export async function requireShopsPremium(store: Firestore, householdId: string): Promise<void> {
  await requirePremium(store, householdId, 'shops');
}

/**
 * A shop link is the member's own and names no household, so linking asks
 * whether any household they are in has Premium. `users/{uid}.householdIds`
 * is written only by the server.
 */
export async function requireShopsPremiumForMember(
  store: Firestore,
  uid: string,
  now: Date = new Date(),
): Promise<void> {
  const listed: unknown = (await userRef(store, uid).get()).get('householdIds');
  const householdIds = Array.isArray(listed)
    ? listed.filter((id): id is string => typeof id === 'string' && id !== '')
    : [];
  if (householdIds.length > 0) {
    const entitlements = await store.getAll(
      ...householdIds.slice(0, HOUSEHOLDS_READ).map((id) => entitlementRef(store, id)),
    );
    if (entitlements.some((entitlement) => tierFrom(entitlement.data(), now) === 'premium')) return;
  }
  throw premiumRequired('shops');
}
