import type { Firestore } from 'firebase-admin/firestore';

import { tierFrom } from '../ai/usage_rules';
import { addDays, todayIn } from '../school_letter/plain_date';
import { readFlag } from '../shared/feature_flags';
import { premiumRequired } from '../subscriptions/errors';
import { entitlementRef } from '../subscriptions/subscription_documents';
import { refusePlanWeek } from './errors';
import { mondayOfWeek } from './iso_week';
import { planCallerIn, type PlanCaller } from './plan_caller';
import { readWeekFacts, type ChildFacts, type WeekFacts } from './week_reads';

export interface OpenPlanning {
  readonly caller: PlanCaller;
  readonly monday: string;
  readonly facts: WeekFacts;
  /** The asked-for members who are children, in the order the household lists them. */
  readonly children: readonly ChildFacts[];
}

/**
 * The door both of *Plan my week*'s steps go through (lunch-box ADR-0012):
 * the switch, the caller's `lunch` grant re-derived from Firestore (BE-05), a
 * week that has not ended, premium checked here and not only on the phone,
 * then the household's facts — before anything is spent on the model.
 */
export async function openPlanning(
  store: Firestore,
  input: {
    readonly householdId: string;
    readonly week: string;
    readonly childIds: readonly string[];
  },
  uid: string,
): Promise<OpenPlanning> {
  if (!(await readFlag(store, 'planMyWeek'))) throw refusePlanWeek('planWeekOff');
  const caller = await planCallerIn(store, input.householdId, uid);

  const monday = mondayOfWeek(input.week);
  const { today } = todayIn(caller.timeZone, new Date());
  if (monday === null || addDays(monday, 6) < today) throw refusePlanWeek('weekNotPlannable');

  const entitlement = await entitlementRef(store, input.householdId).get();
  if (tierFrom(entitlement.data(), new Date()) !== 'premium') {
    throw premiumRequired('aiPlanning');
  }

  const facts = await readWeekFacts(store, input.householdId, monday);
  const asked = new Set(input.childIds);
  const children = facts.children.filter((child) => asked.has(child.memberId));
  if (children.length === 0) throw refusePlanWeek('nothingToPlan');
  return { caller, monday, facts, children };
}
