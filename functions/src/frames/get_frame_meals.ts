import { onCall } from 'firebase-functions/v2/https';

import { parseInput } from '../household/parse_input';
import { db } from '../shared/firestore';
import { readLinkedFrame } from './frame_access';
import { type FrameMeals, assembleFrameMeals, mealWeekOf } from './frame_meal_week';
import { readFramePremium } from './frame_lunch_photos';
import { readMealWeek } from './frame_reads';
import { FRAME_DEVICE_OPTIONS, FRAME_MEALS_PER_CREDENTIAL } from './frame_policy';
import { getFrameMealsInput } from './frame_schemas';

export type GetFrameMealsResult = { status: 'unlinked' } | FrameMeals;

const UNLINKED: GetFrameMealsResult = { status: 'unlinked' };

/** This week's or next week's meal plan for the frame's Meals overview (NestPrep-Home ADR-0029). */
export const getFrameMeals = onCall(
  FRAME_DEVICE_OPTIONS,
  async (request): Promise<GetFrameMealsResult> => {
    const { secret, week } = parseInput(getFrameMealsInput, request.data);
    const store = db();
    const linked = await readLinkedFrame(store, secret, FRAME_MEALS_PER_CREDENTIAL);
    if (linked === null) return UNLINKED;
    const today = linked.clock.date;
    const monday = mealWeekOf(today, week);
    const meals = linked.frame.panels.meals
      ? await readMealWeek(store, linked.home, monday, readFramePremium(store, linked.home))
      : undefined;
    return assembleFrameMeals({ today, week: monday, ...(meals === undefined ? {} : { meals }) });
  },
);
