import { onCall } from 'firebase-functions/v2/https';

import { requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { type DeletionPlan, readDeletionPlan } from './deletion_plan';

/**
 * What deleting the caller's account would do, household by household, so
 * the person reads it before agreeing (accounts ADR-0006). It changes nothing
 * and takes no body: the subject is the caller.
 */
export const previewAccountDeletion = onCall(async (request) => {
  const uid = requireUid(request.auth);
  return previewBody(await readDeletionPlan(db(), uid, new Date()));
});

/** The wire shape (`BE-02`): the plan without its ids of other people. */
export function previewBody(plan: DeletionPlan): Record<string, unknown> {
  return {
    renewingSubscriptions: plan.renewingSubscriptions,
    households: plan.households.map((household) => ({
      householdId: household.householdId,
      name: household.name,
      outcome: household.outcome.kind,
      successorName: household.successorName,
      othersLosingAccess: household.othersLosingAccess,
      hasPremium: household.hasPremium,
    })),
  };
}
