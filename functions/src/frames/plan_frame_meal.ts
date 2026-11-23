import { FieldValue } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';

import { parseInput } from '../household/parse_input';
import { db } from '../shared/firestore';
import { mondayOf } from './frame_day';
import { readLinkedFrame } from './frame_access';
import { refuseFrame } from './frame_errors';
import { readFramePremium } from './frame_lunch_photos';
import {
  FRAME_DEVICE_OPTIONS,
  FRAME_PLAN_MEAL_PER_CREDENTIAL,
  FRAME_REQUEST_LIFETIME_MS,
} from './frame_policy';
import {
  FRAME_REQUESTS,
  MEALS,
  MEAL_PLANS,
  frameRecipeLink,
  frameRecipeMeal,
  frameRecipeOf,
  frameRequestDocument,
  frameRequestId,
  inPlanReach,
  mealIdOf,
  planSlotKey,
  recipeRef,
  recipesShown,
} from './frame_recipes';
import { readMealPlanners } from './frame_reads';
import { planFrameMealInput } from './frame_schemas';
import { creditFor } from './frame_ticks';

export type PlanFrameMealResult = { status: 'unlinked' } | { status: 'linked' };

const UNLINKED: PlanFrameMealResult = { status: 'unlinked' };

export const planFrameMeal = onCall(
  FRAME_DEVICE_OPTIONS,
  async (request): Promise<PlanFrameMealResult> => {
    const input = parseInput(planFrameMealInput, request.data);
    const store = db();
    const linked = await readLinkedFrame(store, input.secret, FRAME_PLAN_MEAL_PER_CREDENTIAL);
    if (linked === null) return UNLINKED;
    const { frameId, home } = linked;
    if (!recipesShown(linked.frame.panels, await readFramePremium(store, home))) {
      throw refuseFrame('recipesOff');
    }
    if (!inPlanReach(input.date, linked.clock.date)) throw refuseFrame('itemOutOfReach');

    const { names, planners, familySize } = await readMealPlanners(home, linked.householdData);
    const addedBy = creditFor(planners, names, input.by);
    if (addedBy === null) throw refuseFrame('whoNeeded');

    const link = input.id === null ? null : frameRecipeLink(input.id, input.household);
    if (input.id !== null && link === null) throw refuseFrame('recipeNotFound');
    const marker = home.collection(FRAME_REQUESTS).doc(frameRequestId(frameId, input.requestId));
    const plan = home.collection(MEAL_PLANS).doc(mondayOf(input.date));
    const slot = planSlotKey(input.date, input.slot);
    await store.runTransaction(async (transaction) => {
      if ((await transaction.get(marker)).exists) return;
      const meal = link === null ? null : home.collection(MEALS).doc(mealIdOf(link));
      if (link !== null && meal !== null) {
        const stored = await transaction.get(recipeRef(store, home, link));
        const recipe = frameRecipeOf(link, stored.data());
        if (recipe === null) throw refuseFrame('recipeNotFound');
        const fields = frameRecipeMeal(link, recipe, addedBy, familySize);
        if ((await transaction.get(meal)).exists) {
          transaction.update(meal, { ingredients: fields.ingredients });
        } else {
          transaction.create(meal, { ...fields, createdAt: FieldValue.serverTimestamp() });
        }
      }
      transaction.set(plan, { slots: { [slot]: meal?.id ?? '' } }, { merge: true });
      transaction.create(
        marker,
        frameRequestDocument(frameId, new Date(Date.now() + FRAME_REQUEST_LIFETIME_MS)),
      );
    });
    return { status: 'linked' };
  },
);
