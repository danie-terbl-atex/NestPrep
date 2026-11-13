import type { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { tierFrom } from '../ai/usage_rules';
import { memberLevelIn } from '../household/access';
import { ROLES, householdRef } from '../household/documents';
import { refuse } from '../household/errors';
import { claimedMemberIdOf } from '../household/membership';
import { isOffShift } from '../household/shift_window';
import { readFlag } from '../shared/feature_flags';
import { premiumRequired } from '../subscriptions/errors';
import { entitlementRef } from '../subscriptions/subscription_documents';
import { refuseOwnRecipe } from './errors';

export interface OwnRecipeCaller {
  readonly uid: string;
  readonly timeZone: string;
  readonly memberId: string | null;
}

const householdShape = z.object({
  timeZone: z.string(),
  members: z.record(z.string(), z.enum([...ROLES, 'member'])),
  access: z.record(z.string(), z.unknown()).optional(),
  profiles: z.record(z.string(), z.string()).optional(),
});

export async function ownRecipeCallerIn(
  store: Firestore,
  householdId: string,
  uid: string,
): Promise<OwnRecipeCaller> {
  const snapshot = await householdRef(store, householdId).get();
  const household = householdShape.safeParse(snapshot.data());
  if (!snapshot.exists || !household.success) throw refuse('notAMember');
  const role = household.data.members[uid];
  if (role === undefined) throw refuse('notAMember');
  const grant = household.data.access?.[uid];
  if (memberLevelIn(role, grant, 'meals') !== 'edit') throw refuseOwnRecipe('mealsNotShared');
  if (await isOffShift(store, householdId, snapshot.data(), uid, new Date())) {
    throw refuseOwnRecipe('mealsNotShared');
  }
  return {
    uid,
    timeZone: household.data.timeZone,
    memberId: await claimedMemberIdOf(store, householdId, household.data.profiles, uid),
  };
}

export async function ownRecipeEditorIn(
  store: Firestore,
  householdId: string,
  uid: string,
): Promise<OwnRecipeCaller & { readonly memberId: string }> {
  if (!(await readFlag(store, 'householdRecipes'))) throw refuseOwnRecipe('householdRecipesOff');
  const caller = await ownRecipeCallerIn(store, householdId, uid);
  const { memberId } = caller;
  if (memberId === null) throw refuse('notAMember');
  const entitlement = await entitlementRef(store, householdId).get();
  if (tierFrom(entitlement.data(), new Date()) !== 'premium') throw premiumRequired('ownRecipes');
  return { ...caller, memberId };
}
